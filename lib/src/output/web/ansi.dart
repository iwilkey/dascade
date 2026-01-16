/// ANSI color emulation for web backends.
///
/// This module converts Dascade cell color attributes into CSS color
/// values. It mirrors the xterm 256 color palette and ensures visual
/// parity between native terminal output and web canvas rendering.
library;

import 'package:dascade/src/output/cell.dart';

/// Web ANSI color resolver.
///
/// This class translates packed Dascade cell color information into
/// concrete foreground and background colors suitable for web based
/// rendering targets.
final class DascadeWebAnsi {

  /// Resolves foreground and background colors for a cell.
  ///
  /// This method applies inverse and bold semantics and returns CSS
  /// color values that match native terminal output.
  static ({String fg, String bg}) resolveColors(int cell) {
    int fg = DascadeCell.foreground(cell);
    int bg = DascadeCell.background(cell);
    final bool inverse = DascadeCell.isInverse(cell);
    final bool bold = DascadeCell.isBold(cell);
    if(inverse) {
      final tmp = fg;
      fg = bg;
      bg = tmp;
    }
    return (
      fg: _ansiToCss(fg, bold: bold, isForeground: true),
      bg: _ansiToCss(bg, bold: false, isForeground: false),
    );
  }

  /// Converts an ANSI color index into a CSS rgb string.
  ///
  /// Supports the full ANSI 256 color space including standard colors,
  /// color cube entries, and grayscale ramp values.
  static String _ansiToCss(
    int ansi, {
    required bool bold,
    required bool isForeground,
  }) {
    // 0 to 15 standard and bright colors
    if(ansi < 16) {
      return _ansi16(ansi, bold: bold && isForeground);
    }
    // 16 to 231 6 by 6 by 6 color cube
    if(ansi >= 16 && ansi <= 231) {
      int c = ansi - 16;
      int r = c ~/ 36;
      int g = (c % 36) ~/ 6;
      int b = c % 6;
      int rr = _cube(r);
      int gg = _cube(g);
      int bb = _cube(b);
      return 'rgb($rr,$gg,$bb)';
    }
    // 232 to 255 grayscale ramp
    int level = 8 + (ansi - 232) * 10;
    return 'rgb($level,$level,$level)';
  }

  /// Converts a color cube component into an RGB channel value.
  static int _cube(int v) {
    return v == 0 ? 0 : 55 + v * 40;
  }

  /// Resolves standard ANSI colors.
  ///
  /// Bold foreground colors are mapped to their bright variants to
  /// match native terminal behavior.
  static String _ansi16(int ansi, {required bool bold}) {
    const List<List<int>> base = [
      [0, 0, 0],       // black
      [128, 0, 0],     // red
      [0, 128, 0],     // green
      [128, 128, 0],   // yellow
      [0, 0, 128],     // blue
      [128, 0, 128],   // magenta
      [0, 128, 128],   // cyan
      [192, 192, 192], // white
      [128, 128, 128], // bright black
      [255, 0, 0],
      [0, 255, 0],
      [255, 255, 0],
      [0, 0, 255],
      [255, 0, 255],
      [0, 255, 255],
      [255, 255, 255],
    ];
    int idx = ansi;
    if(bold && ansi < 8) {
      idx += 8;
    }
    final List<int> c = base[idx];
    return 'rgb(${c[0]},${c[1]},${c[2]})';
  }
}
