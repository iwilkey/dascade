/// Base class + helpers for authoring custom Dascade UI elements.
///
/// This file is intended to be public API. Contributors should be able to
/// implement almost any widget by extending [DUCustomElement] and using its
/// interaction + paint helpers.
///
/// Design contract:
/// - Elements trust the [DURect] assigned in [layout] and render entirely inside it.
/// - Elements do no parent/child layout math.
/// - All colors must come from [DUITheme] (never hardcode fg/bg values).
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/color.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// A batteries-included base class for building UI elements quickly.
///
/// Provides:
/// - Rect storage + border/content rect helpers
/// - Standard click-to-focus
/// - Standard press/hold/release semantics (down/fire)
/// - Drawing helpers: frame, fill, text, centered label (even-row underline)
///
/// Typical custom element:
/// ```dart
/// final class DUMyElement extends DUCustomElement {
///   DUMyElement() : super(border: true);
///
///   @override
///   void interact(final DURuntime r) {
///     updatePressable(r); // sets down/fire
///     if(fire) { /* do thing */ }
///   }
///
///   @override
///   void render(final DURenderer p, final DURuntime r) {
///     drawFrameIfNeeded(p, r);
///     fillContent(p, faceColor(p, r));
///     drawCenteredLabel(p, 'Hello', color: faceColor(p, r));
///   }
/// }
/// ```
abstract class DUCustomElement implements DUElement {

  /// Whether this element draws a border frame.
  final bool border;

  /// Optional title to render into the frame top border.
  final String? borderLabel;

  /// Theme used for all rendering.
  final DUITheme theme;

  /// True while the element is being held down this frame (mouse or Enter).
  bool down = false;

  /// True for exactly one frame when the element is released inside bounds.
  bool fire = false;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  bool _prevEnterDown = false;
  bool _keyboardHeld = false;

  DUCustomElement({
    required this.border,
    this.borderLabel,
    this.theme = DUITheme.defaultTheme,
  });

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  /// The full element bounds (includes border if enabled).
  DURect get outerRect => _rect;

  /// The drawable content bounds (excludes border if enabled).
  DURect get contentRect => border ? _rect.inset(1) : _rect;

  /// Returns true if this element is currently focused.
  bool isFocused(final DURuntime r) => identical(r.focused, this);

  /// Returns true if the mouse is currently hovering this element.
  bool isHovered(final DURuntime r, {final bool contentOnly = false}) {
    return r.hovered(contentOnly ? contentRect : outerRect);
  }

  /// Standard click-to-focus behavior.
  ///
  /// Returns true if the mouse was pressed and released inside [hitRect].
  /// (Also claims focus on success.)
  bool focusOnClick(final DURuntime r, [final DURect? hitRect]) {
    final DURect h = hitRect ?? outerRect;
    final bool clicked = r.clicked(this, h);
    if (clicked) {
      r.focused = this;
    }
    return clicked;
  }

  /// Standard "pressable" semantics for button-like widgets.
  ///
  /// Rules:
  /// - Mouse: press inside -> down; release inside -> fire true (one frame)
  /// - Keyboard: focused + Enter press -> down; Enter release while focused -> fire
  ///
  /// Uses [hitRect] for mouse hit testing (defaults to [outerRect]).
  ///
  /// Call this from [interact] to populate [down] and [fire].
  void updatePressable(final DURuntime r, {final DURect? hitRect}) {
    // Per-frame outputs.
    fire = false;
    final DURect h = hitRect ?? outerRect;
    // Mouse click-to-focus + click detection on release-in-bounds.
    final bool clicked = focusOnClick(r, h);
    final bool focused = isFocused(r);
    // Mouse hold: active element + mouseDown.
    final bool mouseHoldingThis = identical(r.active, this) && r.mouseDown;
    // Keyboard hold: focused + Enter edge transitions.
    final bool enterDown = r.enter;
    final bool enterPressed = enterDown && !_prevEnterDown;
    final bool enterReleased = !enterDown && _prevEnterDown;
    _prevEnterDown = enterDown;
    if(focused && enterPressed) {
      _keyboardHeld = true;
    }
    // Down state.
    down = mouseHoldingThis || _keyboardHeld;
    // Fire on valid release.
    if(clicked) {
      fire = true;
    }
    if(_keyboardHeld && enterReleased) {
      _keyboardHeld = false;
      if (focused) {
        fire = true;
      }
    }
    // If focus is lost, drop keyboard hold.
    if(!focused) {
      _keyboardHeld = false;
      down = mouseHoldingThis;
    }
  }

  /// Convenience: toggle a boolean state on [fire].
  bool toggleOnFire(final bool value) => fire ? !value : value;

  /// Clears press state. Useful if a widget becomes disabled.
  void resetPressable() {
    down = false;
    fire = false;
    _keyboardHeld = false;
    _prevEnterDown = false;
  }

  /// Returns the proper frame color based on focus.
  DUIColor frameColor(final DURuntime r) => isFocused(r) ? theme.frameFocused : theme.frame;

  /// A sensible default "face" color for pressable widgets.
  ///
  /// If you want different behavior, override your own choice in your element.
  DUIColor faceColor(final DURuntime r) {
    final bool focused = isFocused(r);
    if(down) {
      return focused ? theme.buttonDownFocused : theme.buttonDown;
    }
    return focused ? theme.buttonFocused : theme.button;
  }

  /// Draws a frame if [border] is enabled.
  void drawFrameIfNeeded(final DURenderer p, final DURuntime r, {final String? title}) {
    if(!border) return;
    final DUIColor frame = frameColor(r);
    p.drawFrame(
      outerRect,
      title: title ?? borderLabel,
      frameFg: frame.fgClamped,
      frameBg: frame.bgClamped,
    );
  }

  /// Fills the entire [rect] area with a glyph + color.
  void fillRect(
    final DURenderer p,
    final DURect rect, {
    required final int glyph,
    required final DUIColor color,
  }) {
    for(int y = rect.top; y < rect.bottom; y++) {
      for(int x = rect.left; x < rect.right; x++) {
        p.draw(
          x,
          y,
          glyph,
          fg: color.fgClamped,
          bg: color.bgClamped,
          bold: color.bold,
        );
      }
    }
  }

  /// Fills the content area with spaces using [color].
  void fillContent(final DURenderer p, final DUIColor color) {
    final DURect c = contentRect;
    if (c.width <= 0 || c.height <= 0) return;
    fillRect(p, c, glyph: 0x20, color: color);
  }

  /// Draws a single line of text, clipped to [rect] width.
  void drawTextLine(
    final DURenderer p,
    final DURect rect,
    final String text, {
    required final int y,
    required final int x,
    required final DUIColor color,
  }) {
    final int w = rect.width;
    if (w <= 0) return;
    final int len = math.min(w, text.length);
    for (int i = 0; i < len; i++) {
      final int px = x + i;
      if (px < rect.left || px >= rect.right) continue;
      p.draw(
        px,
        y,
        text.codeUnitAt(i),
        fg: color.fgClamped,
        bg: color.bgClamped,
        bold: color.bold,
      );
    }
  }

  /// Draws a centered label inside [contentRect].
  ///
  /// If the available height is even, it renders:
  /// [label]
  /// ------
  /// so the label "looks" vertically centered.
  void drawCenteredLabel(
    final DURenderer p,
    final String label, {
    required final DUIColor color,
  }) {
    final DURect c = contentRect;
    final int w = c.width;
    final int h = c.height;
    if(w <= 0 || h <= 0) return;
    final String capped = (label.length <= w) ? label : label.substring(0, w);
    final int startX = c.left + math.max(0, (w - capped.length) ~/ 2);
    final bool evenRows = (h % 2) == 0;
    final int labelY = evenRows ? (c.top + (h ~/ 2) - 1) : (c.top + (h ~/ 2));
    // Label row.
    drawTextLine(p, c, capped, y: labelY, x: startX, color: color);
    // Underline row when even height.
    if(evenRows) {
      final int lineY = labelY + 1;
      if(lineY >= c.top && lineY < c.bottom) {
        for(int i = 0; i < capped.length; i++) {
          final int px = startX + i;
          if(px < c.left || px >= c.right) continue;
          p.draw(
            px,
            lineY,
            '─'.codeUnitAt(0),
            fg: color.fgClamped,
            bg: color.bgClamped,
            bold: color.bold,
          );
        }
      }
    }
  }
}

/// Key repeat helper for “held” key states.
///
/// Behavior:
/// - Fires immediately on first press.
/// - Then repeats after [initialDelayMs].
/// - Then repeats every [repeatEveryMs] while held.
final class DURepeat {
  bool _wasDown = false;
  int _nextAt = 0;
  bool consume(
    final bool isDown,
    final int nowMs, {
    final int initialDelayMs = 350,
    final int repeatEveryMs = 50,
  }) {
    if(!isDown) {
      _wasDown = false;
      _nextAt = 0;
      return false;
    }
    if(!_wasDown) {
      _wasDown = true;
      _nextAt = nowMs + initialDelayMs;
      return true;
    }
    if(nowMs >= _nextAt) {
      _nextAt = nowMs + repeatEveryMs;
      return true;
    }
    return false;
  }
}
