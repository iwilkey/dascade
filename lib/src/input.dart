/// Keyboard input handling for Dascade.
///
/// This module provides asynchronous, non-blocking keyboard input
/// for terminal applications using `dart_console`.
///
/// IMPORTANT:
/// The underlying terminal API only supports *blocking* key reads.
/// To avoid stalling the render loop, this class runs a dedicated
/// background input pump that continuously reads key presses and
/// buffers them for later consumption.
///
/// This design mirrors traditional terminal UI libraries (ncurses,
/// libtermkey, etc.) and is the only correct way to handle terminal
/// input without blocking rendering.
///
/// Only keyboard input is supported at this time.
library;

import 'package:dart_console/dart_console.dart';

import 'terminal.dart';

import 'dart:isolate';

void DascadeInputIsolate(SendPort sendPort) {
  final console = Console();
  console.rawMode = true;
  while(true) {
    final key = console.readKey(); // blocking
    sendPort.send(key);
  }
}

/// Asynchronous keyboard input manager for Dascade.
final class DascadeInput {

  final DascadeTerminal _terminal;

  bool _running = false;

  /// Creates a new input manager bound to the given terminal.
  DascadeInput(this._terminal);

  void start() {
    if(_running) return;
    _running = true;
    _terminal.enableRawMode();
  }

  Key readKey() {
    Key key = _terminal.readKey();
    return key;
  }

  /// Stops input processing and restores terminal state.
  void stop() {
    if(!_running) return;
    _running = false;
    _terminal.disableRawMode();
  }

  /// Releases resources and stops input processing.
  void dispose() {
    stop();
  }

}
