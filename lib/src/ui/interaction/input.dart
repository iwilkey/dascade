/// Logical keys and key tracker for the Dascade UI system.
library;

import 'package:dascade/dascade.dart';

/// Logical keys recognized by the Dascade UI system.
///
/// This enum represents a normalized subset of keyboard inputs
/// exposed by [DascadeFramework], allowing widgets to reason
/// about key state without depending on raw platform details.
enum DUKey {
  up,
  down,
  left,
  right,
  pageUp,
  pageDown,
  home,
  end,
  escape,
  delete,
  backspace,
  space,
}

/// Tracks per-frame key state and detects key edges.
///
/// [DUKeyTracker] snapshots keyboard input at the beginning of
/// each frame and compares it against the previous frame to
/// expose `down`, `pressed`, and `released` semantics.
///
/// This enables immediate-mode widgets to react to discrete
/// key events without maintaining their own history.
final class DUKeyTracker {
  final Map<DUKey, bool> _prev = {};
  final Map<DUKey, bool> _cur = {};

  /// Captures the current keyboard state from [DascadeFramework].
  ///
  /// Must be called once at the start of each frame.
  void beginFrame(DascadeFramework d) {
    _cur[DUKey.up] = d.up;
    _cur[DUKey.down] = d.down;
    _cur[DUKey.left] = d.left;
    _cur[DUKey.right] = d.right;
    _cur[DUKey.pageUp] = d.pageUp;
    _cur[DUKey.pageDown] = d.pageDown;
    _cur[DUKey.home] = d.home;
    _cur[DUKey.end] = d.end;
    _cur[DUKey.escape] = d.escape;
    _cur[DUKey.delete] = d.delete;
    _cur[DUKey.backspace] = d.backspace;
    _cur[DUKey.space] = d.space;
  }

  /// Finalizes the frame by promoting current state to previous.
  ///
  /// Must be called once at the end of each frame.
  void endFrame() {
    _prev
      ..clear()
      ..addAll(_cur);
  }

  /// Returns `true` while the key is currently held down.
  bool down(DUKey k) => _cur[k] ?? false;

  /// Returns `true` only on the frame the key transitions
  /// from up → down.
  bool pressed(DUKey k) => (_cur[k] ?? false) && !(_prev[k] ?? false);

  /// Returns `true` only on the frame the key transitions
  /// from down → up.
  bool released(DUKey k) => !(_cur[k] ?? false) && (_prev[k] ?? false);
  
}
