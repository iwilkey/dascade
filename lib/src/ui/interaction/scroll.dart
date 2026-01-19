/// Generic 2D scroll state usable by any UI element.
library;

/// Generic 2D scroll state usable by any UI element.
///
/// This is a simple mutable container intended to be stored in
/// [DUIStateStore] and shared across frames.
final class DUScrollState {
  /// Horizontal scroll offset (in cells).
  int x = 0;

  /// Vertical scroll offset (in cells).
  int y = 0;

  /// Clamps the scroll offsets to the provided bounds.
  ///
  /// Call this after mutating [x] or [y] to ensure scrolling
  /// stays within valid content limits.
  void clamp({required int maxX, required int maxY}) {
    if(x < 0) x = 0;
    if(y < 0) y = 0;
    if(x > maxX) x = maxX;
    if(y > maxY) y = maxY;
  }
}
