/// Base class for layout containers like [DURow] and [DUColumn].
library;

import 'dart:math' as math;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/geometry/layout/axis.dart';

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
  ///
  /// Best-effort behavior when cramped:
  /// - If there isn't enough room for gaps, gaps are reduced to 0.
  /// - If there still isn't enough room, allocate 1 cell to as many children as possible.
  /// - Remaining children receive 0-size rects.
  List<DURect> _split(final DURect rect) {
    final int n = children.length;
    if(n == 0) return const <DURect>[];
    final bool horiz = axis == DULayoutAxis.horizontal;
    final int mainSize = horiz ? rect.width : rect.height;
    final int crossA = horiz ? rect.top : rect.left;
    final int crossB = horiz ? rect.bottom : rect.right;
    if(mainSize <= 0) {
      /// we have to drop all children.
      DascadeUI.overflow = true;
      return List<DURect>.generate(
        n,
        (_) => DURect(upperLeft: rect.upperLeft, lowerRight: rect.upperLeft),
      );
    }
    const int minMain = 3;
    // First: try with the requested gap.
    int effectiveGap = gap;
    int totalGap = effectiveGap * (n - 1);
    int available = mainSize - totalGap;
    // If gaps make it impossible to fit even ONE min-sized child, drop gaps.
    if(available < minMain) {
      effectiveGap = 0;
      totalGap = 0;
      available = mainSize;
    }
    // If we still can't fit n * minMain, we cannot satisfy the guarantee for all children.
    // Best-effort: give minMain to as many as possible, remainder get 0.
    final int maxMinChildren = available ~/ minMain;
    if(maxMinChildren < n) {
      /// we have to drop some children.
      DascadeUI.overflow = true;
      final List<int> sizes = List<int>.filled(n, 0);
      final int k = math.max(0, math.min(n, maxMinChildren));
      for(int i = 0; i < k; i++) {
        sizes[i] = minMain;
      }
      // Any leftover space goes to the first visible child.
      final int usedMin = k * minMain;
      final int leftover = available - usedMin;
      if(k > 0 && leftover > 0) {
        sizes[0] += leftover;
      }
      return _rectsFromSizes(
        rect,
        sizes,
        gap: effectiveGap,
        crossA: crossA,
        crossB: crossB,
        horiz: horiz,
      );
    }
    // Otherwise: everyone can get at least minMain.
    // Do your normal weighted distribution over the remaining space.
    final double sum = weights.fold(0.0, (a, b) => a + b);
    final List<int> sizes = List<int>.filled(n, minMain);
    int remaining = available - (n * minMain);
    if(remaining > 0 && sum > 0.0) {
      int used = 0;
      final List<int> extra = List<int>.filled(n, 0);
      for(int i = 0; i < n; i++) {
        final int s = (remaining * (weights[i] / sum)).floor();
        extra[i] = s;
        used += s;
      }
      int rem = remaining - used;
      for(int i = 0; i < n && rem > 0; i++, rem--) {
        extra[i] += 1;
      }
      for(int i = 0; i < n; i++) {
        sizes[i] += extra[i];
      }
    }
    return _rectsFromSizes(
      rect,
      sizes,
      gap: effectiveGap,
      crossA: crossA,
      crossB: crossB,
      horiz: horiz,
    );
  }

  List<DURect> _rectsFromSizes(
    final DURect rect,
    final List<int> sizes, {
    required final int gap,
    required final int crossA,
    required final int crossB,
    required final bool horiz,
  }) {
    int cursor = horiz ? rect.left : rect.top;
    final List<DURect> out = <DURect>[];
    for(int i = 0; i < sizes.length; i++) {
      final int size = sizes[i];
      final DURect slot = horiz
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
