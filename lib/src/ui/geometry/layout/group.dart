/// Base class for layout containers like [DURow] and [DUColumn].
library;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/layout/axis.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';

/// Base class for layout containers like [DURow] and [DUColumn].
///
/// This element handles splitting a given rectangle into slots for children,
/// based on the given axis, weights, padding, and gap spacing.
/// It then delegates layout, interaction, and rendering to each child.
///
/// Layout groups themselves do not respond to input directly.
abstract class DULayoutGroup extends DUElement {
  
  /// Child elements to be arranged by the layout group.
  final List<DUElement> children;

  /// Relative size weights for each child.
  final List<double> weights;

  /// Space between adjacent children.
  final int gap;

  /// Padding applied inside the layout's outer rectangle.
  final int pad;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  DULayoutGroup(
    this.children, {
    required this.weights,
    required this.gap,
    required this.pad,
  }) {
    if(weights.length != children.length) {
      throw StateError(
        'Layout error: weights length (${weights.length}) must match children length (${children.length}).',
      );
    }
  }

  /// The main axis used to arrange children.
  DULayoutAxis get axis;

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  @override
  void interact(final DURuntime r) {
    // Layout containers do not handle interaction directly.
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    final DURect content = pad > 0 ? _rect.inset(pad) : _rect;
    final List<DURect> slots = _split(content);
    for(int i = 0; i < children.length; i++) {
      final DUElement child = children[i];
      child.layout(slots[i]);
      child.interact(r);
      child.render(p, r);
    }
  }

  /// Splits the given rect into `children.length` slots based on weights and gap.
  List<DURect> _split(final DURect rect) {
    final int mainSize = axis == DULayoutAxis.horizontal ? rect.width : rect.height;
    final int crossA = axis == DULayoutAxis.horizontal ? rect.top : rect.left;
    final int crossB = axis == DULayoutAxis.horizontal ? rect.bottom : rect.right;
    final int totalGap = gap * (children.length - 1);
    final int available = mainSize - totalGap;
    if(available <= 0) {
      return List<DURect>.generate(
        children.length,
        (_) => DURect(upperLeft: rect.upperLeft, lowerRight: rect.upperLeft),
      );
    }
    final double sum = weights.fold(0.0, (a, b) => a + b);
    if(sum <= 0) {
      return List<DURect>.generate(
        children.length,
        (_) => DURect(upperLeft: rect.upperLeft, lowerRight: rect.upperLeft),
      );
    }
    final List<int> sizes = List<int>.filled(children.length, 0);
    int used = 0;
    for(int i = 0; i < children.length; i++) {
      final int s = (available * (weights[i] / sum)).floor();
      sizes[i] = s;
      used += s;
    }
    int rem = available - used;
    for(int i = 0; i < children.length && rem > 0; i++, rem--) {
      sizes[i] += 1;
    }
    int cursor = axis == DULayoutAxis.horizontal ? rect.left : rect.top;
    final List<DURect> out = [];
    for(int i = 0; i < children.length; i++) {
      final int size = sizes[i];
      final DURect slot = axis == DULayoutAxis.horizontal
        ? DURect(
            upperLeft: DUPoint(x: cursor, y: crossA),
            lowerRight: DUPoint(x: cursor + size, y: crossB),
          )
        : DURect(
            upperLeft: DUPoint(x: rect.left, y: cursor),
            lowerRight: DUPoint(x: rect.right, y: cursor + size),
          );
      out.add(slot);
      cursor += size + gap;
    }
    return out;
  }
  
}
