/// Rectangular region used for layout, clipping, and hit testing in the Dascade UI system.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/geometry/point.dart';

/// Rectangular region used for layout, clipping, and hit testing in the Dascade UI system.
/// 
/// A DURect represents a box in terminal space, defined by its upper-left and lower-right corners.
/// It supports basic geometric operations like inset, intersection, and point containment.
final class DURect {

  /// The top-left corner of the rectangle.
  DUPoint upperLeft;

  /// The bottom-right corner of the rectangle (exclusive).
  DUPoint lowerRight;

  /// Creates a rectangle from [upperLeft] to [lowerRight].
  DURect({required this.upperLeft, required this.lowerRight});

  /// The left edge (x-coordinate).
  int get left => upperLeft.x;

  /// The top edge (y-coordinate).
  int get top => upperLeft.y;

  /// The right edge (x-coordinate).
  int get right => lowerRight.x;

  /// The bottom edge (y-coordinate).
  int get bottom => lowerRight.y;

  /// The width of the rectangle.
  int get width => right - left;

  /// The height of the rectangle.
  int get height => bottom - top;

  /// Returns a new rectangle inset by [n] on all sides.
  DURect inset(final int n) => DURect(
    upperLeft: DUPoint(x: left + n, y: top + n),
    lowerRight: DUPoint(x: right - n, y: bottom - n),
  );

  /// Returns true if the given (x, y) point is inside this rectangle.
  bool contains(final int x, final int y) => x >= left && x < right && y >= top && y < bottom;

  /// Returns a new rectangle representing the intersection with [other].
  DURect intersects(final DURect other) {
    final int l = math.max(left, other.left);
    final int t = math.max(top, other.top);
    final int r = math.min(right, other.right);
    final int b = math.min(bottom, other.bottom);
    return DURect(
      upperLeft: DUPoint(x: l, y: t),
      lowerRight: DUPoint(x: math.max(l, r), y: math.max(t, b)),
    );
  }

}
