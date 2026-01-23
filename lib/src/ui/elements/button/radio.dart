/// A focusable, interactable radio element in Dascade UI.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/color.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// A focusable, interactable radio element. See example/ui/radio.dart for usage.
final class DURadio implements DUElement {

  /// Radio label rendered inside the element.
  final String label;

  /// Whether to draw a border frame around the element.
  final bool border;

  /// Theme for consistent element styling.
  final DUITheme theme;
  
  /// The text to render at the upper left hand corner of the border (if it's active.)
  final String? borderLabel;

  /// Persistent checked state.
  bool state = false;

  /// True while the element is being held down this frame.
  bool down = false;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  bool _prevEnterDown = false;
  bool _keyboardHeld = false;

  DURadio({
    required this.label,
    required this.border,
    required this.state,
    this.theme = DUITheme.defaultTheme,
    this.borderLabel
  });

  /// Returns the current checked state (immediate-mode read).
  bool value() => state;

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  DURect get _contentRect => border ? _rect.inset(1) : _rect;

  @override
  void interact(final DURuntime r) {
    final bool clicked = r.clicked(this, _rect);
    if(clicked) {
      r.focused = this;
    }
    final bool focused = (r.focused == this);
    final bool mouseHoldingThis = (r.active == this) && r.mouseDown;
    final bool enterDown = r.d.enter;
    final bool enterPressed = enterDown && !_prevEnterDown;
    final bool enterReleased = !enterDown && _prevEnterDown;
    _prevEnterDown = enterDown;
    if(focused && enterPressed) {
      _keyboardHeld = true;
    }
    down = mouseHoldingThis || _keyboardHeld;
    if(clicked) {
      state = !state;
    }
    if(_keyboardHeld && enterReleased) {
      _keyboardHeld = false;
      if(focused) {
        state = !state;
      }
    }
    if(!focused) {
      _keyboardHeld = false;
      down = mouseHoldingThis;
    }
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    final bool focused = (r.focused == this);
    final DUIColor face = down
      ? (focused ? theme.buttonDownFocused : theme.buttonDown)
      : (focused ? theme.buttonFocused : theme.button);
    // Frame.
    if(border) {
      final DUIColor frameStyle = focused ? theme.frameFocused : theme.frame;
      p.drawFrame(
        _rect,
        title: borderLabel,
        frameFg: frameStyle.fgClamped,
        frameBg: frameStyle.bgClamped,
      );
    }
    _clearContent(p, c, fg: face.fgClamped, bg: face.bgClamped, bold: face.bold);
    final int w = c.width;
    final int h = c.height;
    if(w <= 0 || h <= 0) return;
    // Build "[x] " prefix + label (clipped).
    final String mark = state ? '[x] ' : '[ ] ';
    final int maxLabel = math.max(0, w - mark.length);
    final String lab = (label.length <= maxLabel) ? label : label.substring(0, maxLabel);
    final String full = mark + lab;
    final int startX = c.left + math.max(0, (w - full.length) ~/ 2);
    // Same vertical centering trick as button:
    // If even rows, draw underline row to make the label look centered.
    final bool evenRows = (h % 2) == 0;
    final int labelY = evenRows ? (c.top + (h ~/ 2) - 1) : (c.top + (h ~/ 2));
    // Label row.
    final int len = math.min(w, full.length);
    for(int i = 0; i < len; i++) {
      final int x = startX + i;
      if(x < c.left || x >= c.right) continue;
      p.draw(
        x,
        labelY,
        full.codeUnitAt(i),
        fg: face.fgClamped,
        bg: face.bgClamped,
        bold: face.bold,
      );
    }
    // Underline row when we have even vertical space.
    if(evenRows) {
      final int lineY = labelY + 1;
      if(lineY >= c.top && lineY < c.bottom) {
        for(int i = 0; i < len; i++) {
          final int x = startX + i;
          if(x < c.left || x >= c.right) continue;
          p.draw(
            x,
            lineY,
            '─'.codeUnitAt(0),
            fg: face.fgClamped,
            bg: face.bgClamped,
            bold: face.bold,
          );
        }
      }
    }
  }

  void _clearContent(
    final DURenderer p,
    final DURect c, {
    required final int fg,
    required final int bg,
    required final bool bold,
  }) {
    for(int y = c.top; y < c.bottom; y++) {
      for(int x = c.left; x < c.right; x++) {
        p.draw(x, y, 0x20, fg: fg, bg: bg, bold: bold);
      }
    }
  }

}
