/// Web renderer implementation for Dascade.
library;

import 'package:dascade/src/output/rendering_strategy.dart';
import 'package:dascade/src/output/web/terminal.dart';

/// Immediate mode renderer for the web platform.
///
/// This renderer drives a [DascadeTerminalWeb] backend and uses the
/// shared rendering strategy to perform buffered and differential
/// rendering. All platform independent logic lives in the base class.
final class DascadeWebRenderer extends DascadeRenderingStrategy {

  final DascadeTerminalWeb _terminal;

  /// Creates a new web renderer.
  ///
  /// The renderer takes ownership of the terminal and enters rendering
  /// mode immediately.
  DascadeWebRenderer(this._terminal) {
    _terminal.enter();
    _terminal.setRenderer(this);
    syncBufferDimensions();
  }

  /// The current terminal width in cells.
  @override
  int get terminalWidth => _terminal.width;

  /// The current terminal height in cells.
  @override
  int get terminalHeight => _terminal.height;

  /// Clears the rendering surface.
  @override
  void clearScreen() => _terminal.clearScreen();

  /// Emits a single cell to the web terminal.
  ///
  /// Cell coordinates are translated directly into canvas draw calls.
  @override
  void emitCell(final int x, final int y, final int cell) {
    _terminal.renderCell(x, y, cell);
  }

  /// Flush is a no op for the web backend.
  @override
  void flush() {}

}
