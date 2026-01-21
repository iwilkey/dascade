/// A focusable, interactable button in Dascade UI.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/color.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// A focusable, interactable button. See example/ui/button.dart for usage.
final class DUButton implements DUElement {

  /// Button label rendered inside the button.
  final String label;

  /// Whether to draw a border frame around the button.
  final bool border;

  /// Theme for consistent widget styling.
  final DUITheme theme;

  /// True while the button is being held down this frame.
  bool down = false;

  /// True for exactly one frame when the button is released inside its bounds.
  bool fire = false;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  bool _prevEnterDown = false;
  bool _keyboardHeld = false;

  DUButton({
    required this.label,
    this.border = true,
    this.theme = DUITheme.defaultTheme,
  });

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  DURect get _contentRect => border ? _rect.inset(1) : _rect;

  @override
  void interact(final DURuntime r) {
    // Per-frame outputs.
    fire = false;
    // Focus on click (mouse).
    final bool clicked = r.clicked(this, _rect);
    if(clicked) {
      r.focused = this;
    }
    final bool focused = (r.focused == this);
    // Mouse press/hold logic:
    // - r.clicked() sets active on press, focuses on release-in-bounds.
    // - We compute "down" based on being active + mouseDown.
    final bool mouseHoldingThis = (r.active == this) && r.mouseDown;
    // Keyboard press/hold logic:
    // - When focused, Enter press -> begin hold.
    // - Enter release -> fire (if still focused and hovered or just focused by click?).
    final bool enterDown = r.d.enter;
    final bool enterPressed = enterDown && !_prevEnterDown;
    final bool enterReleased = !enterDown && _prevEnterDown;
    _prevEnterDown = enterDown;
    if(focused && enterPressed) {
      _keyboardHeld = true;
    }
    // Down state is true if either mouse is holding us or keyboard is holding us.
    down = mouseHoldingThis || _keyboardHeld;
    // Fire on release:
    // - Mouse: when mouseReleased AND we were active AND released inside rect.
    // - Keyboard: when enterReleased AND we were keyboardHeld AND still focused.
    //
    // For mouse, r.clicked(...) already verifies "pressed then released inside".
    if(clicked) {
      fire = true;
    }
    if(_keyboardHeld && enterReleased) {
      _keyboardHeld = false;
      // Requirement: fire iff key goes UP after pressing AND still within bounds.
      // For keyboard, "within bounds" is interpreted as "still focused" (since
      // keyboard activation uses focus rather than pointer position).
      if(focused) {
        fire = true;
      }
    }
    // If we lose focus, drop keyboard hold.
    if(!focused) {
      _keyboardHeld = false;
      // If we aren't active via mouse either, ensure down is false.
      down = mouseHoldingThis;
    }
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    final bool focused = (r.focused == this);
    // Pick style strictly from theme.
    final DUIColor face = down
      ? (focused ? theme.buttonDownFocused : theme.buttonDown)
      : (focused ? theme.buttonFocused : theme.button);
    // Border/frame uses theme frame colors.
    if(border) {
      final DUIColor frameStyle = focused ? theme.frameFocused : theme.frame;
      p.drawFrame(
        _rect,
        title: null,
        frameFg: frameStyle.fgClamped,
        frameBg: frameStyle.bgClamped,
      );
    }
    // Clear content to face bg (and face fg for spaces).
    _clearContent(p, c, fg: face.fgClamped, bg: face.bgClamped, bold: face.bold);
    // Center label (best-effort, clip-safe).
    final int w = c.width;
    final int h = c.height;
    if(w <= 0 || h <= 0) return;
    final String capped = (label.length <= w) ? label : label.substring(0, w);
    final int startX = (c.left + math.max(0, (w - capped.length) ~/ 2)).floor();
    // If vertical space is even, draw:
    // [label]
    // ------
    // so the label "looks" vertically centered.
    final bool evenRows = (h % 2) == 0;
    final int labelY = evenRows ? (c.top + (h ~/ 2) - 1) : (c.top + (h ~/ 2));
    // Label row.
    for(int i = 0; i < capped.length; i++) {
      final int x = startX + i;
      if(x < c.left || x >= c.right) continue;
      p.draw(
        x,
        labelY,
        capped.codeUnitAt(i),
        fg: face.fgClamped,
        bg: face.bgClamped,
        bold: face.bold,
      );
    }
    // Underline row when we have even vertical space.
    if(evenRows) {
      final int lineY = labelY + 1;
      if(lineY >= c.top && lineY < c.bottom) {
        final int dashCount = capped.length;
        for(int i = 0; i < dashCount; i++) {
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
