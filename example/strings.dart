import 'dart:async';
import 'package:dascade/dascade.dart';

void drawString(
  DascadeFramework d, {
  required int x,
  required int y,
  required String text,
  int fg = 15,
  int bg = 0,
  int underlineFg = 8, // gray by default
}) {
  int cx = x;

  for (final int codeUnit in text.codeUnits) {
    // Main glyph cell
    final int glyphCell = DascadeCell.encode(
      glyph: codeUnit,
      fg: fg,
      bg: bg,
    );

    d.draw(cx, y, glyphCell);

    // Underline cell (one row below)
    final int underlineCell = DascadeCell.encode(
      glyph: '#'.codeUnitAt(0),
      fg: underlineFg,
      bg: bg,
    );

    d.draw(cx, y + 1, underlineCell);

    cx++;
  }
}

Future<void> main() async {
  await Dascade.run((d) async {
    // Optional: disable Sidecar if you don't want print interception
    d.forceNoSidecar = true;

    bool running = true;

    while (running) {
      // Exit on Escape
      if (d.escape) {
        running = false;
      }

      d.beginFrame();

      // Draw some strings
      drawString(
        d,
        x: 2,
        y: 2,
        text: 'Hello, Dascade!',
        fg: 15, // white
        bg: 0,  // black
      );

      drawString(
        d,
        x: 2,
        y: 4,
        text: 'Immediate-mode, cell-based rendering.',
        fg: 14, // yellow
        bg: 0,
      );

      drawString(
        d,
        x: 2,
        y: 6,
        text: 'Press ESC to quit.',
        fg: 12, // red
        bg: 0,
      );

      d.endFrame();

      // Basic frame throttle
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}
