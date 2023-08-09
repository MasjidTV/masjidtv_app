import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/zone_selector.dart';
import '../constants.dart';
import '../model/jakim_zones.dart';
import '../server/backend_server.dart';
import '../server/html_server.dart';
import '../util/html_content_setup.dart';
import '../util/link_launcher.dart';
import '../util/my_storage.dart';
import '../util/override_http_certificate.dart';

enum ServerStatus { started, starting, stopping, stopped }

enum ProcessStatus { started, completed }

class AppServer extends StatefulWidget {
  const AppServer({super.key});

  @override
  State<AppServer> createState() => _AppServerState();
}

class _AppServerState extends State<AppServer>
    with AutomaticKeepAliveClientMixin<AppServer> {
  final NetworkInfo _networkInfo = NetworkInfo();
  ServerStatus _serverStatus = ServerStatus.stopped;
  int? _htmlServerPort;
  ProcessStatus prepareServerStatus = ProcessStatus.completed;
  ProcessStatus setupZoneStatus = ProcessStatus.completed;

  String? savedZone;

  @override
  void initState() {
    super.initState();
    _loadSaveZone();

    // check and download for new zone data if available
    Future.delayed(const Duration(seconds: 3), () async {
      if (savedZone != null) {
        // check wether connected to network
        final connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.none) {
          Fluttertoast.showToast(
              msg:
                  "No internet connection. Skipping checking for new zone data");
          return;
        }
        // download zone data
        setState(() => setupZoneStatus = ProcessStatus.started);
        try {
          await _setupZone(savedZone!);
        } catch (e) {
          Fluttertoast.showToast(msg: "Error while setup zone: $e");
        }
        setState(() => setupZoneStatus = ProcessStatus.completed);
      }
    });

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // check if the html content is already setup
      if (await FlutterBackground.hasPermissions) {
        if (_serverStatus != ServerStatus.started &&
            await HtmlContentSetup.isAlreadySetup()) {
          debugPrint('Starting server from post frame callback');
          _startAllServer();
        } else {
          debugPrint('Server not started from post frame callback');
        }
      } else {
        debugPrint('No permission to start server from post frame callback');
      }
    });
  }

  /// https://pub.dev/packages/flutter_background
  Future<void> _initializeFlutterBackground() async {
    // Don't set batteryOptimization to false, it will cause
    // FlutterBackground.hasPermissions return false, and hence
    // the server is not started during bootup
    var androidConfig = const FlutterBackgroundAndroidConfig(
      notificationTitle: "Masjid TV server is running",
      notificationText: "App is running in the background",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(
          name: 'background_icon',
          defType: 'drawable'), // Default is ic_launcher from folder mipmap
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);

    debugPrint(
        'permission background : ${await FlutterBackground.hasPermissions}');

    if (!success) debugPrint("Failed to initialize FlutterBackground");
  }

  void _loadSaveZone() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedZone = prefs.getString(kSpJakimZone);
    });
  }

  Future<void> _stopServer() async {
    setState(() {
      _serverStatus = ServerStatus.stopping;
      debugPrint('Stopping server');
    });
    await Future.wait([HtmlServer.stop(), BackendServer.stop()]);
    setState(() => _serverStatus = ServerStatus.stopped);
    Fluttertoast.showToast(msg: 'Servers stopped');
    FlutterBackground.disableBackgroundExecution();
  }

  /// Copy the html project folder from flutter assets to device directory
  /// The shelf cannot open access from flutter assets
  Future<List<String>> _copyAssetsToDocuments() async {
    // Get the app documents directory.
    final directory = MyStorage.getMasjidTvDirectory();

    // Get a handle to the asset bundle.
    final bundle = rootBundle;

    // Get a list of all assets in the 'assets' folder.
    final assets = await bundle.loadString('AssetManifest.json');
    var assetList = jsonDecode(assets) as Map<String, dynamic>;

    // removed unwanted assets
    assetList.removeWhere((key, value) =>
        key.startsWith('assets/app_reserved') || key.startsWith('packages'));

    // print all asset that will be copied
    for (final assetPath in assetList.keys) {
      debugPrint(assetPath);
    }

    List<String> copiedAssets = [];

    // Copy each asset to the app documents directory.
    for (final assetPath in assetList.keys) {
      final assetData = await bundle.load(assetPath);
      // remove the 'assets/' part from the path
      final correctedAssetPath = assetPath.replaceFirst('assets/', 'web/');
      final file = File('${directory.path}/$correctedAssetPath');
      await file.create(recursive: true);
      await file.writeAsBytes(assetData.buffer.asUint8List());

      // record
      copiedAssets.add(correctedAssetPath);
    }

    return copiedAssets;
  }

  DateTime _addOneMonth(DateTime date, {int monthCount = 1}) {
    int year = date.year;
    int month = date.month + monthCount;

    if (month > 12) {
      year += (month - 1) ~/ 12; // Add the number of years
      month = (month - 1) % 12 + 1; // Adjust the month within 1-12 range
    }

    return DateTime(year, month, date.day);
  }

  Future<void> _setupZone(String jakimZone) async {
    final now = DateTime.now();

    for (var i = 0; i < 12; i++) {
      var targetMonthYear = _addOneMonth(now, monthCount: i);

      var fileName =
          '${jakimZone.toUpperCase()}-${targetMonthYear.month}-${targetMonthYear.year}.json';

      // check if the file already exist
      final dir = MyStorage.getMasjidTvDirectory();
      final dbFile = join(dir.path, 'db', fileName);
      final file = File(dbFile);
      if (await file.exists()) {
        debugPrint('File $fileName already exist, skipping');
        continue;
      }

      var uri = Uri.https('mpt-server.vercel.app', '/api/v2/solat/$jakimZone', {
        'year': '${targetMonthYear.year}',
        'month': '${targetMonthYear.month}'
      });
      debugPrint('Started fetching $uri');
      debugPrint('for month ${targetMonthYear.month}-${targetMonthYear.year}');

      // For reasons, the call to the API failed with CERTIFICATE_VERIFY_FAILED
      // when running on emulator with API 22. So, I have to override the
      // certificate verification.
      var response = await HttpOverrides.runWithHttpOverrides(() {
        return http.get(uri);
      }, OverrideHttpCertificate());
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        // Save JSON data to a file
        final dir = MyStorage.getMasjidTvDirectory();
        final saveAs = join(dir.path, 'db',
            '${jakimZone.toUpperCase()}-${targetMonthYear.month}-${targetMonthYear.year}.json');

        debugPrint('Saving to $saveAs');
        var file = File(saveAs);
        await file.create(recursive: true);
        await file.writeAsString(json.encode(jsonResponse));

        debugPrint('JSON response saved to file ${file.path}.');

        setState(() {});
      } else {
        if (response.statusCode == 404) {
          debugPrint('Data not available yet maybe');
          continue;
        }
        throw HttpException('Error ${response.statusCode}');
      }
    }
  }

  /// Check if the prayer time database already saved and available
  Future<List<String>?> _verifyZonesAvailable(String jakimCode) async {
    var filesPath = await _listFilesInDbDirectory();

    // return list of filebasename that starts with jakimCode
    return filesPath.where((element) => element.startsWith(jakimCode)).toList();
  }

  /// List the filename in the prayer time database directory
  Future<List<String>> _listFilesInDbDirectory() async {
    final dir = MyStorage.getMasjidTvDirectory();
    final savedZonePath = join(dir.path, 'db');

    // list all files in savedZonePath directory
    var files = Directory(savedZonePath).listSync().toList();

    return files.map((e) => basename(e.path)).toList();
  }

  /// Write the zone to the HTML server config file
  Future<void> _writeZoneToConfigFile(String jakimZone) async {
    // open a file
    var dir = MyStorage.getMasjidTvDirectory();
    var file = File('${dir.path}/config.json');

    // read & parse the file
    var content = await file.readAsString();
    var jsonContent = jsonDecode(content);

    // change the zone
    jsonContent['zone'] = jakimZone;

    // convert back to string
    var newContent = jsonEncode(jsonContent);

    // write the file
    await file.writeAsString(newContent);
  }

  void _startAllServer() async {
    setState(() => _serverStatus = ServerStatus.starting);

    if (!await HtmlContentSetup.isAlreadySetup()) {
      Fluttertoast.showToast(msg: "Please 'Prepare server' before continue");
      setState(() => _serverStatus = ServerStatus.stopped);
      return;
    }

    try {
      _htmlServerPort = await HtmlServer.start();
      await BackendServer.start();
      await _initializeFlutterBackground();
      await FlutterBackground.enableBackgroundExecution();
      setState(() => _serverStatus = ServerStatus.started);
    } catch (e) {
      setState(() => _serverStatus = ServerStatus.stopped);
      Fluttertoast.showToast(msg: e.toString());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: [
        ListTile(
          onTap: _serverStatus == ServerStatus.stopped ? _startAllServer : null,
          onLongPress:
              _serverStatus == ServerStatus.started ? _stopServer : null,
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.dns, color: Colors.white),
          ),
          title: Text(switch (_serverStatus) {
            ServerStatus.stopped => 'MasjidTV Server is stopped',
            ServerStatus.stopping => 'Disposing server',
            ServerStatus.started => 'Server is running',
            ServerStatus.starting => 'Starting server',
          }),
          subtitle: Text(
            switch (_serverStatus) {
              ServerStatus.stopped => 'Tap to start server',
              ServerStatus.stopping => 'Please wait...',
              ServerStatus.started => 'Long press to stop server',
              ServerStatus.starting => 'Please wait...',
            },
          ),
          trailing: switch (_serverStatus) {
            ServerStatus.started => const Icon(Icons.stop, color: Colors.red),
            ServerStatus.stopped =>
              const Icon(Icons.play_arrow, color: Colors.green),
            _ => const SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
          },
        ),

        if (_serverStatus == ServerStatus.started)
          ListTile(
            onTap: () {
              LinkLauncher.launch('http://127.0.0.1:${HtmlServer.port}');
            },
            onLongPress: () async {
              // copy local address to clipboard
              await Clipboard.setData(
                  ClipboardData(text: 'http://127.0.0.1:${HtmlServer.port}'));
              Fluttertoast.showToast(msg: 'Copied local address to clipboard');
            },
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.router, color: Colors.white),
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NetworkText('Local: ', '127.0.0.1:${HtmlServer.port}'),
                FutureBuilder(
                  future: _networkInfo.getWifiIP(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _NetworkText('On your network: ',
                          '${snapshot.data}:$_htmlServerPort');
                    }
                    return const _NetworkText('On your network: ', 'N/A');
                  },
                ),
              ],
            ),
          ),
        const Divider(),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.download_for_offline, color: Colors.white),
          ),
          subtitle: FutureBuilder(
              future: HtmlContentSetup.isAlreadySetup(),
              builder: (context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.hasData && snapshot.data!) {
                  var saveLocation = MyStorage.getMasjidTvDirectory().path;
                  return Text("Saved in $saveLocation");
                }
                return const Text('Download HTML project folder to device');
              }),
          title: const Text('Prepare server'),
          onTap: () async {
            setState(() => prepareServerStatus = ProcessStatus.started);

            var isAlreadySetup = await HtmlContentSetup.isAlreadySetup();
            // show alert dialog if already setup
            if (isAlreadySetup) {
              // ignore: use_build_context_synchronously
              var res = await showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      content: const Text(
                          'Seems like the HTML project folder is already setup. Running the setup again will overwrite the existing files. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  });

              if (res == null || res == false) {
                setState(() => prepareServerStatus = ProcessStatus.completed);
                return;
              }
            }
            try {
              await HtmlContentSetup.setupHtmlContentFromGithub();
              Fluttertoast.showToast(
                  msg: 'Downloaded repo content successfully');
            } catch (e) {
              debugPrint(e.toString());
              Fluttertoast.showToast(msg: 'Error occurred: $e');
            }
            setState(() => prepareServerStatus = ProcessStatus.completed);
          },
          trailing: switch (prepareServerStatus) {
            ProcessStatus.completed => null,
            ProcessStatus.started => const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(),
              ),
          },
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.pin_drop, color: Colors.white),
          ),
          subtitle: Text('${savedZone ?? 'Not set'} (Tap to set)'),
          title: const Text('Prayer time zone'),
          onTap: () async {
            // read json from assets
            final json = await rootBundle.loadString('assets/jakim_zones.json');
            var jakimZonesList = JakimZones.fromList(jsonDecode(json));

            // show dialog
            JakimZones? selectedZone =
                // ignore: use_build_context_synchronously
                await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ZoneSelector(jakimZones: jakimZonesList),
              fullscreenDialog: true,
            ));

            if (selectedZone == null) return;
            // save to SP
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(kSpJakimZone, selectedZone.jakimCode);

            await _writeZoneToConfigFile(selectedZone.jakimCode);
            debugPrint('Zone saved to config.json');
            setState(() => savedZone = selectedZone.jakimCode);
            Fluttertoast.showToast(
                msg: "Zone saved. Downloading prayer time data...");

            // download zone data
            setState(() => setupZoneStatus = ProcessStatus.started);
            try {
              await _setupZone(savedZone!);
              Fluttertoast.showToast(msg: "Data downloaded");
            } catch (e) {
              Fluttertoast.showToast(msg: "Error while setup zone: $e");
            }
            setState(() => setupZoneStatus = ProcessStatus.completed);
          },
        ),
        ListTile(
          enabled: savedZone != null,
          leading: const CircleAvatar(
            backgroundColor: Colors.pink,
            child: Icon(Icons.data_array, color: Colors.white),
          ),
          subtitle: FutureBuilder(
              future: _verifyZonesAvailable(savedZone ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return const Text('No downloaded data yet. Tap to set up');
                  }
                  var monthYear = snapshot.data!
                      .map((e) =>
                          '${e.split('-')[1]}-${e.split('-')[2].split('.')[0]}')
                      .toList();
                  // Extracting the "month-year" portion from filename
                  return Text(
                    'Available: ${monthYear.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return const Text('N/A');
              }),
          title: const Text('Prayer time database'),
          trailing: switch (setupZoneStatus) {
            ProcessStatus.completed => null,
            ProcessStatus.started => const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(),
              ),
          },
          onTap: () async {
            if (savedZone == null) {
              Fluttertoast.showToast(msg: 'Please set zone first');
              return;
            }
            // download zone data
            setState(() => setupZoneStatus = ProcessStatus.started);
            try {
              await _setupZone(savedZone!);
              Fluttertoast.showToast(msg: "Data downloaded");
            } catch (e) {
              Fluttertoast.showToast(msg: "Error while setup zone: $e");
            }
            setState(() => setupZoneStatus = ProcessStatus.completed);
          },
        ),
        // ListTile(
        //   leading: const CircleAvatar(
        //     backgroundColor: Colors.blue,
        //     child: Icon(Icons.folder_copy, color: Colors.white),
        //   ),
        //   subtitle: const Text(
        //       'Copy the html project folder from flutter assets to device directory'),
        //   title: const Text('Prepare server'),
        //   onTap: () async {
        //     var copiedAssets = await _copyAssetsToDocuments();
        //     Fluttertoast.showToast(
        //         msg: 'Copied ${copiedAssets.length} items: $copiedAssets');
        //   },
        // ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _NetworkText extends StatelessWidget {
  const _NetworkText(this.text, this.infoText);

  final String text;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          TextSpan(
            text: infoText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
