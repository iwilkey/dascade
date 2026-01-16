/// Platform abstraction for Dascade.
///
/// A platform is responsible for providing the concrete terminal and
/// renderer implementations used by the runtime. Platform selection
/// occurs at compile time and allows Dascade to run on multiple targets
/// without conditional logic in higher level code.
library;

import 'package:dascade/src/input/input_interface.dart';
import 'package:dascade/src/output/rendering_interface.dart';
import 'package:dascade/src/output/terminal_interface.dart';

/// Defines the factory interface for platform specific backends.
///
/// Implementations must return compatible terminal and renderer pairs
/// for the active platform. The renderer is expected to operate using
/// the terminal instance provided by the platform.
abstract interface class DascadePlatform {

  /// Creates the terminal backend for the platform.
  ///
  /// The terminal is responsible for low level output and screen
  /// management.
  DascadeTerminalInterface createTerminal();

  /// Creates the renderer for the platform.
  ///
  /// The renderer manages buffered rendering and differential output
  /// using the provided terminal backend.
  DascadeRenderingInterface createRenderer(DascadeTerminalInterface terminal);

  /// Creates the input handler for the platform.
  ///
  /// The input handler is responsible for aquisition and reporting of key strokes and cursor input.
  DascadeInputInterface createInput();

}
