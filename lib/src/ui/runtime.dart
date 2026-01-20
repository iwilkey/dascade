/// Manages per-frame input state for the Dascade UI system.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/rect.dart';

/// Manages per-frame input state for the Dascade UI system.
///
/// Handles mouse edges, keyboard input, focus tracking, and typed characters.
/// This class is passed to all elements during interaction and rendering to
/// provide a consistent view of user input for the current frame.
final class DUIRuntime {

  final DascadeFramework d;

  // Mouse edges
  bool _prevMouseDown = false;
  late bool mousePressed;
  late bool mouseReleased;

  // Focus and active elements are tracked by reference.
  DUElement? focused;
  DUElement? active;

  // Typed character input for this frame (single character or empty).
  String typed = '';

  // Tracks whether any element claimed focus this frame.
  bool _didFocusThisFrame = false;

  DUIRuntime(this.d);

  /// Current mouse X position (column).
  int get mx => d.mouseX;

  /// Current mouse Y position (row).
  int get my => d.mouseY;

  /// True if mouse button is held down this frame.
  bool get mouseDown => d.mouseLeftDown;

  /// Mouse scroll wheel delta this frame.
  int get wheel => d.mouseScrollwheelValue;

  /// True if backspace key is held.
  bool get backspace => d.backspace;

  /// True if delete key is held.
  bool get delete => d.delete;

  /// True if enter key is held.
  bool get enter => d.enter;

  /// Called at the beginning of each frame to compute edges and typed input.
  void beginFrame() {
    mousePressed = !_prevMouseDown && mouseDown;
    mouseReleased = _prevMouseDown && !mouseDown;
    typed = d.lastInputChar ?? '';
    _didFocusThisFrame = false;
  }

  /// Called at the end of each frame to finalize focus state and cleanup.
  void endFrame() {
    _prevMouseDown = mouseDown;
    // Clear active if mouse is up.
    if(!mouseDown) {
      active = null;
    }
    // Clear focus if no one claimed it and mouse was released outside.
    if(!_didFocusThisFrame && focused != null) {
      final bool outside = !focused!.rect.contains(mx, my);
      if(mouseReleased && outside) {
        focused = null;
      }
    }
  }

  /// Returns true if the mouse is currently hovering inside [r].
  bool hovered(final DURect r) => r.contains(mx, my);

  /// Handles press-and-release to request focus.
  ///
  /// Returns true if the element was both pressed and released inside [r],
  /// and focus was claimed this frame.
  bool clicked(final DUElement e, final DURect r) {
    if(mousePressed && hovered(r)) {
      active = e;
    }
    if(!mouseReleased) return false;
    final bool ok = (active == e) && hovered(r);
    if(ok) {
      focused = e;
      _didFocusThisFrame = true;
    }
    return ok;
  }

}
