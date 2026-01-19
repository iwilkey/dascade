/// Integer 2D point in the Dascade rendering plane.
library;

/// Integer 2D point in the Dascade rendering plane.
///
/// Coordinates are expressed in terminal cell units, with `(0, 0)`
/// representing the upper-left corner of the screen.
///
/// Used for layout, clipping, and rendering calculations.
final class DUPoint {

  /// Horizontal position (column).
  int x;

  /// Vertical position (row).
  int y;

  /// Creates a point at the given coordinates.
  DUPoint({required this.x, required this.y});

  /// Returns a copy of this point.
  DUPoint copy() => DUPoint(x: x, y: y);

}
