/// Platform agnostic terminal backend interface for Dascade.
///
/// This interface defines the exact surface area required by the
/// rendering system and higher level runtime code. All terminal
/// backends, including native and web implementations, must conform
/// to this interface.
library;

/// Defines the terminal backend contract for Dascade.
///
/// Implementations are responsible for low level screen management,
/// output, and terminal mode control. Rendering logic must not be
/// implemented here and should live exclusively in renderer classes.
abstract interface class DascadeTerminalInterface {

  // //////////////////////////////////////////////
  // LIFECYCLE
  // //////////////////////////////////////////////

  /// Enters the terminal rendering mode.
  ///
  /// This is typically where screen buffers are initialized and the
  /// terminal is prepared for immediate mode rendering.
  void enter();

  /// Exits the terminal rendering mode.
  ///
  /// Implementations should restore any terminal state modified
  /// during [enter].
  void exit();

  /// Performs final cleanup before application shutdown.
  ///
  /// This should restore the terminal to a usable state and must be
  /// safe to call multiple times.
  void cleanup();

  // //////////////////////////////////////////////
  // SCREEN AND CURSOR
  // //////////////////////////////////////////////

  /// Clears the entire rendering surface.
  void clearScreen();

  /// Moves the cursor to the given cell coordinates.
  ///
  /// The origin is the top left corner of the screen.
  void moveCursor(int x, int y);

  /// Hides the cursor.
  void hideCursor();

  /// Shows the cursor.
  void showCursor();

  // //////////////////////////////////////////////
  // OUTPUT
  // //////////////////////////////////////////////

  /// Writes raw text at the current cursor position.
  ///
  /// No newline is appended automatically.
  void write(String text);

  /// Writes a line of text followed by a newline.
  void writeln(String text);

  /// Flushes any buffered output.
  void flush();

  /// Emits an audible alert if supported by the platform.
  void beep();

  /// Applies style and color state for a single cell.
  ///
  /// Renderers are expected to call this before emitting glyphs.
  void applyCellStyle({
    required int fg,
    required int bg,
    required bool bold,
    required bool underline,
    required bool inverse,
  });

  // //////////////////////////////////////////////
  // INPUT AND MODES
  // //////////////////////////////////////////////

  /// Enables mouse input reporting.
  void enableMouse();

  /// Disables mouse input reporting.
  void disableMouse();

  /// Enables raw input mode.
  void enableRawMode();

  /// Disables raw input mode.
  void disableRawMode();

  /// Disables all input related modes.
  ///
  /// This is typically used during shutdown.
  void disableInput();

  // //////////////////////////////////////////////
  // BUFFER CONTROL
  // //////////////////////////////////////////////

  /// Enters an alternate screen buffer if supported.
  void createScreenBuffer();

  /// Exits the alternate screen buffer.
  void destoryScreenBuffer();

  // //////////////////////////////////////////////
  // SIZE
  // //////////////////////////////////////////////

  /// The current width of the terminal in cells.
  int get width;

  /// The current height of the terminal in cells.
  int get height;

  /// Returns the current terminal size.
  ({int width, int height}) get size;

}
