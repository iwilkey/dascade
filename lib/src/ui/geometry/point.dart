/// Basic geometry class used across the Dascade UI system.
library;

/// Basic geometry class used across the Dascade UI system.
/// 
/// DUPoint represents a single coordinate in the terminal's 2D grid.
/// It is the foundation for positioning and layout calculations.
final class DUPoint {

  /// The horizontal coordinate (column).
  int x;

  /// The vertical coordinate (row).
  int y;

  /// Creates a point at (x, y).
  DUPoint({required this.x, required this.y});

}
