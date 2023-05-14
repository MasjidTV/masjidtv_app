import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as io;

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
  HttpServer? server;

  Future<void> _startShelfLocalhostServer() async {
    // Serve the device directory.
    final directory = await getExternalStorageDirectory();
    var handler =
        createStaticHandler(directory!.path, defaultDocument: 'index.html');

    // Create a Shelf cascade with the static file handler first, and the fallback handler second.
    var cascade = Cascade().add(handler).add(_echoRequest);

    // choose random port between 5000 and 8080
    int port = 5000 + Random().nextInt(3080);

    // Start the server on port
    server = await io.serve(cascade.handler, InternetAddress.anyIPv4, port);
  }

  Response _echoRequest(Request request) {
    // Create a plain text response with the request body.
    return Response.ok('Request for "${request.url}" received.');
  }

  Future<void> _stopServer() async {
    setState(() {
      _serverStatus = ServerStatus.stopping;
      debugPrint('Stopping server');
    });
    // await Future.delayed(const Duration(seconds: 1));
    server!.close();
    setState(() {
      _serverStatus = ServerStatus.stopped;
    });
    debugPrint('Stop server');
  }

  /// Copy the html project folder from flutter assets to device directory
  /// The shelf cannot open access from flutter assets
  Future<void> _copyAssetsToDocuments() async {
    // Get the app documents directory.
    final directory = await getExternalStorageDirectory();

    // Get a handle to the asset bundle.
    final bundle = rootBundle;

    // Get a list of all assets in the 'assets' folder.
    final assets = await bundle.loadString('AssetManifest.json');
    var assetList = jsonDecode(assets) as Map<String, dynamic>;

    // print all asset that will be copied
    for (final assetPath in assetList.keys) {
      debugPrint(assetPath);
    }

    // Copy each asset to the app documents directory.
    for (final assetPath in assetList.keys) {
      final assetData = await bundle.load(assetPath);
      // remove the 'assets/' part from the path
      final correctedAssetPath = assetPath.replaceFirst('assets/', '');
      final file = File('${directory!.path}/$correctedAssetPath');
      await file.create(recursive: true);
      await file.writeAsBytes(assetData.buffer.asUint8List());
    }
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
                    await _startShelfLocalhostServer();
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
            ServerStatus.started =>
              'Server is running (Long press to stop server)',
            ServerStatus.starting => 'Starting server',
          }),
          subtitle: Text(
            switch (_serverStatus) {
              ServerStatus.stopped => 'Tap to start server',
              ServerStatus.stopping => 'Please wait...',
              ServerStatus.started =>
                'Server listening on port ${server!.port}',
              ServerStatus.starting => 'Please wait...',
            },
          ),
          trailing: switch (_serverStatus) {
            ServerStatus.started => const Icon(Icons.stop, color: Colors.red),
            ServerStatus.starting => const SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
            ServerStatus.stopping => const SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
            ServerStatus.stopped =>
              const Icon(Icons.play_arrow, color: Colors.green),
          },
        ),
        if (_serverStatus == ServerStatus.started)
          ListTile(
            onTap: () {
              LinkLauncher.launch(
                  'http://${server!.address.host}:${server!.port}');
            },
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.router, color: Colors.white),
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NetworkText(
                    'Local: ', '${server!.address.host}:${server!.port}'),
                FutureBuilder(
                  future: _networkInfo.getWifiIP(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _NetworkText('On your network: ',
                          '${snapshot.data}:${server!.port}');
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
            child: Icon(Icons.folder_copy, color: Colors.white),
          ),
          subtitle: const Text(
              'Copy the html project folder from flutter assets to device directory'),
          title: const Text('Prepare server'),
          onTap: () => _copyAssetsToDocuments(),
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
