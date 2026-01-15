/// Dascade's Sidecar provides an optional secondary terminal (“sidecar”) for logging output
/// while a Dascade application is running.
///
/// Dascade takes exclusive control of the primary terminal for rendering,
/// making direct use of `print()`, `stdout`, or `stderr` unsafe during
/// runtime. The sidecar offers an isolated output channel that does not
/// interfere with rendering.
///
/// The sidecar is managed as a singleton and is created lazily via [open].
/// Output can be written at any time using [write], and resources are
/// released with [dispose].
///
/// Platform support is delegated to platform-specific implementations.
/// Currently, only macOS is supported. Calling [open] on unsupported
/// platforms throws an [UnimplementedError].
///
library;

import 'dart:io';

import 'package:dascade/src/sidecar/sidecar_impl.dart';
import 'package:dascade/src/sidecar/sidecar_mac.dart';

/// Static entry point for managing the Dascade sidecar terminal.
///
/// This class cannot be instantiated. All interaction is performed through
/// its static methods, which forward to a platform-specific
/// [DascadeSidecarImpl] when available.
abstract final class DascadeSidecar {

  /// The active sidecar instance, if one has been opened.
  static DascadeSidecarImpl? _instance;

  /// Opens the sidecar terminal if it has not already been created.
  ///
  /// Returns the active [DascadeSidecarImpl]. On unsupported platforms,
  /// this method throws an [UnimplementedError].
  static Future<DascadeSidecarImpl?> open() async {
    if(_instance != null) return _instance;
    if(Platform.isMacOS) {
      _instance = await DascadeSidecarMac.open();
      return _instance;
    }
    throw UnimplementedError(
      'DascadeSidecar not implemented for this platform',
    );
  }

  /// Writes a message to the sidecar terminal, if one is active.
  ///
  /// If the sidecar has not been opened, this call is a no-op.
  static void write(String message) {
    _instance?.write(message);
  }

  /// Disposes of the sidecar terminal and releases all resources.
  ///
  /// Safe to call multiple times.
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }

}
