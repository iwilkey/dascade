/// A layout-only element that occupies space and fills its rect with color.
///
/// A DUSpacer is useful for padding layouts, gutters, dividers, and panels.
/// It does not participate in input (cannot be focused or clicked).
library;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';

/// A layout-only element that fills its rect with a solid color.
final class DUSpacer implements DUElement {

  /// Fill color used for the spacer.
  final int color;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  DUSpacer({
    required this.color,
  });

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  @override
  void interact(final DURuntime r) {
    // Intentionally no-op: spacers never interact.
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    for (int y = _rect.top; y < _rect.bottom; y++) {
      for (int x = _rect.left; x < _rect.right; x++) {
        p.draw(
          x,
          y,
          0x20,
          fg: 0,
          bg: color,
        );
      }
    }
  }
}
