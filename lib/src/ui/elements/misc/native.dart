/// A native per-frame rendering plane element.
///
/// DUNative lets you draw arbitrary 2D content inside the element's rect using
/// the existing low-level [DURenderer.draw] API, but with coordinates
/// relative to the element (0..width-1, 0..height-1).
library;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// Per-frame draw callback signature.
typedef DUNativeDraw = void Function(int width, int height, DURenderer renderer);

/// A rendering plane element that provides a local coordinate system.
final class DUNative implements DUElement {

  /// Whether to draw a border frame around the plane.
  final bool border;

  /// Theme for consistent styling.
  final DUITheme theme;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  DUNativeDraw? _draw;

  DUNative({
    required this.border,
    this.theme = DUITheme.defaultTheme,
  });

  /// Sets the per-frame draw callback and returns this element for inline use.
  ///
  /// Call this every frame (immediate-mode style):
  /// `native.renderPlane((w,h,p){ ... });`
  DUNative draw(final DUNativeDraw instruction) {
    _draw = instruction;
    return this;
  }

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  DURect get _contentRect => border ? _rect.inset(1) : _rect;

  @override
  void interact(final DURuntime r) {
    // Intentionally no-op: this element is purely for rendering.
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    // Frame.
    if(border) {
      p.drawFrame(
        _rect,
        title: null,
        frameFg: theme.frame.fgClamped,
        frameBg: theme.frame.bgClamped,
      );
    }
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) {
      _draw = null;
      return;
    }
    final DUNativeDraw? draw = _draw;
    if(draw == null) return;
    // Provide a translated renderer so (0,0) is the content top-left.
    final DURenderer local = _DULocalRenderer(
      base: p,
      originX: c.left,
      originY: c.top,
      clip: c,
    );
    draw(c.width, c.height, local);
    // Clear the callback after render to enforce "per-frame" drawing.
    _draw = null;
  }
}

/// A renderer wrapper that translates local coords into absolute coords and
/// clips to a fixed rect. Uses the same low-level [draw] entrypoint.
final class _DULocalRenderer extends DURenderer {

  final DURenderer base;
  final int originX;
  final int originY;
  final DURect clip;

  _DULocalRenderer({
    required this.base,
    required this.originX,
    required this.originY,
    required this.clip,
  }) : super(base.d);

  @override
  void draw(
    final int x,
    final int y,
    final int glyph, {
    final int fg = 15,
    final int bg = 0,
    final bool bold = false,
  }) {
    final int ax = originX + x;
    final int ay = originY + y;
    if(!clip.contains(ax, ay)) return;
    base.draw(
      ax,
      ay,
      glyph,
      fg: fg,
      bg: bg,
      bold: bold,
    );
  }

  @override
  void drawFrame(
    final DURect rect, {
    final String? title,
    final int frameFg = 15,
    final int frameBg = 0,
  }) {
    final DURect translated = DURect(
      upperLeft: DUPoint(x: originX + rect.left, y: originY + rect.top),
      lowerRight: DUPoint(x: originX + rect.right, y: originY + rect.bottom),
    );
    base.pushClip(clip);
    base.drawFrame(
      translated,
      title: title,
      frameFg: frameFg,
      frameBg: frameBg,
    );
    base.popClip();
  }

  @override
  void drawText(
    final DURect rect,
    final List<String> lines, {
    final int fg = 15,
    final int bg = 0,
  }) {
    final DURect translated = DURect(
      upperLeft: DUPoint(x: originX + rect.left, y: originY + rect.top),
      lowerRight: DUPoint(x: originX + rect.right, y: originY + rect.bottom),
    );
    base.pushClip(clip);
    base.drawText(
      translated,
      lines,
      fg: fg,
      bg: bg,
    );
    base.popClip();
  }

  // Clip stack methods should operate on the base renderer.
  @override
  void pushClip(final DURect r) {
    final DURect translated = DURect(
      upperLeft: DUPoint(x: originX + r.left, y: originY + r.top),
      lowerRight: DUPoint(x: originX + r.right, y: originY + r.bottom),
    );
    base.pushClip(clip);
    base.pushClip(translated);
  }

  @override
  void popClip() {
    base.popClip();
    base.popClip();
  }

}
