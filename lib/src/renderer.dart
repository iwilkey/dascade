/// Immediate-mode renderer for Dascade.
///
/// Defines the [DascadeRenderer] class, which coordinates frame lifecycle,
/// buffered rendering, differential output to the terminal, and handling of terminal input.
///
/// The renderer exposes a stateless, immediate-mode API while managing
/// internal state such as frame buffers and previous render output.
library;

import 'package:dascade/src/buffer.dart';
import 'package:dascade/src/cell.dart';

import 'terminal.dart';

/// Coordinates immediate-mode rendering for terminal output.
///
/// [DascadeRenderer] is the primary entry point for issuing draw commands in
/// Dascade. Rendering follows a strict frame-based lifecycle:
///
/// 1. [begin] resets per-frame state
/// 2. Draw commands populate the active buffer
/// 3. [end] computes differences and emits output to the terminal
///
/// The renderer itself does not perform terminal I/O directly; instead,
/// it delegates all side effects to a [DascadeTerminal] backend.
final class DascadeRenderer {

  /// This should be a reference to only instance of DascadeTerminal in the framework. From now on, the renderer will act as the intermediary between user calls
  /// and the terminal.
  late final DascadeTerminal _terminal;

  /// Dimensions of the rendering plane.
  int _width = -1;
  int _height = -1;
  
  /// Buffers. Next is what is to be rendered and current is what is currently being rendered.
  DascadeBuffer? _next;
  DascadeBuffer? _current;

  /// Returns if the system is currently in between a begin() and end() call, where drawing can go.
  bool _frameActive = false;

  /// Creates a new renderer instance and assumes control of the users terminal.
  DascadeRenderer(final DascadeTerminal terminal) {
    _terminal = terminal;
    _terminal.enter();
    _syncBufferDimensions();
  }

  /// Begins a new rendering frame.
  ///
  /// Must be called before issuing any draw commands.
  void begin() {
    assert(!_frameActive, 'begin() called twice without end()!');
    _frameActive = true;
    _syncBufferDimensions();
    _next!.clear();
  }

  /// The current width of the available rendering plane.
  int get width => _width;

  /// The current height of the available rendering plane.
  int get height => _height;

  /// Draws a single cell into the current frame buffer. This is the most primitive way of rendering through Dascade.
  ///
  /// This method writes only to the front buffer. The cell will not
  /// appear on screen until [end] is called.
  /// 
  /// Dascade Coordinate System:
  /// 
  /// Left                        Right
  /// --------------------------------- Top
  /// | (0, 0)                        |
  /// |                               |
  /// |                               |
  /// |                               |
  /// |                               |
  /// |                               |
  /// |       (width - 1, height - 1) |
  /// --------------------------------- Bottom
  /// 
  void draw(final int x, final int y, final int cell) {
    if(!_frameActive) return;
    if(x < 0 || y < 0 || x >= _width || y >= _height) return;
    _next!.set(x, y, cell);
  }

  /// Ends the current frame, computes diffs, and renders changes.
  void end() {
    assert(_frameActive, 'end() called without begin()');
    _frameActive = false;
    _render();
  }

  /// Reads internal buffers and renders differences through the terminal backend.
  ///
  /// Complexity:
  /// - Worst-case: O(width * height) per frame (full buffer scan)
  /// - Typical-case: O(N + K), where K is the number of changed cells
  ///
  /// This full scan is intentional to guarantee correctness and simplicity.
  /// Terminal I/O dominates performance long before buffer iteration becomes
  /// a bottleneck.
  ///
  /// Potential optimizations (average-case improvements only):
  /// - Dirty-region tracking during draw() calls
  /// - Run-length batching of adjacent changed cells
  /// - Cursor movement minimization (tracking last cursor position)
  ///
  /// NOTE (iwilkey): Any optimization must preserve correctness under arbitrary
  /// draw order and partial updates. Avoid premature optimization.
  void _render() {
    final List<int> nextCells = _next!.raw;
    final List<int> currentCells = _current!.raw;
    for(int i = 0; i < nextCells.length; i++) {
      final int next = nextCells[i];
      if(next == currentCells[i]) continue;
      final int x = i % _width;
      final int y = i ~/ _width;
      /// NOTE (iwilkey): Because this is the most primitive API boundary, the definition of the Dascade coordinate system will originate
      /// from here. I have chosen to swap x and y to align with the way that glfw defines logical-pixel screen space (see above coordinate system). Just keep this
      /// in mind if you are editing the internals of the engine after this boundary.
      _terminal.moveCursor(y, x);
      _terminal.applyCellStyle(
        fg: DascadeCell.foreground(next),
        bg: DascadeCell.background(next),
        bold: DascadeCell.isBold(next),
        underline: DascadeCell.isUnderline(next),
        inverse: DascadeCell.isInverse(next),
      );
      final int glyph = DascadeCell.glyph(next);
      _terminal.write(
        glyph == 0 ? ' ' : String.fromCharCode(glyph),
      );
      currentCells[i] = next;
    }
    _terminal.flush();
  }

  /// Initializes or resizes internal buffers to match current terminal dimensions.
  void _syncBufferDimensions() {
    final int w = _terminal.width;
    final int h = _terminal.height;
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
    _terminal.clearScreen();
  }
  
}
