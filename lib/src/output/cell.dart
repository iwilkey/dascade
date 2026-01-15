/// Bit-packed terminal cell utilities.
library;

/// A cell is represented as a single 64-bit integer containing glyph,
/// color, and style information. Buffers store raw integers; this class
/// provides helpers to encode and decode cell state.
final class DascadeCell {

  /// The cell packing paradigm is as follows:
  /// 
  /// A "cell" is one 64-bit integer.
  ///
  /// - Bits  0–20  (21): Glyph (Unicode codepoint)
  /// 
  /// - Bits 21–28  (8):  Foreground ANSI color (0–255)
  /// 
  /// - Bits 29–36  (8):  Background ANSI color (0–255)
  /// 
  /// - Bits 37     (1):  Bold
  /// 
  /// - Bits 38     (1):  Underline
  /// 
  /// - Bits 39     (1):  Inverse
  /// 
  /// - Bits 40     (1):  Dim (future?)
  /// 
  /// - Bits 41     (1):  Blink (future?)
  /// 
  /// - Bits 42     (1):  Strikethrough (future?)
  /// 
  /// - Bits 43–63       RESERVED (future)

  static const int _emptyCell      = 0;
  static const int _glyphBits      = 21;
  static const int _colorBits      = 8;
  static const int _glyphShift     = 0;
  static const int _fgShift        = 21;
  static const int _bgShift        = 29;
  static const int _boldShift      = 37;
  static const int _underlineShift = 38;
  static const int _inverseShift   = 39;
  static const int _glyphMask      = (1 << _glyphBits) - 1;
  static const int _colorMask      = (1 << _colorBits) - 1;

  /// Encodes a terminal cell into a 64-bit integer, where:
  static int encode({
    required int glyph,
    required int fg, // ANSI 0–255
    required int bg, // ANSI 0–255
    final bool bold = false,
    final bool underline = false,
    final bool inverse = false,
  }) {
    assert(glyph >= 0 && glyph <= 0x10FFFF);
    assert(fg >= 0 && fg <= 255);
    assert(bg >= 0 && bg <= 255);
    return (glyph & _glyphMask) |
           ((fg & _colorMask) << _fgShift) |
           ((bg & _colorMask) << _bgShift) |
           (bold ? (1 << _boldShift) : 0) |
           (underline ? (1 << _underlineShift) : 0) |
           (inverse ? (1 << _inverseShift) : 0);
  }

  /// Returns if the given cell is empty.
  static bool empty(final int cell) => cell == _emptyCell;

  /// Decodes the target glyph code packed in given cell value.
  static int glyph(final int cell) => (cell >> _glyphShift) & _glyphMask;

  /// Decodes the target foreground ANSI color packed in given cell value.
  static int foreground(final int cell) => (cell >> _fgShift) & _colorMask;

  /// Decodes the target background ANSI color packed in given cell value.
  static int background(final int cell) => (cell >> _bgShift) & _colorMask;

  /// Decodes the target bold state packed in given cell value.
  static bool isBold(final int cell) => (cell & (1 << _boldShift)) != 0;

  /// Decodes the target underline state in given cell value.
  static bool isUnderline(final int cell) => (cell & (1 << _underlineShift)) != 0;

  /// Decodes the target inverse state in given cell value.
  static bool isInverse(final int cell) => (cell & (1 << _inverseShift)) != 0;

  /// Compares one cell to another (can be used for diffing.)
  static bool equals(final int cell0, final int cell1) => cell0 == cell1;

}
