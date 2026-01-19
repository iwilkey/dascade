/// Native platform implementation for Dascade.
///
/// This platform provides terminal and renderer implementations backed
/// by the host operating system terminal. It is selected at compile time
/// for non web targets using conditional imports.
library;

import 'dart:io';

import 'package:dascade/src/input/input_interface.dart';
import 'package:dascade/src/input/native/input.dart';

import 'platform.dart';
import 'package:dascade/src/output/native/terminal.dart';
import 'package:dascade/src/output/native/renderer.dart';
import 'package:dascade/src/output/terminal_interface.dart';
import 'package:dascade/src/output/rendering_interface.dart';

/// Native platform factory for Dascade.
///
/// Creates terminal and renderer instances that target a real system
/// terminal and use ANSI escape sequences for output.
final class DascadePlatformImpl implements DascadePlatform {

  /// Creates the native terminal backend.
  ///
  /// Mouse tracking is enabled by default to support interactive
  /// terminal applications.
  @override
  DascadeTerminalInterface createTerminal() {
    if(Platform.isWindows) {
      return DascadeNativeTerminal()..enableMouse();
    } else {
      /// POSIX-style terminal; raw mode! SIGINT will not be supported, though.
      return DascadeNativeTerminal()..enableMouse()..enableRawMode();
    }
  }

  /// Creates the native renderer.
  ///
  /// The renderer performs buffered and differential rendering using
  /// the provided native terminal backend.
  @override
  DascadeRenderingInterface createRenderer(DascadeTerminalInterface terminal) {
    return DascadeNativeRenderer(terminal as DascadeNativeTerminal);
  }

  /// Creates a native input handler.
  ///
  /// The input handler is responsible for aquisition and reporting of key strokes and cursor input.
  @override
  DascadeInputInterface createInput() {
    return DascadeNativeInput()..start();
  }

}
