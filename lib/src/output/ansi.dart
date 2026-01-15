/// ANSI style and color state management for Dascade.
library;

import 'package:dart_console/dart_console.dart';

/// Responsible for emitting correct ANSI escape sequences for colors
/// and text styles while minimizing redundant output.
/// 
/// Essentially minimizes the ANSI state changes that can occur during rendering.
final class DascadeAnsiState {

  /// Table for well-known ANSI 16.
  static const List<ConsoleColor> _ansi16 = [
    ConsoleColor.black,
    ConsoleColor.red,
    ConsoleColor.green,
    ConsoleColor.yellow,
    ConsoleColor.blue,
    ConsoleColor.magenta,
    ConsoleColor.cyan,
    ConsoleColor.white,
    ConsoleColor.brightBlack,
    ConsoleColor.brightRed,
    ConsoleColor.brightGreen,
    ConsoleColor.brightYellow,
    ConsoleColor.brightBlue,
    ConsoleColor.brightMagenta,
    ConsoleColor.brightCyan,
    ConsoleColor.brightWhite,
  ];

  /// Last forground ANSI value.
  int _fg = -1;

  /// Last background ANSI value.
  int _bg = -1;

  /// Last bold state.
  bool _bold = false;

  /// Last underline state.
  bool _underline = false;

  /// Last inverse state.
  bool _inverse = false;

  /// Applies a new style state, emitting ANSI sequences as needed.
  void apply({
    required void Function(String) write,
    required void Function(ConsoleColor) setFg,
    required void Function(ConsoleColor) setBg,
    required int fg,
    required int bg,
    required bool bold,
    required bool underline,
    required bool inverse,
  }) {
    /// If the style of this cell is the same as before, we can ignore this function call.
    if(fg == _fg &&
       bg == _bg &&
       bold == _bold &&
       underline == _underline &&
       inverse == _inverse) {
      return;
    }
    write('\x1b[0m');
    _applyColor(fg, isForeground: true, write: write, set: setFg);
    _applyColor(bg, isForeground: false, write: write, set: setBg);
    if(bold) write('\x1b[1m');
    if(underline) write('\x1b[4m');
    if(inverse) write('\x1b[7m');
    _fg = fg;
    _bg = bg;
    _bold = bold;
    _underline = underline;
    _inverse = inverse;
  }

  /// Completely resets the ANSI state.
  void reset(void Function(String) write) {
    write('\x1b[0m');
    _fg = -1;
    _bg = -1;
    _bold = false;
    _underline = false;
    _inverse = false;
  }

  /// Applies a given color to ANSI state.
  void _applyColor(
    final int color, {
    required bool isForeground,
    required void Function(String) write,
    required void Function(ConsoleColor) set,
  }) {
    if(color < 16) {
      set(_ansi16[color]);
    } else {
      write(isForeground
        ? '\x1b[38;5;${color}m'
        : '\x1b[48;5;${color}m');
    }
  }

}
