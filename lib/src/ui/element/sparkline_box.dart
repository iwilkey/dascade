/// TODO: Dart docs.
library;

import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';

final class DUSparklineBoxElement implements DUElement {
  @override
  final int id;
  @override
  final DURect rect;

  final String title;
  final String seriesAName;
  final String seriesBName;
  final bool border;

  DUSparklineBoxElement({
    required this.id,
    required this.rect,
    required this.title,
    required this.seriesAName,
    required this.seriesBName,
    required this.border,
  });

  @override
  void render(DUIPainter p, DUIRuntime r) {
    if (border) p.drawFrame(rect, title: title);

    final DURect c = border ? rect.inset(1) : rect;
    if (c.width <= 2 || c.height <= 2) return;

    p.drawText(c, [seriesAName]);
    p.drawHLine(c, y: c.upperLeft.y + 1);

    final int midY = c.upperLeft.y + (c.height ~/ 2);

    p.drawText(
      DURect(
        upperLeft: DUPoint(x: c.upperLeft.x, y: midY),
        lowerRight: DUPoint(x: c.lowerRight.x, y: midY + 1),
      ),
      [seriesBName],
    );
    p.drawHLine(c, y: midY + 1);

    final int topPlotY0 = c.upperLeft.y + 2;
    final int topPlotY1 = midY;
    final int botPlotY0 = midY + 2;
    final int botPlotY1 = c.lowerRight.y;

    p.drawSparkline(
      DURect(
        upperLeft: DUPoint(x: c.upperLeft.x, y: topPlotY0),
        lowerRight: DUPoint(x: c.lowerRight.x, y: topPlotY1),
      ),
      fg: 45,
      seed: 1,
    );

    p.drawSparkline(
      DURect(
        upperLeft: DUPoint(x: c.upperLeft.x, y: botPlotY0),
        lowerRight: DUPoint(x: c.lowerRight.x, y: botPlotY1),
      ),
      fg: 196,
      seed: 2,
    );
  }
  
  @override
  void interact(DUIRuntime r) {
    // TODO: implement interact
  }
}
