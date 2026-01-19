/// TODO: Dart docs.
library;

import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';

final class DUDotLineChartBoxElement implements DUElement {
  @override
  final int id;
  @override
  final DURect rect;

  final String title;
  final bool border;

  DUDotLineChartBoxElement({
    required this.id,
    required this.rect,
    required this.title,
    required this.border,
  });

  @override
  void render(DUIPainter p, DUIRuntime r) {
    if (border) p.drawFrame(rect, title: title);

    final DURect c = border ? rect.inset(1) : rect;
    if (c.width < 10 || c.height < 6) return;

    p.drawAxes(c);

    final DURect plot = DURect(
      upperLeft: DUPoint(x: c.upperLeft.x + 4, y: c.upperLeft.y + 1),
      lowerRight: DUPoint(x: c.lowerRight.x - 1, y: c.lowerRight.y - 2),
    );

    p.drawSineDots(plot, fg: 196, glyph: 0x2022);
  }
  
  @override
  void interact(DUIRuntime r) {
    // TODO: implement interact
  }
}