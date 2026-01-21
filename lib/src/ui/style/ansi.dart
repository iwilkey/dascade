/// Minimal, shared palette indices.
library;

/// ANSI/xterm-256 palette indices (first 16 are “classic ANSI”).
final class DUIAnsi {
  /// Static utility.
  DUIAnsi._();

  static const int black = 0;
  static const int red = 1;
  static const int green = 2;
  static const int yellow = 3;
  static const int blue = 4;
  static const int magenta = 5;
  static const int cyan = 6;
  static const int white = 7;

  static const int brightBlack = 8;
  static const int brightRed = 9;
  static const int brightGreen = 10;
  static const int brightYellow = 11;
  static const int brightBlue = 12;
  static const int brightMagenta = 13;
  static const int brightCyan = 14;
  static const int brightWhite = 15;

  /// Nice-looking accent color in xterm-256 (often teal/cyan).
  static const int accent = 51;
  
}
