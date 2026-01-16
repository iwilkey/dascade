/// Web terminal emulator backend for Dascade.
///
/// This terminal implementation renders the Dascade cell grid to a
/// full screen HTML canvas. It emulates terminal behavior in software
/// and serves as the low level output backend for web based builds.
///
/// Unlike native terminals, browsers do not provide a fixed-width,
/// cell-aligned text grid. This implementation explicitly measures
/// font metrics at runtime and manually centers glyphs inside logical
/// cells to achieve deterministic, terminal-like rendering.
///
/// At this time, Dascade Web terminal rendering is simulated and
/// experimental. While visual parity with native terminals is a core
/// goal, minor discrepancies may still exist depending on browser,
/// font availability, device pixel ratio, and unwanted visual artifacts.
/// 
/// Note (iwilkey): One of the best ways to contribute to this project is to work on this module to ensure
/// terminal rendering emulation is as close as possible to native platforms.
library;

// ignore: deprecated_member_use
import 'dart:html';

import 'package:dascade/dascade.dart';
import 'package:dascade/src/output/terminal_interface.dart';
import 'package:dascade/src/output/web/ansi.dart';
import 'package:dascade/src/output/web/metrics.dart';
import 'package:dascade/src/output/web/renderer.dart';

/// Web-based terminal implementation for Dascade.
///
/// This class translates Dascade’s cell-based rendering model into
/// explicit HTML canvas draw calls. It does not perform buffering,
/// diffing, or layout logic itself; instead, it assumes that all
/// rendering decisions have already been made upstream by the
/// rendering system.
///
/// The primary responsibility of this class is to:
/// - Maintain a consistent cell grid
/// - Render ANSI-colored background rectangles
/// - Center glyphs precisely within each cell
/// - Match native terminal output as closely as possible
final class DascadeTerminalWeb implements DascadeTerminalInterface {

  /// Reference to the terminal object.
  late DascadeWebRenderer _renderer;

  /// The backing canvas element.
  late CanvasElement _canvas;

  /// 2D rendering context used for all drawing operations.
  late CanvasRenderingContext2D _ctx;

  /// Current terminal width in cells.
  int _width = 0;

  /// Current terminal height in cells.
  int _height = 0;

  // ─────────────────────────────────────────────
  // Font / glyph metrics
  // ─────────────────────────────────────────────

  /// Horizontal offset applied when rendering a glyph to center it
  /// within its logical cell.
  double _glyphOffsetX = 0;

  /// Vertical offset applied when rendering a glyph to center it
  /// within its logical cell while respecting font ascent/descent.
  double _glyphOffsetY = 0;

  /// Cached font string used for rendering.
  ///
  /// This is cached to ensure that resizing the canvas does not
  /// introduce subtle font drift or metric recalculation errors.
  late String _font;

  /// Gives the web terminal interface a reference to the web renderer.
  void setRenderer(final DascadeWebRenderer renderer) {
    _renderer = renderer;
    /// Because web-based runtimes of Dascade are backed by modern web browsers (and GPUs, in most cases)
    /// differential rendering of cells is NOT needed, and actually serves to complicate the rendering strategy
    /// and can produce unwanted artifacts.
    _renderer.forceNoDiffing = true;
  }

  /// Enters the web terminal rendering mode.
  ///
  /// This method:
  /// - Creates a full screen canvas
  /// - Clears the document body
  /// - Initializes font and rendering state
  /// - Measures glyph metrics
  /// - Computes initial terminal geometry
  ///
  /// This method must be called exactly once during runtime startup.
  @override
  void enter() {
    _canvas = CanvasElement();
    document.body!
      ..children.clear()
      ..append(_canvas);
    _ctx = _canvas.context2D;
    // Use explicit baseline handling; we do our own centering.
    _ctx
      ..textAlign = 'left'
      ..textBaseline = 'alphabetic';
    // Carefully curated monospace font stack.
    _font =
      '${DascadeWebMetrics.cellHeight - 2}px '
      '"Fira Code", '
      '"JetBrains Mono", '
      '"Source Code Pro", '
      '"IBM Plex Mono", '
      'Menlo, Consolas, '
      '"DejaVu Sans Mono", '
      '"Liberation Mono", '
      'monospace';
    _ctx.font = _font;
    _computeGlyphMetrics();
    _resize();
    window.onResize.listen((_) => _resize());
  }

  // ─────────────────────────────────────────────
  // Runtime font measurement (critical for parity)
  // ─────────────────────────────────────────────

  /// Computes runtime glyph metrics used to center characters
  /// inside logical terminal cells.
  ///
  /// Browsers render text using font metrics (ascent, descent,
  /// bounding boxes) rather than a strict grid. To emulate a
  /// terminal, we must:
  ///
  /// - Measure a representative glyph
  /// - Compute its true pixel dimensions
  /// - Derive offsets that place it visually centered in a cell
  ///
  /// This method is the key to achieving native-terminal parity
  /// in a canvas-based renderer.
  void _computeGlyphMetrics() {
    // Measure a representative glyph.
    final TextMetrics m = _ctx.measureText('M');
    final double glyphWidth = m.width!.toDouble();
    final double ascent = m.actualBoundingBoxAscent!.toDouble();
    final double descent = m.actualBoundingBoxDescent!.toDouble();
    final double glyphHeight = ascent + descent;
    // Horizontal centering within the cell.
    _glyphOffsetX = (DascadeWebMetrics.cellWidth - glyphWidth) / 2;
    // Vertical centering, corrected for baseline.
    _glyphOffsetY = (DascadeWebMetrics.cellHeight / 2) + (ascent - glyphHeight / 2);
    // Pixel snapping avoids subpixel blur.
    _glyphOffsetX = _glyphOffsetX.roundToDouble();
    _glyphOffsetY = _glyphOffsetY.roundToDouble();
  }

  // ─────────────────────────────────────────────
  // Resize handling
  // ─────────────────────────────────────────────

  /// Handles browser resize events.
  ///
  /// This method:
  /// - Resizes the backing canvas using device pixel ratio
  /// - Resets the transform to maintain crisp rendering
  /// - Recomputes terminal dimensions in cells
  /// - Clears the screen
  void _resize() {
    final double dpr = window.devicePixelRatio.toDouble();
    final int cssWidth = window.innerWidth!;
    final int cssHeight = window.innerHeight!;
    _canvas
      ..width = (cssWidth * dpr).round()
      ..height = (cssHeight * dpr).round()
      ..style.width = '${cssWidth}px'
      ..style.height = '${cssHeight}px';
    _ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    _ctx.font = _font;
    _width = (cssWidth / DascadeWebMetrics.cellWidth).floor();
    _height = (cssHeight / DascadeWebMetrics.cellHeight).floor();
  }

  // ─────────────────────────────────────────────
  // TerminalInterface implementation
  // ─────────────────────────────────────────────

  /// Exits terminal mode.
  ///
  /// This is a no-op on the web backend.
  @override
  void exit() {}

  /// Performs final cleanup.
  ///
  /// No cleanup is currently required for the web backend.
  @override
  void cleanup() {}

  /// Clears the entire terminal surface.
  @override
  void clearScreen() {
    _ctx
      ..fillStyle = 'black'
      ..fillRect(0, 0, _canvas.width!, _canvas.height!);
  }

  @override
  void moveCursor(int x, int y) {}

  @override
  void hideCursor() {}

  @override
  void showCursor() {}

  /// Raw text output is not supported on the web backend.
  ///
  /// All output must be performed via cell rendering.
  @override
  void write(String text) {}

  /// Raw text output is not supported on the web backend.
  @override
  void writeln(String text) {}

  @override
  void flush() {}

  /// Audible alerts are not supported on the web backend.
  @override
  void beep() {}

  /// Applies cell styling.
  ///
  /// Styling is handled during rendering and does not require
  /// persistent state on the web backend.
  @override
  void applyCellStyle({
    required int fg,
    required int bg,
    required bool bold,
    required bool underline,
    required bool inverse,
  }) {}

  // ─────────────────────────────────────────────
  // Cell rendering
  // ─────────────────────────────────────────────

  /// Renders a single cell at the given grid position.
  ///
  /// This method:
  /// - Resolves ANSI foreground/background colors
  /// - Draws the background rectangle
  /// - Renders the glyph centered within the cell
  void renderCell(final int x, final int y, final int cell) {
    final int px = x * DascadeWebMetrics.cellWidth;
    final int py = y * DascadeWebMetrics.cellHeight;
    final ({String bg, String fg}) colors = DascadeWebAnsi.resolveColors(cell);
    // Background
    _ctx
      ..fillStyle = colors.bg
      ..fillRect(
        px,
        py,
        DascadeWebMetrics.cellWidth,
        DascadeWebMetrics.cellHeight,
      );
    final int glyph = DascadeCell.glyph(cell);
    if(glyph == 0) return;
    // Foreground glyph
    _ctx
      ..fillStyle = colors.fg
      ..fillText(
        String.fromCharCode(glyph),
        px + _glyphOffsetX,
        py + _glyphOffsetY,
      );
  }

  // ─────────────────────────────────────────────
  // Geometry
  // ─────────────────────────────────────────────

  /// Terminal width in cells.
  @override
  int get width => _width;

  /// Terminal height in cells.
  @override
  int get height => _height;

  /// Current terminal size in cells.
  @override
  ({int width, int height}) get size => (width: _width, height: _height);

  @override
  void createScreenBuffer() {}

  @override
  void destoryScreenBuffer() {}

  @override
  void enableMouse() {}

  @override
  void disableMouse() {}

  @override
  void enableRawMode() {}

  @override
  void disableRawMode() {}

  @override
  void disableInput() {}

}
