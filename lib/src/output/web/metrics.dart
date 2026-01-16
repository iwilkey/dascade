/// Shared rendering metrics for the web backend.
///
/// This class defines the canonical cell and glyph measurements used by
/// all web based Dascade systems, including rendering and input handling.
/// These values are intentionally fixed to ensure that drawing, hit testing,
/// and layout remain perfectly aligned to the terminal cell grid.
library;

final class DascadeWebMetrics {

  /// Width of a single terminal cell in physical pixels.
  ///
  /// All horizontal layout and mouse hit testing is derived from this value.
  static const int cellWidth = 9;

  /// Height of a single terminal cell in physical pixels.
  ///
  /// All vertical layout and mouse hit testing is derived from this value.
  static const int cellHeight = 18;

  /// Horizontal glyph offset from the left edge of a cell.
  ///
  /// This offset aligns glyphs to a terminal style baseline rather than
  /// true geometric centering, matching the behavior of real terminals.
  static const int glyphXOffset = 1;

  /// Vertical glyph baseline offset from the top edge of a cell.
  ///
  /// This value positions text using font ascent metrics so glyphs appear
  /// consistent with native terminal rendering.
  static const int glyphYOffset = 14;

}
