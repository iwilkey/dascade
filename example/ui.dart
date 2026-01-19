/// Showcases Dascade's UI system. THIS IS EXPERIMENTAL IN THIS COMMIT. IT WILL NOT BE DOCUMENTED TILL
/// IT'S SOLIDIFIED.
library;

import 'dart:async';
import 'package:dascade/dascade.dart';

Future<void> main() async {
  await Dascade.run((d) async {
    d.forceNoSidecar = true;
    bool running = true;
    while(running) {
      if(d.escape) running = false;
      d.beginFrame();
      d.ui.row(() {
        d.ui.column(() {
          d.ui.textBox(
            title: 'Text Box',
            lines: const [
              ': PRESS q TO QUIT DEMO',
            ],
            border: true,
            editable: true,
          );
          d.ui.row(() {
            d.ui.listBox(
              title: 'List',
              items: const [
                '[4] output.go',
                '[5] random_out.go',
                '[6] dashboard.go',
                '[7] nsf/termbox~go',
              ],
              border: true,
            );
            d.ui.sparklineBox(
              title: 'Sparkline',
              seriesAName: 'srv 0:',
              seriesBName: 'srv 1:',
              border: true,
            );
          }, children: 2, weights: const [0.55, 0.45], gap: 1);
          d.ui.gaugeBox(
            title: 'Gauge',
            value: 0.31,
            border: true,
          );
          d.ui.dotLineChartBox(
            title: 'dot-mode Line Chart',
            border: true,
          );
        }, children: 4, weights: const [0.12, 0.28, 0.12, 0.48], gap: 1);
        d.ui.column(() {
          d.ui.barChartBox(
            title: 'Bar Chart',
            border: true,
          );
         
          d.ui.brailleLineChartBox(
            title: 'braille-mode Line Chart',
            border: true,
          );
        }, children: 2, weights: const [0.40, 0.60], gap: 1);
      }, children: 2, weights: const [0.66, 0.34], gap: 2, pad: 1);
      d.endFrame();
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}
