import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/zone_selector.dart';
import '../constants.dart';
import '../model/jakim_zones.dart';
import '../server/backend_server.dart';
import '../server/html_server.dart';
import '../util/html_content_setup.dart';
import '../util/link_launcher.dart';

enum ServerStatus { started, starting, stopping, stopped }

class AppServer extends StatefulWidget {
  const AppServer({super.key});

  @override
  State<AppServer> createState() => _AppServerState();
}

class _AppServerState extends State<AppServer> {
  final NetworkInfo _networkInfo = NetworkInfo();
  ServerStatus _serverStatus = ServerStatus.stopped;
  ServerStatus _backendServerStatus = ServerStatus.stopped;
  int? htmlServerPort;
  int? backendServerPort;

  String? savedZone;

  @override
  void initState() {
    super.initState();
    _loadSaveZone();
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
    // await Future.delayed(const Duration(seconds: 1));
    await HtmlServer.stop();
    setState(() {
      _serverStatus = ServerStatus.stopped;
    });
    debugPrint('Stop server');
  }

  Future<void> _stopBackendServer() async {
    setState(() {
      _backendServerStatus = ServerStatus.stopping;
      debugPrint('Stopping backend server');
    });
    await BackendServer.stop();
    setState(() {
      _backendServerStatus = ServerStatus.stopped;
    });
    debugPrint('Stop backend server');
  }

  /// Copy the html project folder from flutter assets to device directory
  /// The shelf cannot open access from flutter assets
  Future<List<String>> _copyAssetsToDocuments() async {
    // Get the app documents directory.
    final directory = await getExternalStorageDirectory();

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
      final file = File('${directory!.path}/$correctedAssetPath');
      await file.create(recursive: true);
      await file.writeAsBytes(assetData.buffer.asUint8List());

      // record
      copiedAssets.add(correctedAssetPath);
    }

    return copiedAssets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: _serverStatus == ServerStatus.stopped
              ? () async {
                  setState(() => _serverStatus = ServerStatus.starting);

                  try {
                    htmlServerPort = await HtmlServer.start();
                    setState(() => _serverStatus = ServerStatus.started);
                  } catch (e) {
                    setState(() => _serverStatus = ServerStatus.stopped);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          )
                        ],
                      ),
                    );
                    return;
                  }
                }
              : null,
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
        ListTile(
          onTap: _backendServerStatus == ServerStatus.stopped
              ? () async {
                  setState(() => _backendServerStatus = ServerStatus.starting);

                  try {
                    backendServerPort = await BackendServer.start();
                    setState(() => _backendServerStatus = ServerStatus.started);
                  } catch (e) {
                    setState(() => _backendServerStatus = ServerStatus.stopped);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          )
                        ],
                      ),
                    );
                    return;
                  }
                }
              : null,
          onLongPress: _backendServerStatus == ServerStatus.started
              ? _stopBackendServer
              : null,
          leading: const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.developer_board, color: Colors.white),
          ),
          title: Text(switch (_backendServerStatus) {
            ServerStatus.stopped => 'MasjidTV Backend is stopped',
            ServerStatus.stopping => 'Disposing server',
            ServerStatus.started => 'Backend Server is running',
            ServerStatus.starting => 'Starting server',
          }),
          subtitle: Text(
            switch (_backendServerStatus) {
              ServerStatus.stopped => 'Tap to start server',
              ServerStatus.stopping => 'Please wait...',
              ServerStatus.started =>
                'Server listening on port $backendServerPort (Long press to stop server)',
              ServerStatus.starting => 'Please wait...',
            },
          ),
          trailing: switch (_backendServerStatus) {
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
              LinkLauncher.launch(HtmlServer.url);
            },
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.router, color: Colors.white),
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NetworkText('Local: ', HtmlServer.url),
                FutureBuilder(
                  future: _networkInfo.getWifiIP(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _NetworkText('On your network: ',
                          '${snapshot.data}:$htmlServerPort');
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
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.pin_drop, color: Colors.white),
          ),
          subtitle: Text('${savedZone ?? 'Not set'} (Tap to set)'),
          title: const Text('Prayer time zone'),
          onTap: () async {
            // read json from assets
            final json = await rootBundle
                .loadString('assets/app_reserved/jakim_zones.json');
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
            setState(() => savedZone = selectedZone.jakimCode);
          },
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.folder_copy, color: Colors.white),
          ),
          subtitle: const Text(
              'Copy the html project folder from flutter assets to device directory'),
          title: const Text('Prepare server'),
          onTap: () async {
            var copiedAssets = await _copyAssetsToDocuments();
            Fluttertoast.showToast(
                msg: 'Copied ${copiedAssets.length} items: $copiedAssets');
          },
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.download_for_offline, color: Colors.white),
          ),
          subtitle: const Text(
              'Copy the html project folder from flutter assets to device directory'),
          title: const Text('Prepare server'),
          onTap: () async {
            await HtmlContentSetup.setupHtmlContentFromGithub();
            Fluttertoast.showToast(msg: 'Downloaded repo content successfully');
          },
        ),
      ],
    );
  }
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
