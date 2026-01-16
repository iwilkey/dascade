/// Platform independent renderer base for Dascade.
///
/// This class implements the shared rendering logic used by all
/// platforms. It manages frame lifecycle, buffer allocation,
/// differential rendering, and traversal of the render surface.
///
/// Platform specific subclasses are responsible only for translating
/// individual cells to their output target.
library;

import 'package:dascade/src/output/buffer.dart';
import 'package:dascade/src/output/rendering_interface.dart';

/// Shared renderer implementation used by all platforms.
///
/// This class provides a complete immediate mode rendering pipeline.
/// Subclasses must implement low level output behavior by overriding
/// [emitCell], [clearScreen], and [flush].
abstract class DascadeRenderingStrategy implements DascadeRenderingInterface {

  /// Whether or not to force the renderer to not diff cells.
  bool forceNoDiffing = false;

  int _width = -1;
  int _height = -1;

  DascadeBuffer? _next;
  DascadeBuffer? _current;

  bool _frameActive = false;

  /// The current terminal width in cells.
  int get terminalWidth;

  /// The current terminal height in cells.
  int get terminalHeight;

  /// Clears the entire rendering surface.
  ///
  /// Called automatically when the render surface is resized.
  void clearScreen();

  /// Emits a single cell to the output backend.
  ///
  /// Coordinates are guaranteed to be within bounds.
  void emitCell(final int x, final int y, final int cell);

  /// Flushes any buffered output.
  void flush();

  /// Creates a new rendering strategy.
  DascadeRenderingStrategy();

  /// Begins a new rendering frame.
  ///
  /// Must be called before issuing any draw commands.
  @override
  void begin() {
    assert(!_frameActive, 'begin() called twice without end()');
    _frameActive = true;
    syncBufferDimensions();
    _next!.clear();
  }

  /// Ends the current rendering frame and emits changes.
  @override
  void end() {
    assert(_frameActive, 'end() called without begin()');
    _frameActive = false;
    _render();
  }

  /// The current width of the rendering plane.
  @override
  int get width => _width;

  /// The current height of the rendering plane.
  @override
  int get height => _height;

  /// Draws a single cell into the active frame buffer.
  ///
  /// Draw calls outside the rendering bounds are ignored.
  @override
  void draw(final int x, final int y, final int cell) {
    if(!_frameActive) return;
    if(x < 0 || y < 0 || x >= _width || y >= _height) return;
    _next!.set(x, y, cell);
  }

  /// Computes differences between frame buffers and emits changes.
  ///
  /// This method performs a full buffer scan to guarantee correctness.
  /// Output backends are expected to dominate performance costs.
  void _render() {
    final List<int> nextCells = _next!.raw;
    final List<int> currentCells = _current!.raw;
    for(int i = 0; i < nextCells.length; i++) {
      final int next = nextCells[i];
      if(next == currentCells[i] && !forceNoDiffing) continue;
      final int x = i % _width;
      final int y = i ~/ _width;
      emitCell(x, y, next);
      currentCells[i] = next;
    }
    flush();
  }

  /// Synchronizes internal buffers with terminal dimensions.
  ///
  /// This method reallocates buffers when the render surface size
  /// changes and clears the output surface.
  void syncBufferDimensions() {
    final int w = terminalWidth;
    final int h = terminalHeight;
    if(w == _width && h == _height) return;
    _width = w;
    _height = h;
    if(_next == null) {
      _next = DascadeBuffer(_width, _height);
    } else {
      _next!.resize(_width, _height);
    }
    if(_current == null) {
      _current = DascadeBuffer(_width, _height);
    } else {
      _current!.resize(_width, _height);
      _current!.clear();
    }
    clearScreen();
  }

  /// Disposes of renderer resources.
  ///
  /// Subclasses may override this to perform platform specific cleanup.
  @override
  void dispose() {}

}
