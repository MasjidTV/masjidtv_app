import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:path/path.dart' as p;

import 'backend_server.dart';

class HtmlServer {
  static HttpServer? _server;
  static Future<int> start() async {
    // Serve the device directory.
    final directory = await getExternalStorageDirectory();
    var handler = createStaticHandler(p.join(directory!.path, 'web'),
        defaultDocument: 'index.html');

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
