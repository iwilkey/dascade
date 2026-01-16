/// Public entrypoint for Dascade.
///
/// This file defines the **stable, platform-agnostic facade** used by all
/// Dascade applications. It is the *only* file that end users should import
/// to start a Dascade runtime.
///
/// Internally, this module dispatches execution to the correct platform
/// runtime (native or web) using **compile-time conditional imports**.
/// No runtime platform checks or branching are performed here.
///
/// From the user's perspective, this guarantees:
/// - A single, stable API surface
/// - Identical behavior across platforms
/// - Zero exposure to platform-specific implementation details
library;

import 'dart:async';

import 'package:dascade/src/runtime/dascade_framework.dart';
import 'package:dascade/src/runtime/dascade_native.dart'
    if(dart.library.html) 'package:dascade/src/runtime/dascade_web.dart';

/// Stable public API facade for Dascade.
///
/// This class is the **only supported entry point** for running a Dascade
/// application. All examples, documentation, and user code should invoke
/// Dascade exclusively through this interface.
///
/// The facade itself contains **no platform-specific logic**. Instead,
/// it forwards execution to a compile-time–selected runtime implementation.
///
/// Example:
/// ```dart
/// await Dascade.run((d) async {
///   while (true) {
///     d.beginFrame();
///     d.draw(0, 0, someCell);
///     d.endFrame();
///   }
/// });
/// ```
final class Dascade {

  const Dascade._();

  /// Runs a Dascade application on the active platform.
  ///
  /// This method initializes the appropriate Dascade runtime and executes
  /// the provided application callback within it.
  ///
  /// The concrete runtime implementation (native or web) is selected at
  /// **compile time** via conditional imports, ensuring optimal behavior
  /// and zero platform ambiguity.
  ///
  /// This is the **ONLY correct way** to start a Dascade application.
  ///
  /// Attempting to construct or invoke runtime implementations directly
  /// is unsupported and may result in undefined behavior.
  static Future<void> run(
    Future<void> Function(DascadeFramework d) app,
  ) {
    return execute(app);
  }

}
