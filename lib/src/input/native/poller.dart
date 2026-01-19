/// Dascade's Native input isolate routine.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:dascade/src/input/native/mouse_event.dart';
import 'package:dascade/src/input/native/parser.dart';
import 'package:dascade/src/input/native/win_vt.dart';

/// Native input isolate routine.
/// 
/// User's of this framework will never have to deal with this object.
final class DascadeNativeInputPoller {

  /// This is a static class; it should never be instantiated.
  DascadeNativeInputPoller._();

  /// Native input isolate routine.
  /// 
  /// Polls input off of the main rendering thread.
  /// 
  /// Owns stdin and emits [Key] or [DascadeNativeMouseEvent] through the [DascadeNativeInputParseEmitter].
  static void routine(final SendPort sendPort) async {
    // Patch for windows: Windows terminals don't read ANSI input by default
    if(Platform.isWindows) {
      DascadeWindowsVT.enable();
    }
    stdin.echoMode = false;
    stdin.lineMode = false;
    while(true) {
      final int codeUnit = stdin.readByteSync();
      if(codeUnit < 0) continue;
      DascadeNativeInputParseEmitter.emit(codeUnit, sendPort);
      await Future<void>.delayed(Duration.zero);
    }
  }

}
