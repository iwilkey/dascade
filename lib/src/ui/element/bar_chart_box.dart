/// TODO: Dart docs.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';

final class DUBarChartBoxElement implements DUElement {
  @override
  final int id;
  @override
  final DURect rect;

  final String title;
  final bool border;

  DUBarChartBoxElement({
    required this.id,
    required this.rect,
    required this.title,
    required this.border,
  });

  @override
  void render(DUIPainter p, DUIRuntime r) {
    if (border) p.drawFrame(rect, title: title);

    final DURect c = border ? rect.inset(1) : rect;
    if (c.width < 6 || c.height < 4) return;

    final List<int> values = const [5, 3, 2, 5, 8, 3];
    final int n = values.length;
    final int maxV = values.reduce(math.max);

    final int plotH = c.height - 2;
    final int baseY = c.upperLeft.y + plotH;

    for (int i = 0; i < n; i++) {
      final int barX = c.upperLeft.x + (i * (c.width ~/ n));
      final int w = math.max(1, (c.width ~/ n) - 1);
      final int h = (plotH * values[i] / maxV).round();

      for (int x = 0; x < w; x++) {
        for (int y = 0; y < h; y++) {
          p.drawGlyph(barX + x, baseY - y, 0x2588, fg: 46);
        }
      }

      p.drawText(
        DURect(
          upperLeft: DUPoint(x: barX, y: baseY + 1),
          lowerRight: DUPoint(x: barX + w, y: baseY + 2),
        ),
        ['${values[i]}'],
        fg: 15,
      );
    }
  }
  
  @override
  void interact(DUIRuntime r) {
    // TODO: implement interact
  }
}
