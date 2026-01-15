/// Off-screen cell buffer for Dascade.
///
/// A [DascadeBuffer] represents a 2D grid of terminal cells backed by
/// a contiguous [List<int>]. Buffers are renderer-agnostic and contain
/// no rendering or terminal logic.
///
/// Buffers are designed to be resized to match terminal dimensions
/// and compared efficiently for differential rendering.
library;

/// A 2D buffer of packed terminal cells.
///
/// Cells are stored in row-major order:
/// `index = y * width + x`
final class DascadeBuffer {

  /// Width of the buffer.
  int _width;

  /// Height of the buffer.
  int _height;

  /// Data.
  List<int> _cells;

  /// Creates a new buffer with the given dimensions.
  ///
  /// All cells are initialized to empty.
  DascadeBuffer(final int width, final int height)
    : _width = width,
      _height = height,
      _cells = List<int>.filled(
        width * height,
        0,
        growable: false,
      );

  /// The buffer width in cells.
  int get width => _width;

  /// The buffer height in cells.
  int get height => _height;

  /// Total number of cells in the buffer.
  int get length => _cells.length;

  /// Returns the linear index for the given coordinates.
  int index(final int x, final int y) {
    assert(x >= 0 && x < _width);
    assert(y >= 0 && y < _height);
    return y * _width + x;
  }

  /// Returns the cell at the given coordinates.
  int get(final int x, final int y) {
    return _cells[index(x, y)];
  }

  /// Sets the cell at the given coordinates.
  void set(final int x, final int y, final int cell) {
    _cells[index(x, y)] = cell;
  }

  /// Returns the cell at the given linear index.
  int getAt(final int index) {
    assert(index >= 0 && index < _cells.length);
    return _cells[index];
  }

  /// Sets the cell at the given linear index.
  void setAt(final int index, final int cell) {
    assert(index >= 0 && index < _cells.length);
    _cells[index] = cell;
  }

  /// Clears the buffer by setting all cells to empty.
  void clear() {
    _cells.fillRange(0, _cells.length, 0);
  }

  /// Resizes the buffer to the given dimensions.
  ///
  /// Existing cell data is preserved where possible. Newly allocated
  /// areas are initialized to empty.
  void resize(final int newWidth, final int newHeight) {
    if(newWidth == _width && newHeight == _height) {
      return;
    }
    final List<int> newCells = List<int>.filled(newWidth * newHeight, 0, growable: false);
    final int copyWidth = newWidth < _width ? newWidth : _width;
    final int copyHeight = newHeight < _height ? newHeight : _height;
    for(int y = 0; y < copyHeight; y++) {
      final int oldRowStart = y * _width;
      final int newRowStart = y * newWidth;
      for(int x = 0; x < copyWidth; x++) {
        newCells[newRowStart + x] = _cells[oldRowStart + x];
      }
    }
    _width = newWidth;
    _height = newHeight;
    _cells = newCells;
  }

  /// Returns the internal cell list.
  ///
  /// This is intended for renderer and diff engine use only.
  List<int> get raw => _cells;

}
