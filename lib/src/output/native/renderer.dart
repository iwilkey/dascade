/// Native renderer implementation for Dascade.
///
/// This renderer targets a real system terminal and uses ANSI escape
/// sequences for output. It builds on the shared rendering strategy
/// to provide buffered, differential, immediate mode rendering.
library;

import 'package:dascade/src/output/cell.dart';
import 'package:dascade/src/output/native/terminal.dart';
import 'package:dascade/src/output/rendering_strategy.dart';

/// Immediate mode renderer for native terminal output.
///
/// This class coordinates frame lifecycle and delegates all terminal
/// side effects to a [DascadeNativeTerminal] backend. Rendering follows
/// a strict begin and end frame model.
final class DascadeNativeRenderer extends DascadeRenderingStrategy {

  /// The native terminal backend used for output.
  ///
  /// This renderer assumes ownership of the terminal for the duration
  /// of its lifetime.
  late final DascadeNativeTerminal _terminal;

  /// Creates a new native renderer and enters terminal rendering mode.
  DascadeNativeRenderer(this._terminal) {
    _terminal.enter();
  }

  /// The current terminal width in cells.
  @override
  int get terminalWidth => _terminal.width;

  /// The current terminal height in cells.
  @override
  int get terminalHeight => _terminal.height;

  /// Clears the terminal screen.
  @override
  void clearScreen() => _terminal.clearScreen();

  /// Emits a single cell to the native terminal.
  ///
  /// This method moves the cursor, applies ANSI style state, and writes
  /// the glyph for the given cell.
  @override
  void emitCell(final int x, final int y, final int cell) {
    _terminal.moveCursor(y, x);
    _terminal.applyCellStyle(
      fg: DascadeCell.foreground(cell),
      bg: DascadeCell.background(cell),
      bold: DascadeCell.isBold(cell),
      underline: DascadeCell.isUnderline(cell),
      inverse: DascadeCell.isInverse(cell),
    );
    final int glyph = DascadeCell.glyph(cell);
    _terminal.write(glyph == 0 ? ' ' : String.fromCharCode(glyph));
  }

  /// Emits an entire row to the native terminal.
  ///
  /// This implementation performs a single cursor move, then emits
  /// glyphs left-to-right while minimizing ANSI state changes.
  ///
  /// Rows are written using write([entire_line]) to reduce syscall overhead.
  @override
  void emitRow(final int y, final List<int> cells) {
    _terminal.moveCursor(y, 0);
    int lastFg = -1;
    int lastBg = -1;
    bool lastBold = false;
    bool lastUnderline = false;
    bool lastInverse = false;
    final StringBuffer line = StringBuffer();
    for(int x = 0; x < cells.length; x++) {
      final int cell = cells[x];
      final int fg = DascadeCell.foreground(cell);
      final int bg = DascadeCell.background(cell);
      final bool bold = DascadeCell.isBold(cell);
      final bool underline = DascadeCell.isUnderline(cell);
      final bool inverse = DascadeCell.isInverse(cell);
      if(fg != lastFg ||
          bg != lastBg ||
          bold != lastBold ||
          underline != lastUnderline ||
          inverse != lastInverse) {
        if(line.isNotEmpty) {
          _terminal.write(line.toString());
          line.clear();
        }
        _terminal.applyCellStyle(
          fg: fg,
          bg: bg,
          bold: bold,
          underline: underline,
          inverse: inverse,
        );
        lastFg = fg;
        lastBg = bg;
        lastBold = bold;
        lastUnderline = underline;
        lastInverse = inverse;
      }
      final int glyph = DascadeCell.glyph(cell);
      line.write(glyph == 0 ? ' ' : String.fromCharCode(glyph));
    }
    if(line.isNotEmpty) {
      _terminal.write(line.toString());
    }
  }

  /// Flushes any buffered terminal output.
  @override
  void flush() => _terminal.flush();

  /// Disposes of renderer resources.
  ///
  /// Subclasses may override this to release platform specific resources.
  @override
  void dispose() {}

}
