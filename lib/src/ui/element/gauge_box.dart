/// TODO: Dart docs.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';

final class DUGaugeBoxElement implements DUElement {
  @override
  final int id;
  @override
  final DURect rect;

  final String title;
  final double value;
  final bool border;

  DUGaugeBoxElement({
    required this.id,
    required this.rect,
    required this.title,
    required this.value,
    required this.border,
  });

  @override
  void render(DUIPainter p, DUIRuntime r) {
    if (border) p.drawFrame(rect, title: title);

    final DURect c = border ? rect.inset(1) : rect;
    if (c.width < 6 || c.height < 1) return;

    final int barW = math.max(1, c.width - 8);
    final int filled = (barW * value.clamp(0.0, 1.0)).round();

    final int y = c.upperLeft.y;
    final int x = c.upperLeft.x;

    for (int i = 0; i < barW; i++) {
      final int fg = (i < filled) ? 196 : 8;
      p.drawGlyph(x + i, y, 0x2588, fg: fg);
    }

    final String pct = '${(value * 100).round()}%';
    p.drawText(
      DURect(
        upperLeft: DUPoint(x: c.upperLeft.x + barW + 2, y: y),
        lowerRight: DUPoint(x: c.lowerRight.x, y: y + 1),
      ),
      [pct],
    );
  }
  
  @override
  void interact(DUIRuntime r) {
    // TODO: implement interact
  }
}
