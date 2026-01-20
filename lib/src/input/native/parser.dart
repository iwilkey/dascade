/// Parses raw stdin bytes into higher-level Dascade input events.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:dascade/src/input/native/mouse_event.dart';

/// Parses raw stdin bytes into higher-level Dascade input events.
///
/// This emitter mirrors `dart_console` key parsing behavior, and additionally
/// supports ANSI mouse reporting in both:
/// - SGR (1006): `ESC [ < ... M/m`
/// - X10/Normal (1000): `ESC [ M Cb Cx Cy`
///
/// Call [emit] with the first byte of an input sequence. If that byte begins a
/// multi-byte sequence (escape / mouse), this class will synchronously read the
/// remaining bytes from [stdin] to complete parsing.
final class DascadeNativeInputParseEmitter {

  /// This is a static utility. It should never be instantiated.
  DascadeNativeInputParseEmitter._();

  /// ASCII NUL (0x00).
  static const int ASCII_NUL = 0x00;

  /// ASCII ESC (0x1B).
  static const int ASCII_ESC = 0x1b;

  /// ASCII DEL (0x7F).
  static const int ASCII_DEL = 0x7f;

  /// ASCII LF / newline (0x0A).
  static const int ASCII_LF = 0x0a;

  /// ASCII CR / carriage return (0x0D).
  static const int ASCII_CR = 0x0d;

  /// Ctrl+A lower bound (0x01).
  static const int ASCII_CTRL_A_MIN = 0x01;

  /// Ctrl+Z upper bound (0x1A).
  static const int ASCII_CTRL_Z_MAX = 0x1a;

  /// Unknown control range start (0x1C).
  static const int ASCII_CTRL_UNKNOWN_MIN = 0x1c;

  /// Unknown control range end (0x1F).
  static const int ASCII_CTRL_UNKNOWN_MAX = 0x1f;

  /// CSI introducer after ESC: `[` (0x5B).
  static const int ANSI_CSI = 0x5b;

  /// SS3 introducer after ESC: `O` (0x4F).
  static const int ANSI_SS3 = 0x4f;

  /// SGR mouse introducer after CSI: `<` (0x3C).
  static const int ANSI_SGR_MOUSE_INTRO = 0x3c;

  /// X10/Normal mouse introducer after CSI: `M` (0x4D).
  static const int ANSI_X10_MOUSE_INTRO = 0x4d;

  /// SGR mouse terminator for press/motion: `M` (0x4D).
  static const int ANSI_SGR_MOUSE_PRESS = 0x4d;

  /// SGR mouse terminator for release: `m` (0x6D).
  static const int ANSI_SGR_MOUSE_RELEASE = 0x6d;

  /// X10/Normal mouse coordinate offset (Cx/Cy are `pos + 33`).
  static const int ANSI_X10_COORD_OFFSET = 33;

  /// X10/Normal mouse button offset (Cb is `code + 32`).
  static const int ANSI_X10_BUTTON_OFFSET = 32;

  /// Mouse: mask for low button bits.
  static const int ANSI_MOUSE_BUTTON_MASK = 0x03;

  /// Mouse: scroll bit test used by this decoder (bit 6 / value >= 64).
  static const int ANSI_MOUSE_SCROLL_BIT = 64;

  /// '~' terminator for numeric CSI sequences (0x7E).
  static const int ANSI_TILDE = 0x7e;

  /// Numeric CSI digit lower bound: '0'.
  static const int ASCII_DIGIT_0 = 0x30;

  /// Numeric CSI digit upper bound: '9'.
  static const int ASCII_DIGIT_9 = 0x39;

  /// SGR mouse coordinate offset (SGR coords are 1-based).
  static const int ANSI_SGR_COORD_OFFSET = 1;

  /// Emits either a [Key] or a [DascadeNativeMouseEvent] to [sendPort].
  ///
  /// - For normal printable bytes, a printable [Key] is emitted.
  /// - For control bytes and escape sequences, a control [Key] is emitted.
  /// - For mouse sequences, a [DascadeNativeMouseEvent] is emitted and no [Key]
  ///   is sent.
  static void emit(final int codeUnit, final SendPort sendPort) {
    // Ctrl+A through Ctrl+Z (0x01-0x1a)
    // These map directly to ControlCharacter.values[codeUnit]
    if(codeUnit >= ASCII_CTRL_A_MIN && codeUnit <= ASCII_CTRL_Z_MAX) {
      sendPort.send(Key.control(ControlCharacter.values[codeUnit]));
      return;
    }
    // Enter / Return (0x0a or 0x0d)
    if(codeUnit == ASCII_LF || codeUnit == ASCII_CR) {
      sendPort.send(Key.control(ControlCharacter.enter));
      return;
    }
    // Escape sequences (0x1b)
    if(codeUnit == ASCII_ESC) {
      final Key? key = _parseEscapeSequence(sendPort);
      if (key != null) {
        sendPort.send(key);
      }
      return;
    }
    // Backspace (0x7f)
    if(codeUnit == ASCII_DEL) {
      sendPort.send(Key.control(ControlCharacter.backspace));
      return;
    }
    // Unknown control characters (0x00 or 0x1c-0x1f)
    if(codeUnit == ASCII_NUL || (codeUnit >= ASCII_CTRL_UNKNOWN_MIN && codeUnit <= ASCII_CTRL_UNKNOWN_MAX)) {
      sendPort.send(Key.control(ControlCharacter.unknown));
      return;
    }
    // Printable characters
    sendPort.send(Key.printable(String.fromCharCode(codeUnit)));
  }

  /// Parses bytes following an initial [ASCII_ESC].
  ///
  /// Returns a parsed [Key], or `null` when a mouse event was emitted.
  static Key? _parseEscapeSequence(final SendPort sendPort) {
    final Key key = Key.control(ControlCharacter.escape);
    final int charCode = stdin.readByteSync();
    if (charCode == -1) {
      return key; // Just escape
    }
    final String char1 = String.fromCharCode(charCode);
    // ESC + DEL (0x7f) = wordBackspace
    if (charCode == ASCII_DEL) {
      key.controlChar = ControlCharacter.wordBackspace;
      return key;
    }
    // CSI sequences: ESC [
    if (char1 == '[') {
      return _parseCsiSequence(sendPort, key);
    }
    // SS3 sequences: ESC O
    if (char1 == 'O') {
      return _parseSs3Sequence(key);
    }
    // ESC b = wordLeft
    if (char1 == 'b') {
      key.controlChar = ControlCharacter.wordLeft;
      return key;
    }
    // ESC f = wordRight
    if (char1 == 'f') {
      key.controlChar = ControlCharacter.wordRight;
      return key;
    }
    // Unknown escape sequence
    key.controlChar = ControlCharacter.unknown;
    return key;
  }

  /// Parses CSI (Control Sequence Introducer) sequences: `ESC [`.
  ///
  /// CSI may represent arrow keys, navigation keys, page keys, or mouse
  /// reporting sequences.
  static Key? _parseCsiSequence(final SendPort sendPort, final Key key) {
    final int charCode = stdin.readByteSync();
    if (charCode == -1) {
      return key;
    }
    final String char2 = String.fromCharCode(charCode);
    // SGR Mouse sequences: ESC [ <
    // Used by modern terminals (Windows Terminal, iTerm2, GNOME Terminal, etc.)
    if (char2 == '<') {
      _parseSgrMouseSequence(sendPort);
      return null; // Mouse event handled separately
    }
    // X10/Normal Mouse sequences: ESC [ M
    // Used by older terminals and some Windows environments
    if (char2 == 'M') {
      _parseNormalMouseSequence(sendPort);
      return null; // Mouse event handled separately
    }
    // Single character CSI sequences
    switch (char2) {
      case 'A':
        key.controlChar = ControlCharacter.arrowUp;
        return key;
      case 'B':
        key.controlChar = ControlCharacter.arrowDown;
        return key;
      case 'C':
        key.controlChar = ControlCharacter.arrowRight;
        return key;
      case 'D':
        key.controlChar = ControlCharacter.arrowLeft;
        return key;
      case 'H':
        key.controlChar = ControlCharacter.home;
        return key;
      case 'F':
        key.controlChar = ControlCharacter.end;
        return key;
    }
    // Numeric CSI sequences: ESC [ n ~
    // Check if char2 is a digit between '1' and '9'
    if (char2.codeUnits[0] > ASCII_DIGIT_0 && char2.codeUnits[0] < ASCII_DIGIT_9) {
      final int charCode3 = stdin.readByteSync();
      if (charCode3 == -1) {
        return key;
      }
      final String char3 = String.fromCharCode(charCode3);
      if (char3 != '~') {
        key.controlChar = ControlCharacter.unknown;
        return key;
      }
      // Parse the number
      switch (char2) {
        case '1':
          key.controlChar = ControlCharacter.home;
          break;
        case '3':
          key.controlChar = ControlCharacter.delete;
          break;
        case '4':
          key.controlChar = ControlCharacter.end;
          break;
        case '5':
          key.controlChar = ControlCharacter.pageUp;
          break;
        case '6':
          key.controlChar = ControlCharacter.pageDown;
          break;
        case '7':
          key.controlChar = ControlCharacter.home;
          break;
        case '8':
          key.controlChar = ControlCharacter.end;
          break;
        default:
          key.controlChar = ControlCharacter.unknown;
      }
      return key;
    }
    key.controlChar = ControlCharacter.unknown;
    return key;
  }

  /// Parses SS3 (Single Shift 3) sequences: `ESC O`.
  static Key _parseSs3Sequence(final Key key) {
    final int charCode = stdin.readByteSync();
    if (charCode == -1) {
      return key;
    }
    final String char2 = String.fromCharCode(charCode);
    switch (char2) {
      case 'H':
        key.controlChar = ControlCharacter.home;
        break;
      case 'F':
        key.controlChar = ControlCharacter.end;
        break;
      case 'P':
        key.controlChar = ControlCharacter.F1;
        break;
      case 'Q':
        key.controlChar = ControlCharacter.F2;
        break;
      case 'R':
        key.controlChar = ControlCharacter.F3;
        break;
      case 'S':
        key.controlChar = ControlCharacter.F4;
        break;
      default:
        key.controlChar = ControlCharacter.unknown;
    }
    return key;
  }

  /// Parses SGR (1006) mouse sequences: `ESC [ < Ps ; Ps ; Ps M/m`.
  ///
  /// Format: `\x1b[<button;x;y[Mm]`
  /// - `M` = press/motion
  /// - `m` = release
  static void _parseSgrMouseSequence(final SendPort sendPort) {
    // Read until we hit 'M' (press/motion) or 'm' (release)
    final buffer = <int>[];
    while (true) {
      final int b = stdin.readByteSync();
      if (b == -1) break;
      buffer.add(b);
      if (b == ANSI_SGR_MOUSE_PRESS || b == ANSI_SGR_MOUSE_RELEASE) {
        break;
      }
    }
    if (buffer.isEmpty) return;
    // Parse: button;x;y[Mm]
    final String seq = String.fromCharCodes(buffer);
    final bool isRelease =
        seq.endsWith(String.fromCharCode(ANSI_SGR_MOUSE_RELEASE));
    final String params = seq.substring(0, seq.length - 1);
    final List<String> parts = params.split(';');
    if (parts.length != 3) return;
    final int? buttonCode = int.tryParse(parts[0]);
    final int? rawX = int.tryParse(parts[1]);
    final int? rawY = int.tryParse(parts[2]);
    if (buttonCode == null || rawX == null || rawY == null) return;
    // Convert to 0-based coordinates
    final int x = rawX - ANSI_SGR_COORD_OFFSET;
    final int y = rawY - ANSI_SGR_COORD_OFFSET;
    // Decode the button code
    final DascadeNativeMouseEvent? event = _decodeMouseEvent(
      buttonCode: buttonCode,
      x: x,
      y: y,
      isRelease: isRelease,
    );
    if (event != null) {
      sendPort.send(event);
    }
  }

  /// Parses X10/Normal (1000) mouse sequences: `ESC [ M Cb Cx Cy`.
  ///
  /// - `Cb = button + 32`
  /// - `Cx = x + 33`
  /// - `Cy = y + 33`
  static void _parseNormalMouseSequence(final SendPort sendPort) {
    // Read exactly 3 bytes: Cb, Cx, Cy
    final int cb = stdin.readByteSync();
    final int cx = stdin.readByteSync();
    final int cy = stdin.readByteSync();
    if (cb == -1 || cx == -1 || cy == -1) return;
    // Decode coordinates (subtract 33 to get 0-based)
    final int x = cx - ANSI_X10_COORD_OFFSET;
    final int y = cy - ANSI_X10_COORD_OFFSET;
    // Decode button (subtract 32)
    final int buttonCode = cb - ANSI_X10_BUTTON_OFFSET;
    // In normal mode, button 3 typically means release
    // However, we can't always distinguish which button was released
    final bool isRelease = (buttonCode & ANSI_MOUSE_BUTTON_MASK) == 3;
    final DascadeNativeMouseEvent? event = _decodeMouseEvent(
      buttonCode: buttonCode,
      x: x,
      y: y,
      isRelease: isRelease,
    );
    if (event != null) {
      sendPort.send(event);
    }
  }

  /// Decodes an ANSI mouse button code into a [DascadeNativeMouseEvent].
  ///
  /// This covers both SGR (1006) and X10/Normal (1000) protocols.
  static DascadeNativeMouseEvent? _decodeMouseEvent({
    required int buttonCode,
    required int x,
    required int y,
    required bool isRelease,
  }) {
    // Validate coordinates
    if (x < 0 || y < 0) return null;
    // Check for scroll wheel events (bit 6 set, value >= 64)
    final bool isScroll = (buttonCode & ANSI_MOUSE_SCROLL_BIT) != 0;
    int scroll = 0;
    bool leftDown = false;
    bool leftUp = false;
    bool middleDown = false;
    bool middleUp = false;
    bool rightDown = false;
    bool rightUp = false;
    if (isScroll) {
      // Scroll events: 64 = up, 65 = down, 66 = left (rare), 67 = right (rare)
      final int scrollDirection = buttonCode & ANSI_MOUSE_BUTTON_MASK;
      switch (scrollDirection) {
        case 0: // scroll up
          scroll = 1;
          break;
        case 1: // scroll down
          scroll = -1;
          break;
        case 2: // scroll left
          scroll = 0;
          break;
        case 3: // scroll right
          scroll = 0;
          break;
      }
    } else {
      // Regular button events
      final int button = buttonCode & ANSI_MOUSE_BUTTON_MASK;

      if (isRelease) {
        // Release event
        switch (button) {
          case 0:
            leftUp = true;
            break;
          case 1:
            middleUp = true;
            break;
          case 2:
            rightUp = true;
            break;
          case 3:
            // In normal mode, 3 means "release" but we don't know which button.
            leftUp = true;
            break;
        }
      } else {
        // Press or motion event
        switch (button) {
          case 0:
            leftDown = true;
            break;
          case 1:
            middleDown = true;
            break;
          case 2:
            rightDown = true;
            break;
          case 3:
            // Button 3 in press context is unusual, treat as no-op.
            break;
        }
      }
    }
    return DascadeNativeMouseEvent(
      x: x,
      y: y,
      leftDown: leftDown,
      leftUp: leftUp,
      middleDown: middleDown,
      middleUp: middleUp,
      rightDown: rightDown,
      rightUp: rightUp,
      scroll: scroll,
    );
  }
}
