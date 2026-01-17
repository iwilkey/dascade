/// Dascade's Input isolate routine.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:dascade/src/input/native/mouse_event.dart';
import 'package:dascade/src/input/native/windows_vt.dart';

/// Input isolate routine.
/// 
/// User's of this framework will never have to deal with this object.
final class DascadeNativeInputPoller {

  /// This is a static class; it should never be instantiated.
  DascadeNativeInputPoller._();

  /// Input isolate routine.
  /// 
  /// Polls input off of the main rendering thread.
  /// 
  /// Owns stdin and emits [Key] or [DascadeNativeMouseEvent].
  static void routine(final SendPort sendPort) {
    /// Patch for windows: Windows terminals don't read ANSI input by default, so we need to do the following...
    if(Platform.isWindows) {
      DascadeWindowsVT.enableInput();
      DascadeWindowsVT.enableOutput();
    }
    stdin.echoMode = false;
    stdin.lineMode = false;
    while(true) {
      final int codeUnit = stdin.readByteSync();
      if(codeUnit <= 0) continue;
      // Ctrl+A .. Ctrl+Z
      if(codeUnit >= 0x01 && codeUnit <= 0x1a) {
        sendPort.send(
          Key.control(ControlCharacter.values[codeUnit]),
        );
        continue;
      }
      // Escape sequences
      if(codeUnit == 0x1b) {
        final int next = stdin.readByteSync();
        if(next == -1) {
          sendPort.send(Key.control(ControlCharacter.escape));
          continue;
        }
        // Mouse: ESC [ <
        if (next == 0x5b) {
          final int third = stdin.readByteSync();
          if (third == 0x3c) {
            // SGR mouse sequence
            final buffer = <int>[0x1b, 0x5b, 0x3c];
            while (true) {
              final int b = stdin.readByteSync();
              buffer.add(b);
              if(b == 0x4d || b == 0x6d) break; // M or m
            }
            final String seq = String.fromCharCodes(buffer);
            final match = RegExp(r'\x1b\[<(\d+);(\d+);(\d+)([Mm])').firstMatch(seq);
            if(match != null) {
              final int code = int.parse(match.group(1)!);
              final int x = int.parse(match.group(2)!) - 1;
              final int y = int.parse(match.group(3)!) - 1;
              final bool release = match.group(4) == 'm';
              final bool isScroll = (code & 0x60) == 0x40;
              int scroll = 0;
              bool leftDown = false;
              bool leftUp = false;
              bool middleDown = false;
              bool middleUp = false;
              bool rightDown = false;
              bool rightUp = false;
              if(isScroll) {
                if(code == 64) {
                  scroll = 1;
                } else if (code == 65) {
                  scroll = -1;
                }
              } else {
                final int button = code & 0x3;
                if(release) {
                  switch (button) {
                    case 0: leftUp = true; break;
                    case 1: middleUp = true; break;
                    case 2: rightUp = true; break;
                  }
                } else {
                  switch (button) {
                    case 0: leftDown = true; break;
                    case 1: middleDown = true; break;
                    case 2: rightDown = true; break;
                  }
                }
              }
              sendPort.send(
                DascadeNativeMouseEvent(
                  x: x,
                  y: y,
                  leftDown: leftDown,
                  leftUp: leftUp,
                  middleDown: middleDown,
                  middleUp: middleUp,
                  rightDown: rightDown,
                  rightUp: rightUp,
                  scroll: scroll,
                ),
              );
              continue;
            }
          }
          // Not mouse → fall back to key parsing
          final int c2 = stdin.readByteSync();
          final Key key = Key.control(ControlCharacter.escape);
          switch(c2) {
            case 65:
              key.controlChar = ControlCharacter.arrowUp;
              break;
            case 66:
              key.controlChar = ControlCharacter.arrowDown;
              break;
            case 67:
              key.controlChar = ControlCharacter.arrowRight;
              break;
            case 68:
              key.controlChar = ControlCharacter.arrowLeft;
              break;
            default:
              key.controlChar = ControlCharacter.unknown;
          }
          sendPort.send(key);
          continue;
        }
        // Other escape cases
        sendPort.send(Key.control(ControlCharacter.escape));
        continue;
      }
      // Backspace
      if(codeUnit == 0x7f) {
        sendPort.send(Key.control(ControlCharacter.backspace));
        continue;
      }
      // Printable
      sendPort.send(
        Key.printable(String.fromCharCode(codeUnit)),
      );
    }
  }

}
