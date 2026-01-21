/// Dascade theme.
///
/// This file defines a tiny, dependency-free style system that maps cleanly to
/// Dascade’s 256-color cell encoding (fg/bg 0–255 + bold).
library;

import 'package:dascade/src/ui/style/ansi.dart';
import 'package:dascade/src/ui/style/color.dart';

/// Theme used to style elements.
final class DUITheme {

  /// The default look of Dascade.
  static const DUITheme defaultTheme = DUITheme(
    text: DUIColor(fg: DUIAnsi.brightWhite, bg: DUIAnsi.black),
    frame: DUIColor(fg: DUIAnsi.brightWhite, bg: DUIAnsi.black),
    frameFocused: DUIColor(fg: DUIAnsi.accent, bg: DUIAnsi.black, bold: true),
    cursor: DUIColor(fg: DUIAnsi.black, bg: DUIAnsi.accent, bold: true),
    button: DUIColor(fg: DUIAnsi.brightWhite, bg: DUIAnsi.black),
    buttonFocused: DUIColor(fg: DUIAnsi.accent, bg: DUIAnsi.black, bold: true),
    buttonDown: DUIColor(fg: DUIAnsi.black, bg: DUIAnsi.accent, bold: true),
    buttonDownFocused: DUIColor(fg: DUIAnsi.black, bg: DUIAnsi.accent, bold: true),
  );

  /// The color of rendered plaintext.
  final DUIColor text;

  /// The color of a non-focused frame.
  final DUIColor frame;

  /// The color of a focused frame.
  final DUIColor frameFocused;

  /// The color of a rendered cursor (like in textboxes or textfields).
  final DUIColor cursor;

  /// Base button face (normal).
  final DUIColor button;

  /// Button face when focused.
  final DUIColor buttonFocused;

  /// Button face when held down (mouse/enter pressed).
  final DUIColor buttonDown;

  /// Button face when held down and focused.
  final DUIColor buttonDownFocused;

  const DUITheme({
    required this.text,
    required this.frame,
    required this.frameFocused,
    required this.cursor,
    required this.button,
    required this.buttonFocused,
    required this.buttonDown,
    required this.buttonDownFocused,
  });

}
