/// Low-level drawing interface used by all UI elements.
library;

import 'dart:math' as math;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';

/// Low-level drawing interface used by all UI elements.
///
/// Provides:
/// - hierarchical clipping
/// - coordinate translation
/// - safe terminal bounds checking
/// - primitive drawing helpers
///
/// Elements are expected to treat this as a *stateless painter*:
/// all state should live in the element or in [DUIStateStore].
final class DUIPainter {
  
  /// Underlying Dascade framework.
  final DascadeFramework d;

  /// Active clipping regions (stack-based).
  final List<DURect> _clipStack = [];

  /// Active coordinate offsets (stack-based).
  final List<DUPoint> _offsetStack = [];

  DUIPainter(this.d);

  /// Current effective clipping rectangle.
  ///
  /// Defaults to the full terminal bounds.
  DURect get _clip => _clipStack.isEmpty
      ? DURect(
          upperLeft: DUPoint(x: 0, y: 0),
          lowerRight: DUPoint(x: d.width, y: d.height),
        )
      : _clipStack.last;

  /// Current accumulated drawing offset.
  ///
  /// Defaults to (0, 0).
  DUPoint get _offset => _offsetStack.isEmpty
      ? DUPoint(x: 0, y: 0)
      : _offsetStack.last;

  /// Pushes a new clipping rectangle.
  ///
  /// The effective clip is the intersection of the current clip
  /// and the provided rectangle.
  void pushClip(DURect rect) {
    _clipStack.add(_clip.intersect(rect));
  }

  /// Pops the most recent clipping rectangle.
  void popClip() {
    if (_clipStack.isNotEmpty) _clipStack.removeLast();
  }

  /// Pushes a translation offset applied to all subsequent draws.
  void pushOffset(int dx, int dy) {
    final DUPoint o = _offset;
    _offsetStack.add(DUPoint(x: o.x + dx, y: o.y + dy));
  }

  /// Pops the most recent translation offset.
  void popOffset() {
    if (_offsetStack.isNotEmpty) _offsetStack.removeLast();
  }

  bool _inClip(int x, int y) => _clip.contains(x, y);

  /// Draws a single glyph at terminal coordinates.
  ///
  /// Automatically applies:
  /// - offset transforms
  /// - clipping
  /// - terminal bounds checks
  void drawGlyph(
    int x,
    int y,
    int glyph, {
    int fg = 15,
    int bg = 0,
    bool bold = false,
  }) {
    final DUPoint o = _offset;
    final int tx = x + o.x;
    final int ty = y + o.y;

    if (tx < 0 || ty < 0 || tx >= d.width || ty >= d.height) return;
    if (!_inClip(tx, ty)) return;

    d.draw(
      tx,
      ty,
      DascadeCell.encode(
        glyph: glyph,
        fg: fg.clamp(0, 255),
        bg: bg.clamp(0, 255),
        bold: bold,
      ),
    );
  }

  /// Draws a rectangular frame with optional title.
  ///
  /// Uses box-drawing characters and respects clipping.
  void drawFrame(
    DURect rect, {
    String? title,
    int frameFg = 15,
    int titleFg = 51,
  }) {
    pushClip(rect);

    final int w = rect.width;
    final int h = rect.height;
    if (w < 2 || h < 2) {
      popClip();
      return;
    }

    final int x0 = rect.left;
    final int y0 = rect.top;
    final int x1 = rect.right - 1;
    final int y1 = rect.bottom - 1;

    for (int x = x0; x <= x1; x++) {
      drawGlyph(x, y0, 0x2500, fg: frameFg);
      drawGlyph(x, y1, 0x2500, fg: frameFg);
    }
    for (int y = y0; y <= y1; y++) {
      drawGlyph(x0, y, 0x2502, fg: frameFg);
      drawGlyph(x1, y, 0x2502, fg: frameFg);
    }

    drawGlyph(x0, y0, 0x250C, fg: frameFg);
    drawGlyph(x1, y0, 0x2510, fg: frameFg);
    drawGlyph(x0, y1, 0x2514, fg: frameFg);
    drawGlyph(x1, y1, 0x2518, fg: frameFg);

    if (title != null && title.isNotEmpty) {
      final int max = w - 4;
      if (max > 0) {
        final int len = math.min(title.length, max);
        for (int i = 0; i < len; i++) {
          drawGlyph(
            x0 + 2 + i,
            y0,
            title.codeUnitAt(i),
            fg: titleFg,
            bold: true,
          );
        }
      }
    }

    popClip();
  }

  /// Draws multiple lines of text clipped to [rect].
  void drawText(DURect rect, List<String> lines, {int fg = 15}) {
    pushClip(rect);

    final int w = rect.width;
    final int h = rect.height;
    if (w <= 0 || h <= 0) {
      popClip();
      return;
    }

    final int x0 = rect.left;
    int y = rect.top;

    for (final line in lines) {
      if (y >= rect.bottom) break;
      final int len = math.min(line.length, w);
      for (int i = 0; i < len; i++) {
        drawGlyph(x0 + i, y, line.codeUnitAt(i), fg: fg);
      }
      y += 1;
    }

    popClip();
  }

  /// Draws a horizontal line across [rect] at terminal row [y].
  void drawHLine(DURect rect, {required int y, int fg = 8}) {
    if (y < rect.top || y >= rect.bottom) return;
    pushClip(rect);
    for (int x = rect.left; x < rect.right; x++) {
      drawGlyph(x, y, 0x2500, fg: fg);
    }
    popClip();
  }

  /// Draws simple X/Y axes with fixed labels.
  ///
  /// Intended as a lightweight helper for demo and diagnostics.
  void drawAxes(DURect c) {
    if (c.width < 8 || c.height < 5) return;

    pushClip(c);

    final int axisX = c.upperLeft.x + 3;
    for (int y = c.upperLeft.y + 1; y < c.lowerRight.y - 1; y++) {
      drawGlyph(axisX, y, 0x2502, fg: 8);
    }

    final int axisY = c.lowerRight.y - 2;
    for (int x = axisX; x < c.lowerRight.x - 1; x++) {
      drawGlyph(x, axisY, 0x2500, fg: 8);
    }

    final List<String> labels = const ['1.70', '1.00', '0.30', '-0.40'];
    for (int i = 0; i < labels.length; i++) {
      final int y = c.upperLeft.y +
          1 +
          (i * math.max(1, (c.height - 3) ~/ (labels.length - 1)));
      final String s = labels[i];
      for (int j = 0; j < s.length; j++) {
        drawGlyph(c.upperLeft.x + j, y, s.codeUnitAt(j), fg: 15);
      }
    }

    popClip();
  }

  /// Draws a filled sparkline using block glyphs.
  void drawSparkline(DURect plot, {required int fg, required int seed}) {
    if (plot.width <= 0 || plot.height <= 0) return;

    pushClip(plot);

    final int w = plot.width;
    final int h = plot.height;

    for (int i = 0; i < w; i++) {
      final double t = (i / math.max(1, w - 1));
      final double v = 0.5 +
          0.4 * math.sin((t * 8.0 + seed) * 2.0) +
          0.1 * math.sin((t * 23.0 + seed) * 2.0);

      final double clamped = v.clamp(0.0, 1.0);
      final int bar = math.max(0, (clamped * (h - 1)).round());

      for (int y = 0; y < bar; y++) {
        final int gy = plot.lowerRight.y - 1 - y;
        drawGlyph(plot.upperLeft.x + i, gy, 0x2588, fg: fg);
      }
    }

    popClip();
  }

  /// Draws a sine wave using a single glyph per column.
  void drawSineDots(DURect plot, {required int fg, required int glyph}) {
    if (plot.width <= 0 || plot.height <= 0) return;

    pushClip(plot);

    final int w = plot.width;
    final int h = plot.height;

    for (int i = 0; i < w; i++) {
      final double t = i / math.max(1, w - 1);
      final double s = math.sin(t * math.pi * 2.0);
      final double v = (s * 0.45 + 0.5).clamp(0.0, 1.0);

      final int y =
          plot.upperLeft.y + ((1.0 - v) * (h - 1)).round();
      drawGlyph(plot.upperLeft.x + i, y, glyph, fg: fg);
    }

    popClip();
  }
}
