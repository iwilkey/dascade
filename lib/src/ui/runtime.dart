/// Manages per-frame input state for the Dascade UI system.
///
/// Handles mouse edges, keyboard input edges, focus tracking, and typed chars.
/// This runtime is passed to all elements each frame to provide consistent
/// per-frame input semantics (pressed/released edges where needed).
library;

import 'package:dascade/dascade.dart';

/// Manages per-frame input state for the Dascade UI system.
final class DURuntime {

  /// Reference to the live framework.
  final DascadeFramework d;

  // Mouse edges.
  bool _prevMouseDown = false;
  late bool mousePressed;
  late bool mouseReleased;

  // Key edges (we track only what UI commonly needs).
  bool _prevLeft = false;
  bool _prevRight = false;
  bool _prevUp = false;
  bool _prevDown = false;
  bool _prevHome = false;
  bool _prevEnd = false;
  bool _prevPageUp = false;
  bool _prevPageDown = false;
  bool _prevEnter = false;
  bool _prevBackspace = false;
  bool _prevDelete = false;

  late bool leftPressed;
  late bool rightPressed;
  late bool upPressed;
  late bool downPressed;
  late bool homePressed;
  late bool endPressed;
  late bool pageUpPressed;
  late bool pageDownPressed;
  late bool enterPressed;
  late bool backspacePressed;
  late bool deletePressed;

  /// Focus and active elements are tracked by reference.
  DUElement? focused;
  DUElement? active;

  /// Typed character input for this frame (single character or empty).
  String typed = '';

  /// Tracks whether any element claimed focus this frame.
  bool _didFocusThisFrame = false;

  DURuntime(this.d);

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

  /// True if arrow keys are held.
  bool get left => d.left;
  bool get right => d.right;
  bool get up => d.up;
  bool get down => d.down;

  /// True if navigation keys are held.
  bool get home => d.home;
  bool get end => d.end;
  bool get pageUp => d.pageUp;
  bool get pageDown => d.pageDown;

  /// Called at the beginning of each frame to compute edges and typed input.
  void beginFrame() {
    // Mouse edges.
    mousePressed = !_prevMouseDown && mouseDown;
    mouseReleased = _prevMouseDown && !mouseDown;

    // Typed input.
    typed = d.lastInputChar ?? '';

    // Key edges.
    leftPressed = !_prevLeft && left;
    rightPressed = !_prevRight && right;
    upPressed = !_prevUp && up;
    downPressed = !_prevDown && down;

    homePressed = !_prevHome && home;
    endPressed = !_prevEnd && end;
    pageUpPressed = !_prevPageUp && pageUp;
    pageDownPressed = !_prevPageDown && pageDown;

    enterPressed = !_prevEnter && enter;
    backspacePressed = !_prevBackspace && backspace;
    deletePressed = !_prevDelete && delete;

    _didFocusThisFrame = false;
  }

  /// Called at the end of each frame to finalize focus state and cleanup.
  void endFrame() {
    _prevMouseDown = mouseDown;

    _prevLeft = left;
    _prevRight = right;
    _prevUp = up;
    _prevDown = down;

    _prevHome = home;
    _prevEnd = end;
    _prevPageUp = pageUp;
    _prevPageDown = pageDown;

    _prevEnter = enter;
    _prevBackspace = backspace;
    _prevDelete = delete;

    // Clear active if mouse is up.
    if (!mouseDown) {
      active = null;
    }

    // Clear focus if no one claimed it and mouse was released outside.
    if (!_didFocusThisFrame && focused != null) {
      final bool outside = !focused!.rect.contains(mx, my);
      if (mouseReleased && outside) {
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
    if (mousePressed && hovered(r)) {
      active = e;
    }
    if (!mouseReleased) return false;

    final bool ok = (active == e) && hovered(r);
    if (ok) {
      focused = e;
      _didFocusThisFrame = true;
    }
    return ok;
  }
  
}
