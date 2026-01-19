/// Central interaction state for a single UI frame.
library;

import 'package:dascade/dascade.dart';

/// Central interaction state for a single UI frame.
///
/// This struct tracks pointer-related UI semantics such as:
/// - which element is currently hovered (`hot`)
/// - which element is being pressed (`active`)
/// - which element owns keyboard focus (`focused`)
/// - which element has pointer capture (`captured`)
///
/// The model is inspired by immediate-mode UI systems (e.g. ImGui),
/// but enforces stricter focus rules (focus is only granted on click).
final class DUIInteraction {
  
  /// Element currently under the pointer for this frame.
  ///
  /// Reset every frame and recomputed by widgets during interaction.
  int? hot;

  /// Element that was pressed on pointer-down.
  int? active;

  /// Element that currently owns keyboard focus.
  int? focused;

  /// Element that has captured the pointer during a drag.
  int? captured;

  bool _prevMouseLeftDown = false;

  /// Initializes per-frame interaction state.
  ///
  /// Must be called once at the beginning of each frame.
  void beginFrame() {
    hot = null;
  }

  /// Finalizes interaction state for the frame.
  ///
  /// Handles pointer release cleanup and updates button history.
  /// Must be called once at the end of each frame.
  void endFrame(DascadeFramework d) {
    if (!d.mouseLeftDown) {
      active = null;
      captured = null;
    }
    _prevMouseLeftDown = d.mouseLeftDown;
  }

  /// Returns `true` only on the frame the mouse button transitions
  /// from up → down.
  bool mousePressed(DascadeFramework d) => !_prevMouseLeftDown && d.mouseLeftDown;

  /// Returns `true` only on the frame the mouse button transitions
  /// from down → up.
  bool mouseReleased(DascadeFramework d) => _prevMouseLeftDown && !d.mouseLeftDown;

  /// Returns `true` if the given element currently owns focus.
  bool isFocused(int id) => focused == id;

  /// Requests keyboard focus for the given element.
  ///
  /// Focus is exclusive; any previously focused element loses focus.
  void requestFocus(int id) {
    focused = id;
  }

  /// Clears keyboard focus entirely.
  void clearFocus() {
    focused = null;
  }

  /// Returns `true` if the given element currently owns pointer capture.
  bool isCapturedBy(int id) => captured == id;
  
}
