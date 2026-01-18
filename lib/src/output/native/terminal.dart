/// Terminal backend abstraction for Dascade.
///
/// [DascadeNativeTerminal] encapsulates all interaction with the native terminal via
/// the `dart_console` package. It provides low-level control over screen
/// output, cursor state, color attributes, and user input.
///
/// This class is intentionally imperative and stateful. Higher-level
/// components (such as [DRenderer]) should treat it as a backend and
/// avoid embedding rendering logic here.
library;

import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:dascade/src/input/native/win_vt.dart';
import 'package:dascade/src/output/native/ansi.dart';
import 'package:dascade/src/output/terminal_interface.dart';

/// Native terminal interface used by Dascade.
///
/// This class owns the underlying [Console] instance and is responsible
/// for configuring terminal modes, performing output, and reading input.
///
/// Only this class should directly depend on `dart_console`.
final class DascadeNativeTerminal implements DascadeTerminalInterface {

  /// Creates a new terminal backend.
  ///
  /// The terminal is not modified until [enter] is called.
  DascadeNativeTerminal();

  /// There should only be one instance of dart console; I don't want the rest of the project tightly coupled to it.
  final Console _console = Console();

  /// Current ANSI state of the native terminal.
  final DascadeAnsiState _ansi = DascadeAnsiState();

  /// Is the terminal currently focused?
  bool _entered = false;

  /// Puts the terminal into a controlled rendering state.
  ///
  /// This typically clears the screen, hides the cursor, and prepares the
  /// terminal for immediate-mode rendering.
  ///
  /// Calling [enter] more than once has no effect.
  @override
  void enter() {
    if(_entered) return;
    _entered = true;
    createScreenBuffer();
    _console.clearScreen();
    _console.hideCursor();
    _ansi.reset(_console.write);
  }

  /// Restores the terminal to its original state.
  ///
  /// This should be called before the application exits to ensure the
  /// terminal is left in a usable state.
  @override
  void exit() {
    if(!_entered) return;
    _entered = false;
    _ansi.reset(_console.write);
    _console.showCursor();
  }

  /// Clears the entire screen and moves the cursor to the origin.
  @override
  void clearScreen() {
    _console.clearScreen();
    _ansi.reset(_console.write);
    moveCursor(0, 0);
  }

  /// Moves the cursor to the given cell coordinates.
  ///
  /// The origin (0, 0) is the top-left corner of the terminal.
  @override
  void moveCursor(final int x, final int y) {
    _console.cursorPosition = Coordinate(x, y);
  }

  /// Hides the cursor.
  @override
  void hideCursor() {
    _console.hideCursor();
  }

  /// Shows the cursor.
  @override
  void showCursor() {
    _console.showCursor();
  }

  /// Writes raw text to the terminal at the current cursor position.
  ///
  /// No newline is appended automatically.
  @override
  void write(final String text) {
    _console.write(text);
  }

  /// Writes a line of text followed by a newline.
  @override
  void writeln(final String text) {
    _console.writeLine(text);
  }

  /// Flushes any buffered output.
  ///
  /// This currently delegates to stdout flushing, but is exposed for
  /// future backends.
  @override
  void flush() {
    stdout.flush();
  }

  /// Writes a BEL command to stdout. Must be flushed to occur.
  /// 
  /// No guarentee this works on every terminal platform, but it certainly does on some.
  @override
  void beep() {
    stdout.write('\x07');
  }

  /// Applies the style and colors for a single cell.
  ///
  /// This method is ANSI-aware and minimizes redundant escape sequences.
  /// The renderer should call this before writing a glyph.
  /// 
  /// NOTE: This method assumes the cursor position is already correct.
  /// The renderer is responsible for cursor movement.
  @override
  void applyCellStyle({
    required int fg,
    required int bg,
    required bool bold,
    required bool underline,
    required bool inverse,
  }) {
    if(!_entered) return; /// No-op if terminal is not entered.
    _ansi.apply(
      write: _console.write,
      setFg: _console.setForegroundColor,
      setBg: _console.setBackgroundColor,
      fg: fg,
      bg: bg,
      bold: bold,
      underline: underline,
      inverse: inverse,
    );
  }

  /// The current terminal width in character cells.
  @override
  int get width => _console.windowWidth;

  /// The current terminal height in character cells.
  @override
  int get height => _console.windowHeight;

  /// Returns the current terminal size.
  @override
  ({int width, int height}) get size => (width: width, height: height);

  /// Enters the alternate screen buffer.
  @override
  void createScreenBuffer() {
    write('\x1b[?1049h');
  }

  /// Exits the alternate screen buffer and restores the main screen.
  @override
  void destoryScreenBuffer() {
    write('\x1b[?1049l');
  }
  
  /// Enables mouse ANSI events.
  @override
  void enableMouse() {
    write('\x1b[?1003h'); // any event tracking.
    write('\x1b[?1006h'); // SGR encoding
  }

  /// Disables mouse ANSI events.
  @override
  void disableMouse() {
    write('\x1b[?1003l');
    write('\x1b[?1006l');
  }

  /// Enables raw input mode.
  @override
  void enableRawMode() {
    _console.rawMode = true;
  }

  /// Disables raw input mode.
  @override
  void disableRawMode() {
    _console.rawMode = false;
  }

  /// Disables mouse ANSI events and raw mode. Should be called at [Dascade] dispose() time, nowhere else.
  @override
  void disableInput() {
    disableMouse();
    disableRawMode();
  }

  /// Restores the terminal to it's original state. Should be called at [Dascade] dispose() time, nowhere else.
  @override
  void cleanup() {
    if(Platform.isWindows) {
      DascadeWindowsVT.restoreConsoleMode();
    }
    destoryScreenBuffer();
    write('\x1b[0m');
    write('\x1b[?25h');
  }

}
