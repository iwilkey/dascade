/// Base interface for all UI elements in the Dascade system.
library;

import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';

/// Base interface for all UI elements in the Dascade system.
///
/// Every element must define its layout bounds, handle user interaction,
/// and draw itself using a painter. This is the core abstraction that enables
/// custom widgets, layout containers, and interactive components.
abstract class DUElement {

  /// The bounding rectangle of the element (assigned during layout).
  DURect get rect;

  /// Called during layout to assign the element's position and size.
  void layout(final DURect rect);

  /// Handles user interaction (mouse, keyboard, focus) for this frame.
  void interact(final DUIRuntime r);

  /// Renders the element using the given [painter] and [runtime].
  void render(final DUIRenderer p, final DUIRuntime r);

}
