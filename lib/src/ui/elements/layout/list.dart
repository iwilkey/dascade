/// A scrollable viewport element that constrains and renders child elements.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/color.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// A scrollable, unbounded virtual space to assemble an arbitrary list of
/// fixed-size elements.
final class DUList implements DUElement {

  /// Whether to draw a border frame around the list.
  final bool border;

  /// Whether the list scrolls horizontally.
  ///
  /// - false (default): vertical list (scrollY).
  /// - true: horizontal list (scrollX).
  final bool horizontal;

  /// Theme for consistent element styling.
  final DUITheme theme;

  /// The text to render at the upper left hand corner of the border (if it's active.)
  final String? borderLabel;

  /// Current scroll offset in the primary axis (rows or columns).
  int scroll = 0;

  // Immediate-mode inputs for this frame.
  List<DUElement> _children = const <DUElement>[];

  int _itemSize = 1;
  int _gap = 0;
  int _pad = 0;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  DUList({
    required this.border,
    this.horizontal = false,
    this.theme = DUITheme.defaultTheme,
    this.borderLabel
  });

  /// Provides the per-frame child list and layout parameters.
  ///
  /// [itemSize] is the fixed size (in cells) assigned to EACH child
  /// along the list axis:
  /// - vertical: each child gets height = itemSize
  /// - horizontal: each child gets width  = itemSize
  ///
  /// Call this every frame (immediate-mode style) before the element is rendered.
  DUList show(
    final List<DUElement> children, {
    required final int itemSize,
    final int gap = 0,
    final int pad = 0,
  }) {
    if(itemSize < 0) {
      throw Exception('[Dascade UI] DUList: itemSize cannot be negative.');
    }
    if(gap < 0) {
      throw Exception('[Dascade UI] DUList: gap cannot be negative.');
    }
    if(pad < 0) {
      throw Exception('[Dascade UI] DUList: pad cannot be negative.');
    }
    _children = children;
    _itemSize = itemSize;
    _gap = gap;
    _pad = pad;
    return this;
  }

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  DURect get _contentRect {
    final DURect base = border ? _rect.inset(1) : _rect;
    return _pad > 0 ? base.inset(_pad) : base;
  }

  @override
  void interact(final DURuntime r) {
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    final bool clicked = r.clicked(this, _rect);
    if(clicked) {
      r.focused = this;
    }
    final bool focused = (r.focused == this);
    // Mouse wheel scroll when hovered over content.
    if(r.hovered(c) && r.wheel != 0) {
      // "Wheel" is vertical by convention, but we reuse it for horizontal lists too.
      // This matches typical UI where wheel scrolls the active axis.
      scroll += (-r.wheel) * 2;
    }
    // Arrow key scroll ONLY when focused.
    if(focused) {
      if(!horizontal) {
        if(r.upPressed) scroll -= 1;
        if(r.downPressed) scroll += 1;
      } else {
        if(r.leftPressed) scroll -= 1;
        if(r.rightPressed) scroll += 1;
      }
    }
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    final DURect outer = _rect;
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    final bool focused = (r.focused == this);
    // Frame.
    if(border) {
      final DUIColor frameStyle = focused ? theme.frameFocused : theme.frame;
      p.drawFrame(
        outer,
        title: borderLabel,
        frameFg: frameStyle.fgClamped,
        frameBg: frameStyle.bgClamped,
      );
    }
    // Clip children to content.
    p.pushClip(c);
    final List<DUElement> children = _children;
    final int n = children.length;
    if(n == 0) {
      p.popClip();
      return;
    }
    final int itemSize = _itemSize;
    final int gap = _gap;
    // Virtual content size along the list axis:
    // n * itemSize + (n - 1) * gap
    final int contentSize = math.max(0, (n * itemSize) + ((n - 1) * gap));
    final int viewportSize = horizontal ? c.width : c.height;
    // Clamp scroll to valid range.
    final int maxScroll = math.max(0, contentSize - viewportSize);
    scroll = scroll.clamp(0, maxScroll);
    final int viewA = scroll;
    final int viewB = scroll + viewportSize;
    // Render only visible children.
    for(int i = 0; i < n; i++) {
      final int a0 = i * (itemSize + gap);
      final int a1 = a0 + itemSize;
      if(a1 <= viewA) continue;
      if(a0 >= viewB) continue;
      final DUElement child = children[i];
      if(!horizontal) {
        final int y0 = c.top + (a0 - viewA);
        final int y1 = c.top + (a1 - viewA);
        final DURect childRect = DURect(
          upperLeft: DUPoint(x: c.left, y: y0),
          lowerRight: DUPoint(x: c.right, y: y1),
        );
        child.layout(childRect);
      } else {
        final int x0 = c.left + (a0 - viewA);
        final int x1 = c.left + (a1 - viewA);
        final DURect childRect = DURect(
          upperLeft: DUPoint(x: x0, y: c.top),
          lowerRight: DUPoint(x: x1, y: c.bottom),
        );
        child.layout(childRect);
      }
      child.interact(r);
      child.render(p, r);
    }
    p.popClip();
  }
}
