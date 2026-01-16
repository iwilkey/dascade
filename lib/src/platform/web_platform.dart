/// Web platform implementation for Dascade.
///
/// This class wires together the web specific terminal and renderer
/// implementations. It is selected at compile time using conditional
/// imports and is never instantiated on native platforms.
///
/// The platform is responsible only for object creation. All rendering
/// behavior and lifecycle control is handled by the renderer and terminal
/// implementations themselves.
library;

import 'package:dascade/src/input/input_interface.dart';
import 'package:dascade/src/input/web/input.dart';

import 'platform.dart';
import 'package:dascade/src/output/web/terminal.dart';
import 'package:dascade/src/output/web/renderer.dart';
import 'package:dascade/src/output/terminal_interface.dart';
import 'package:dascade/src/output/rendering_interface.dart';

/// Web platform factory for Dascade.
///
/// Creates the web terminal and web renderer instances used when running
/// in a browser environment.
final class DascadePlatformImpl implements DascadePlatform {

  /// Creates the web terminal backend.
  ///
  /// This terminal renders cells to a full screen HTML canvas and
  /// emulates ANSI behavior in software.
  @override
  DascadeTerminalInterface createTerminal() {
    return DascadeTerminalWeb();
  }

  /// Creates the web renderer.
  ///
  /// The renderer is responsible for buffered rendering and differential
  /// output. The provided terminal is expected to be a
  /// [DascadeTerminalWeb] instance.
  @override
  DascadeRenderingInterface createRenderer(DascadeTerminalInterface terminal) {
    return DascadeWebRenderer(terminal as DascadeTerminalWeb);
  }

  /// Creates a web-based input handler.
  ///
  /// The input handler is responsible for aquisition and reporting of key strokes and cursor input.
  @override
  DascadeInputInterface createInput() {
    return DascadeWebInput()..start();
  }

}
