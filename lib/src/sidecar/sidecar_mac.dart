/// macOS implementation of the Dascade Sidecar terminal.
///
/// This implementation launches a new Terminal.app tab and streams log
/// output to it via a named FIFO pipe. The terminal session blocks on
/// reading the pipe and exits automatically when the pipe is closed,
/// ensuring clean shutdown behavior.
///
/// This class is internal to the Dascade sidecar system and should not be
/// instantiated directly. Use [DascadeSidecar.open] instead.
///
library;

import 'dart:io';

import 'package:dascade/src/sidecar/sidecar_impl.dart';

/// macOS-specific sidecar backend.
///
/// Manages a FIFO pipe connected to a dedicated Terminal.app tab.
/// Messages written via [write] are streamed to the terminal without
/// interfering with Dascade’s primary rendering terminal.
final class DascadeSidecarMac implements DascadeSidecarImpl {

  /// Private constructor used by [open].
  DascadeSidecarMac._(this._pipePath, this._sink);

  /// Filesystem path of the FIFO pipe.
  final String _pipePath;

  /// Sink writing into the FIFO pipe.
  final IOSink _sink;

  /// Opens a new macOS Terminal tab and attaches a FIFO-backed log stream.
  ///
  /// The terminal blocks on the pipe until [dispose] is called, at which
  /// point the pipe is closed and the terminal session exits automatically.
  static Future<DascadeSidecarMac> open() async {
    final String pipePath = '${Directory.systemTemp.path}/dascade_sidecar.pipe';
    final File pipeFile = File(pipePath);

    if(pipeFile.existsSync()) {
      pipeFile.deleteSync();
    }

    await Process.run('mkfifo', [pipePath]);

    await Process.run(
      'osascript',
      [
        '-e',
'''
tell application "Terminal"
  activate
  do script "echo '--- Dascade Sidecar ---'; cat $pipePath; exit"
end tell
'''
      ],
    );

    final IOSink sink = pipeFile.openWrite(mode: FileMode.write);
    sink.writeln('[Dascade] Sidecar attached.');
    sink.flush();

    return DascadeSidecarMac._(pipePath, sink);
  }

  /// Writes a message to the sidecar terminal.
  @override
  void write(final String message) {
    _sink.writeln(message);
  }

  /// Closes the sidecar terminal and releases all resources.
  ///
  /// This closes the FIFO pipe, causing the terminal session to exit.
  @override
  void dispose() {
    try {
      _sink.writeln('\n[Dascade] Sidecar closed.');
      _sink.flush();
      _sink.close();
    } catch (_) {}

    try {
      File(_pipePath).deleteSync();
    } catch (_) {}
  }
}
