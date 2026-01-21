/// Immutable ANSI style (256-color fg/bg + bold).
library;

/// Immutable ANSI style (256-color fg/bg + bold).
///
/// Dascade encodes cell colors as 0–255 indices (xterm-256 palette). This class
/// simply standardizes how widgets describe color intent.
final class DUIColor {
  
  /// Foreground palette index (0–255).
  final int fg;

  /// Background palette index (0–255).
  final int bg;

  /// Bold flag.
  final bool bold;

  const DUIColor({
    required this.fg,
    required this.bg,
    this.bold = false,
  });

  int get fgClamped => fg.clamp(0, 255);
  int get bgClamped => bg.clamp(0, 255);

}
