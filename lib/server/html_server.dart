import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../util/my_storage.dart';
import 'backend_server.dart';

class HtmlServer {
  static HttpServer? _server;
  static Future<int> start() async {
    var permissionStatus = await Permission.manageExternalStorage.status;
    if (!permissionStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    // Serve the device directory.
    var htmlProjectDir = MyStorage.getMasjidTvDirectory();
    var handler =
        createStaticHandler(htmlProjectDir.path, defaultDocument: 'index.html');

    // Create a Shelf cascade with the static file handler first, and the fallback handler second.
    var cascade = Cascade().add(handler).add(_echoRequest);

    // read port from SP or assign randomly
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var port = prefs.getInt('kSpServerPort') ?? _getRandomPort();

    // Start the server on port
    _server = await io.serve(cascade.handler, InternetAddress.anyIPv4, port);
    debugPrint('Serving at http://${_server!.address.host}:${_server!.port}');
    return _server!.port;
  }

  static String get url => 'http://${_server!.address.host}:${_server!.port}';
  static String get host => _server!.address.host;
  static int get port => _server!.port;

  static Response _echoRequest(Request request) {
    // Create a plain text response with the request body.
    return Response.ok('Request for "${request.url}" received.');
  }

  static int _getRandomPort() {
    var genPort = 5000 + Random().nextInt(3080);
    return genPort == BackendServer.reservedPort ? _getRandomPort() : genPort;
  }

  static Future<void> stop() async => await _server?.close();
}
