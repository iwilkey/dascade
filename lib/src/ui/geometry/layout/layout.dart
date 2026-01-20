/// High-level, child-count-agnostic layout rules for the Dascade UI system.
///
/// This file defines the `DULayout` abstraction, which is responsible for
/// producing a normalized list of layout weights **at layout time**, based
/// solely on the number of children being laid out.
library;

/// A high-level, child-count-agnostic layout rule.
///
/// Subclasses encode *how* space should be distributed, and are responsible
/// for generating a normalized list of weights for a given child count.
abstract class DULayout {

  /// Resolves the final list of normalized weights for a given child count.
  ///
  /// Implementations must:
  /// - Return exactly `count` entries
  /// - Ensure the returned weights sum to **1.0**
  ///
  /// Throws if the layout rule cannot be satisfied for the given count.
  List<double> generate(final int count);

  /// Most direct way of describing layout to Dascade UI. The weights given here
  /// must sum to 1, no exceptions. While there is epsilon tolerance, still be mindful 
  /// of floating-point rounding.
  ///
  /// Example:
  /// ```dart
  /// DULayout.custom([0.25, 0.5, 0.25]);
  /// ```
  static DULayout custom(final List<double> weights) => _DULayoutCustom(weights);

  /// Distributes space equally among all children.
  ///
  /// Example:
  /// ```dart
  /// DULayout.equal().generate(3); // [0.333, 0.333, 0.333]
  /// ```
  static DULayout equal() => _DULayoutEqual();

  /// Uses explicitly provided weights.
  ///
  /// The values do **not** need to sum to 1.0; they will be normalized.
  ///
  /// This is the escape hatch for full manual control and preserves the
  /// behavior of the original system.
  ///
  /// Example:
  /// ```dart
  /// DULayout.flex([2, 1, 1]); // → [0.5, 0.25, 0.25]
  /// ```
  static DULayout flex(final List<double> raw) => _DULayoutFlex(raw);

  /// Assigns a fixed portion of space to the first child, and distributes
  /// the remainder equally among the rest.
  ///
  /// This is extremely useful for sidebars, inspectors, and master-detail
  /// layouts.
  ///
  /// Example (3 children):
  /// ```dart
  /// DULayout.firstFixed(0.3).generate(3);
  /// // → [0.3, 0.35, 0.35]
  /// ```
  static DULayout firstFixed(final double first, [final double rest = 1.0]) => _DULayoutFirstFixed(first, rest);

  /// Expands a single child while all others share the remaining space.
  ///
  /// Useful for "main view + tool panes" layouts.
  ///
  /// Example:
  /// ```dart
  /// DULayout.singleExpanded(1); // second child dominates
  /// ```
  static DULayout singleExpanded(final int index, {final double expanded = 1.0, double rest = 0.2}) => _DULayoutSingleExpanded(index, expanded, rest);

}

/// Distributes space equally among all children.
final class _DULayoutEqual extends DULayout {

  @override
  List<double> generate(final int count) {
    if(count <= 0) return const [];
    final double w = 1.0 / count;
    return List<double>.filled(count, w);
  }

}

/// Uses explicitly provided weights.
///
/// The values do **not** need to sum to 1.0; they will be normalized.
final class _DULayoutFlex extends DULayout {

  final List<double> raw;

  _DULayoutFlex(this.raw);

  @override
  List<double> generate(int count) {
    if(raw.length != count) {
      throw Exception(
        '[Dascade UI] DULayout.flex: expected $count weights, got ${raw.length}.',
      );
    }
    final double total = raw.fold(0.0, (a, b) => a + b);
    if(total <= 0.0) {
      throw Exception(
        '[Dascade UI] DULayout.flex: sum of weights must be > 0.',
      );
    }
    return raw.map((w) => w / total).toList();
  }

}

/// Assigns a fixed portion of space to the first child, and distributes
/// the remainder equally among the rest.
///
/// This is extremely useful for sidebars, inspectors, and master-detail
/// layouts.
final class _DULayoutFirstFixed extends DULayout {

  final double first;
  final double rest;

  _DULayoutFirstFixed(this.first, this.rest);

  @override
  List<double> generate(final int count) {
    if(count <= 0) return const [];
    if(count == 1) return const [1.0];
    final double restTotal = rest * (count - 1);
    final double total = first + restTotal;
    if(total <= 0.0) {
      throw Exception(
        '[Dascade UI] DULayout.firstFixed: total weight must be > 0.',
      );
    }
    return <double>[
      first / total,
      ...List<double>.filled(count - 1, rest / total),
    ];
  }

}

/// Most direct way of describing layout to Dascade UI. The weights given here
/// must sum to 1, no exceptions. While there is epsilon tolerance, still be mindful 
/// of floating-point rounding.
final class _DULayoutCustom extends DULayout {

  /// Epsilon for floating-point rounding errors.
  static const double _EPS = 0.001;

  final List<double> weights;

  _DULayoutCustom(this.weights);

  @override
  List<double> generate(final int count) {
    if(weights.length != count) {
      throw Exception(
        '[Dascade UI] DULayout.custom: expected $count entries, got ${weights.length}.',
      );
    }
    final double total = weights.fold(0, (a, b) => a + b);
    if((total - 1.0).abs() > _EPS) {
      throw Exception(
        '[Dascade UI] DULayout.custom: sum of ratios must be equal to one.',
      );
    }
    return weights;
  }
}

/// Expands a single child while all others share the remaining space.
///
/// Useful for "main view + tool panes" layouts.
final class _DULayoutSingleExpanded extends DULayout {

  final int index;
  final double expanded;
  final double rest;

  _DULayoutSingleExpanded(this.index, this.expanded, this.rest);
  
  @override
  List<double> generate(final int count) {
    if(count <= 0) return const [];
    if(index < 0 || index >= count) {
      throw Exception(
        '[Dascade UI] DULayout.singleExpanded: index $index out of range.',
      );
    }
    final List<double> raw = List<double>.filled(count, rest);
    raw[index] = expanded;
    final double total = raw.fold(0.0, (a, b) => a + b);
    if(total <= 0.0) {
      throw Exception(
        '[Dascade UI] DULayout.singleExpanded: total weight must be > 0.',
      );
    }
    return raw.map((w) => w / total).toList();
  }

}
