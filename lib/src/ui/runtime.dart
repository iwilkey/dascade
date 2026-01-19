/// Per-frame runtime context passed to every UI element.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/interaction/input.dart';
import 'package:dascade/src/ui/interaction/interaction.dart';
import 'package:dascade/src/ui/interaction/scroll.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/state.dart';

/// Per-frame runtime context passed to every UI element.
///
/// Provides unified access to:
/// - raw platform input ([d])
/// - persistent widget state ([state])
/// - interaction state (hot/active/focused)
/// - key edge detection
/// - helper methods for pointer, keyboard, scrolling, and IDs
///
/// This object is recreated every frame but references long-lived
/// state stores where appropriate.
final class DUIRuntime {
  
  /// Underlying Dascade framework (raw input + drawing).
  final DascadeFramework d;

  /// Cross-frame state storage keyed by stable element IDs.
  final DUIStateStore state;

  /// Interaction state (hot / active / focused / capture).
  final DUIInteraction interaction;

  /// Key edge tracker for pressed/released detection.
  final DUKeyTracker keys;

  /// Text input received this frame (single character).
  ///
  /// Provided as a string to allow future expansion to IME or
  /// multi-codepoint input without breaking APIs.
  final String typed;

  /// Optional manual ID stack for scoped widget IDs.
  ///
  /// Used by complex widgets that internally emit sub-elements.
  final List<int> _idStack;

  DUIRuntime({
    required this.d,
    required this.state,
    required this.interaction,
    required this.keys,
    required this.typed,
    required List<int> idStack,
  }) : _idStack = idStack;

  /// Returns true if the mouse cursor is inside [r].
  bool hovered(DURect r) => r.contains(d.mouseX, d.mouseY);

  /// Returns true while this element is the active one and the
  /// mouse button is held down.
  bool held(int id) => interaction.active == id && d.mouseLeftDown;

  /// Detects a mouse press inside [r] and claims active/capture.
  ///
  /// This sets:
  /// - [interaction.hot] when hovered
  /// - [interaction.active] and [interaction.captured] on press
  bool pressedOn(int id, DURect r) {
    final bool h = hovered(r);
    if (h) interaction.hot = id;
    if (h && interaction.mousePressed(d)) {
      interaction.active = id;
      interaction.captured = id;
      return true;
    }
    return false;
  }

  /// Detects a mouse release that logically belongs to this element.
  ///
  /// Returns true if:
  /// - the element captured the mouse, or
  /// - the mouse was released while hovered and active
  bool releasedOn(int id, DURect r) {
    final bool h = hovered(r);
    if (!interaction.mouseReleased(d)) return false;
    if (interaction.isCapturedBy(id)) return true;
    return h && interaction.active == id;
  }

  /// High-level click helper.
  ///
  /// Guarantees correct behavior by:
  /// - internally claiming active/capture on press
  /// - returning true exactly once on a valid click release
  ///
  /// Most widgets should prefer this over manual press/release logic.
  bool clicked(int id, DURect r) {
    pressedOn(id, r);

    if (!interaction.mouseReleased(d)) return false;

    final bool h = hovered(r);
    final bool ok =
        (interaction.active == id) && (interaction.isCapturedBy(id) || h);
    return ok;
  }

  /// Returns true if this element currently owns keyboard focus.
  bool focused(int id) => interaction.isFocused(id);

  /// Requests keyboard focus for this element.
  void requestFocus(int id) => interaction.requestFocus(id);

  /// Clears keyboard focus entirely.
  void clearFocus() => interaction.clearFocus();

  /// Returns true while the key is held down.
  bool keyDown(DUKey k) => keys.down(k);

  /// Returns true on the frame the key was pressed.
  bool keyPressed(DUKey k) => keys.pressed(k);

  /// Returns true on the frame the key was released.
  bool keyReleased(DUKey k) => keys.released(k);

  /// Applies mouse wheel scrolling to [s] if the cursor is over [rect].
  ///
  /// Supports horizontal and/or vertical scrolling with configurable speed.
  void applyScrollWheel(
    DURect rect,
    DUScrollState s, {
    bool horizontal = false,
    bool vertical = true,
    int speed = 1,
  }) {
    if (!hovered(rect)) return;
    final int delta = d.mouseScrollwheelValue;
    if (delta == 0) return;
    if (vertical) s.y += (-delta) * speed;
    if (horizontal) s.x += (-delta) * speed;
  }

  /// Pushes a scoped ID seed for nested widget construction.
  ///
  /// Useful when a single element emits multiple logical children.
  void pushId(String key) {
    final int seed = _idStack.isEmpty ? 0 : _idStack.last;
    _idStack.add(_hash(seed, key));
  }

  /// Pops the most recent scoped ID seed.
  void popId() {
    if (_idStack.isNotEmpty) _idStack.removeLast();
  }

  /// Computes a stable ID under the current scope.
  int scopedId(String leaf) {
    final int seed = _idStack.isEmpty ? 0 : _idStack.last;
    return _hash(seed, leaf);
  }

  int _hash(int seed, String s) {
    int h = seed;
    for (int i = 0; i < s.length; i++) {
      h = 31 * h + s.codeUnitAt(i);
    }
    return h;
  }
}
