import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onEvent
    throw UnimplementedError();
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onStart
    throw UnimplementedError();
  }

}
