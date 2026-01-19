/// Layout engine for Dascade UI.
library;

import 'package:dascade/src/ui/math/rect.dart';

/// Primary layout direction for a layout scope.
enum DULayoutAxis {
  /// Children are laid out left-to-right.
  horizontal,

  /// Children are laid out top-to-bottom.
  vertical,
}

/// Active layout scope describing how child slots are allocated.
///
/// A scope:
/// - owns a rectangular region
/// - divides it into a fixed number of children
/// - distributes space using normalized weights
/// - enforces strict child counts
///
/// Scopes are pushed/popped as row()/column() calls are entered/exited.
final class DULayoutScope {
  /// Layout direction.
  final DULayoutAxis axis;

  /// Rectangular region this scope manages.
  final DURect rect;

  /// Number of children expected in this scope.
  final int children;

  /// Relative size weights per child.
  ///
  /// Length must equal [children].
  final List<double> weights;

  /// Gap (in terminal cells) between children.
  final int gap;

  /// Number of children already consumed.
  int index = 0;

  DULayoutScope({
    required this.axis,
    required this.rect,
    required this.children,
    required this.weights,
    required this.gap,
  });
}

/// Result of slot allocation within a layout scope.
///
/// A slot represents:
/// - the exact rectangle assigned to a child
/// - a stable, content-independent element ID
///
/// Slots are ephemeral per-frame but IDs remain stable
/// as long as layout structure is unchanged.
final class DUSlot {
  /// Assigned rectangle for the element.
  final DURect rect;

  /// Stable element identifier.
  final int id;

  const DUSlot({
    required this.rect,
    required this.id,
  });
}
