/// Immediate-mode painter for rendering UI elements in Dascade.
library;

import 'dart:math' as math;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';

/// Immediate-mode renderer for UI elements in Dascade.
///
/// This class handles drawing glyphs, borders, and text within the terminal,
/// using an internal clip stack to restrict drawing operations to defined regions.
/// Elements receive a [DUIRenderer] each frame to emit their visuals.
final class DUIRenderer {

  /// Reference to running framework instance.
  final DascadeFramework d;

  /// Stack of clip rectangles. All drawing is restricted to the current clip.
  final List<DURect> _clipStack = [];

  DUIRenderer(this.d);

  /// Returns the current active clip rect.
  DURect get _clip => _clipStack.isEmpty
    ? DURect(
        upperLeft: DUPoint(x: 0, y: 0),
        lowerRight: DUPoint(x: d.width, y: d.height),
      )
    : _clipStack.last;

  /// Pushes a new clip rectangle, intersected with the previous.
  void pushClip(final DURect r) {
    _clipStack.add(_clip.intersects(r));
  }

  /// Pops the most recent clip rectangle.
  void popClip() {
    if(_clipStack.isNotEmpty) _clipStack.removeLast();
  }

  /// Returns true if the given position is inside the current clip.
  bool _inClip(final int x, final int y) => _clip.contains(x, y);

  /// Draws a single glyph at the given position, respecting clip.
  ///
  /// If the glyph is outside the terminal bounds or the active clip,
  /// it will not be rendered.
  void renderGlyph(
    final int x,
    final int y,
    final int glyph, {
    final int fg = 15,
    final int bg = 0,
    final bool bold = false,
  }) {
    if(x < 0 || y < 0 || x >= d.width || y >= d.height) return;
    if(!_inClip(x, y)) return;
    d.draw(
      x,
      y,
      DascadeCell.encode(
        glyph: glyph,
        fg: fg.clamp(0, 255),
        bg: bg.clamp(0, 255),
        bold: bold,
      ),
    );
  }

  /// Draws a rectangular ASCII frame using box-drawing characters.
  ///
  /// If [title] is provided, it is rendered into the top border.
  void renderFrame(
    final DURect rect, {
    final String? title,
    final int frameFg = 15,
    final int frameBg = 0,
  }) {
    pushClip(rect);
    final int w = rect.width;
    final int h = rect.height;
    if(w < 2 || h < 2) {
      popClip();
      return;
    }
    final int x0 = rect.left;
    final int y0 = rect.top;
    final int x1 = rect.right - 1;
    final int y1 = rect.bottom - 1;
    for(int x = x0 + 1; x < x1; x++) {
      renderGlyph(x, y0, 0x2500, fg: frameFg, bg: frameBg); // top
      renderGlyph(x, y1, 0x2500, fg: frameFg, bg: frameBg); // bottom
    }
    for(int y = y0 + 1; y < y1; y++) {
      renderGlyph(x0, y, 0x2502, fg: frameFg, bg: frameBg); // left
      renderGlyph(x1, y, 0x2502, fg: frameFg, bg: frameBg); // right
    }
    renderGlyph(x0, y0, 0x250C, fg: frameFg, bg: frameBg); // top-left
    renderGlyph(x1, y0, 0x2510, fg: frameFg, bg: frameBg); // top-right
    renderGlyph(x0, y1, 0x2514, fg: frameFg, bg: frameBg); // bottom-left
    renderGlyph(x1, y1, 0x2518, fg: frameFg, bg: frameBg); // bottom-right
    if(title != null && title.isNotEmpty && w > 4) {
      final String capped = title.length <= w - 4
        ? title
        : title.substring(0, w - 4);
      for(int i = 0; i < capped.length; i++) {
        renderGlyph(x0 + 2 + i, y0, capped.codeUnitAt(i), fg: frameFg, bg: frameBg);
      }
    }
    popClip();
  }

  /// Draws a list of text lines inside a bounded rectangle.
  ///
  /// Lines are clipped vertically and horizontally. Colors are consistent
  /// across all lines.
  void renderText(
    final DURect rect,
    final List<String> lines, {
    final int fg = 15,
    final int bg = 0,
  }) {
    pushClip(rect);
    final int w = rect.width;
    final int h = rect.height;
    if(w <= 0 || h <= 0) {
      popClip();
      return;
    }
    int y = rect.top;
    for(final String line in lines) {
      if(y >= rect.bottom) break;
      final int len = math.min(line.length, w);
      for(int i = 0; i < len; i++) {
        renderGlyph(rect.left + i, y, line.codeUnitAt(i), fg: fg, bg: bg);
      }
      y += 1;
    }
    popClip();
  }

}
