import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../util/my_storage.dart';

/// Backend server is to manage config files.
/// ie: Read & write to config files from html frontend.
class BackendServer {
  /// Let's make the port constant, so that we can
  /// maintain this value in the HTML file
  static const _port = 7000;

  static get reservedPort => _port;

  static HttpServer? _server;

  /// Start server
  static Future<int> start() async {
    // Use any available host or container IP (usually `0.0.0.0`).
    final ip = InternetAddress.anyIPv4;

    // Configure routes.
    final router = Router()
      ..get('/', _rootHandler)
      ..get('/getConfig', _readConfigFile)
      ..post('/edit', _saveConfigFile);

    // Configure a pipeline that logs requests.
    final handler = const Pipeline()
        .addMiddleware(corsHeaders(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
          },
        ))
        .addMiddleware(logRequests())
        .addHandler(router);

    try {
      _server = await serve(handler, ip, _port);
      debugPrint('Server listening on port ${_server?.port}');
      return _server!.port;
    } on SocketException catch (e) {
      debugPrint(e.message);
      throw Exception(
        "Can't start b'end server. Probably the port isn't clean. Close the app and reopen to try again",
      );
    }
  }

  static Future<void> stop() async => await _server?.close();

  static Response _rootHandler(Request req) {
    return Response.ok('Hello, World!\n', headers: {
      'Content-Type': 'text/plain',
      'Access-Control-Allow-Origin': '*'
    });
  }

  /// Retrieve config file from frontend and save it
  static Future<Response> _saveConfigFile(Request request) async {
    // open a file
    final directory = MyStorage.getMasjidTvDirectory();
    final file = File('${directory.path}/config.json');
    debugPrint('Accessing file: ${file.path}');

    final contents = await request.readAsString();

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    final prettyprint = encoder.convert(json.decode(contents));

    // print the content
    // debugPrint('Content: $prettyprint');

    // write to a file
    file.writeAsStringSync(prettyprint);

    // re-read the content
    // var verifyContent = file.readAsStringSync();
    // debugPrint('Content: $verifyContent');
    return Response.ok('Written', headers: {
      'Content-Type': 'text/plain',
      'Access-Control-Allow-Origin': '*'
    });
  }

  /// read config file and return it to frontend
  static Future<Response> _readConfigFile(Request request) async {
    // open a file
    final directory = MyStorage.getMasjidTvDirectory();
    final file = File('${directory.path}/config.json');

    final contents = await file.readAsString();
    debugPrint('Read content: $contents');
    return Response.ok(contents, headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    });
  }
}
