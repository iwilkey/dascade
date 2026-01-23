/// Static utilities for immediate-mode rendering of UI elements in Dascade.
library;

import 'package:dascade/dascade.dart';

/// Static utilities for immediate-mode rendering of UI elements in Dascade.
extension DURendererUtils on DURenderer {

  /// Static UI renderer utility to render an arbitrary string.
  static void drawString(
    final DascadeFramework d,
    final int x,
    final int y,
    final String text, {
    required int fg,
    final int bg = 0,
  }) {
    if(y < 0 || y >= d.height) return;
    final int maxLen = d.width - x;
    if(maxLen <= 0) return;
    final String clipped = text.length > maxLen ? text.substring(0, maxLen) : text;
    for(int i = 0; i < clipped.length; i++) {
      d.draw(
        x + i,
        y,
        DascadeCell.encode(
          glyph: clipped.codeUnitAt(i),
          fg: fg,
          bg: bg,
        ),
      );
    }
  }

  /// Static UI renderer utility to render an arbitrary centered message.
  static void drawCenteredMessage(
    final DascadeFramework d,
    final String message,
  ) {
    final List<String> lines = message.split('\n');
    final int startY = (d.height ~/ 2) - (lines.length ~/ 2);
    for(int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final int startX = (d.width ~/ 2) - (line.length ~/ 2);
      drawString(
        d,
        startX.clamp(0, d.width),
        startY + i,
        line,
        fg: 250,
      );
    }
  }

  /// Static UI renderer utility to render an arbitrary error screen with given stack trace.
  static void drawErrorScreen(
    final DascadeFramework d,
    final Object error,
    final StackTrace stack,
  ) {
    int y = 0;
    drawString(
      d,
      0,
      y++,
      'DASCADE APPLICATION FATAL ERROR',
      fg: 196,
    );
    y++;
    for(final String line in error.toString().split('\n')) {
      if(y >= d.height) return;
      drawString(d, 0, y++, line, fg: 231);
    }
    y++;
    for(final String line in stack.toString().split('\n')) {
      if(y >= d.height) return;
      drawString(d, 0, y++, line, fg: 244);
    }
  }

}
