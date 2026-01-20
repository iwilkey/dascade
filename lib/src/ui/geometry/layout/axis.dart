/// Defines the primary axis for layout containers like rows and columns.
///
/// This enum is used to describe how children are laid out inside a container:
/// - [horizontal] layouts arrange children left-to-right.
/// - [vertical] layouts arrange children top-to-bottom.
library;

enum DULayoutAxis {
  /// Children are laid out from left to right.
  horizontal,

  /// Children are laid out from top to bottom.
  vertical,
}
