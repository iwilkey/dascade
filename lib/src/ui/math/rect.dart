/// Axis-aligned rectangle in the Dascade rendering plane.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/math/point.dart';

/// Axis-aligned rectangle in the Dascade rendering plane.
///
/// Rectangles define abstract layout space and clipping regions.
/// Coordinates are expressed in terminal cell units and use a
/// half-open interval:
/// - left/top are inclusive
/// - right/bottom are exclusive
///
/// This makes width/height calculations stable and composable.
final class DURect {

  /// Upper-left corner of the rectangle.
  DUPoint upperLeft;

  /// Lower-right corner of the rectangle (exclusive).
  DUPoint lowerRight;

  /// Creates a rectangle from two corner points.
  DURect({required this.upperLeft, required this.lowerRight});

  /// Left edge (inclusive).
  int get left => upperLeft.x;

  /// Top edge (inclusive).
  int get top => upperLeft.y;

  /// Right edge (exclusive).
  int get right => lowerRight.x;

  /// Bottom edge (exclusive).
  int get bottom => lowerRight.y;

  /// Width of the rectangle in cells.
  int get width => right - left;

  /// Height of the rectangle in cells.
  int get height => bottom - top;

  /// Returns a new rectangle inset on all sides by `n` cells.
  ///
  /// Useful for borders, padding, and content regions.
  DURect inset(int n) => DURect(
    upperLeft: DUPoint(x: left + n, y: top + n),
    lowerRight: DUPoint(x: right - n, y: bottom - n),
  );

  /// Returns a translated copy of this rectangle.
  DURect translate(int dx, int dy) => DURect(
    upperLeft: DUPoint(x: left + dx, y: top + dy),
    lowerRight: DUPoint(x: right + dx, y: bottom + dy),
  );

  /// Returns true if the given point lies within this rectangle.
  bool contains(int x, int y) => x >= left && x < right && y >= top && y < bottom;

  /// Returns the intersection of this rectangle and another.
  ///
  /// If the rectangles do not overlap, an empty rectangle is returned.
  DURect intersect(DURect other) {
    final int l = math.max(left, other.left);
    final int t = math.max(top, other.top);
    final int r = math.min(right, other.right);
    final int b = math.min(bottom, other.bottom);
    return DURect(
      upperLeft: DUPoint(x: l, y: t),
      lowerRight: DUPoint(x: r < l ? l : r, y: b < t ? t : b),
    );
  }

}
