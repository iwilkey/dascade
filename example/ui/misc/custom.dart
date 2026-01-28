/// Demonstration of building custom UI elements by extending [DUCustomElement].
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dascade/dascade.dart';

Future<void> main() async {

  await Dascade.run((d) async {

    bool running = true;

    final DUTextBox log = DUTextBox(
      borderLabel: 'Log',
      initialText: 'Custom elements (extend DUCustomElement):\n'
          '- Click / Enter Stepper buttons\n'
          '- Watch progress animate\n',
      border: true,
      editable: false,
    );

    final DUStepper stepper = DUStepper(
      border: true,
      borderLabel: 'Stepper',
      min: 0,
      max: 99,
      value: 5,
    );

    final DUProgress progress = DUProgress(
      border: true,
      borderLabel: 'Progress',
    );

    int lastMs = DateTime.now().millisecondsSinceEpoch;
    int lastLoggedValue = stepper.value;

    while(running) {
      if(d.escape) running = false;
      d.beginFrame();
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int dt = now - lastMs;
      lastMs = now;
      progress.advance(dt);
      // Log stepper changes (no extra widget state beyond what we already have).
      if(stepper.value != lastLoggedValue) {
        log.text += '\nStepper value: ${stepper.value}';
        lastLoggedValue = stepper.value;
      }
      /// Your custom elements are DUElements, so they can (and should) be given to the layout engine just like
      /// any stock UI element!
      d.ui.root(
        d.ui.column(
          <DUElement>[log, stepper, progress],
          layout: DULayout.flex([2, 1, 1]),
          gap: 0,
          pad: 0,
        ),
      );
      d.endFrame();
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}

/// A small stepper custom element:
/// - Left half decrements, right half increments
/// - Focus + Enter acts like "increment"
final class DUStepper extends DUCustomElement {

  final int min;
  final int max;

  int value;

  DUStepper({
    required super.border,
    super.borderLabel,
    super.theme,
    required this.min,
    required this.max,
    required this.value,
  });

  // Two internal press regions (both still render within our rect).
  bool _downMinus = false;
  bool _downPlus = false;

  bool _fireMinus = false;
  bool _firePlus = false;

  // Track keyboard edge ourselves so Enter can mean "+1".
  bool _prevEnter = false;

  @override
  void interact(final DURuntime r) {
    // Keep overall focus semantics.
    focusOnClick(r, outerRect);

    _fireMinus = false;
    _firePlus = false;

    final DURect c = contentRect;
    if(c.width <= 0 || c.height <= 0) return;

    // Split hit rect into two halves.
    final int mid = c.left + (c.width ~/ 2);

    final DURect minusRect = DURect(
      upperLeft: DUPoint(x: c.left, y: c.top),
      lowerRight: DUPoint(x: mid, y: c.bottom),
    );

    final DURect plusRect = DURect(
      upperLeft: DUPoint(x: mid, y: c.top),
      lowerRight: DUPoint(x: c.right, y: c.bottom),
    );

    // Mouse "down" for each half is active+hovered.
    _downMinus = identical(r.active, this) && r.mouseDown && r.hovered(minusRect);
    _downPlus = identical(r.active, this) && r.mouseDown && r.hovered(plusRect);

    // Fire per-half on release inside that half.
    //
    // We use the runtime's clicked semantics for the *whole element* via focusOnClick,
    // but for sub-regions we do a small, local version:
    if(r.mousePressed && r.hovered(c)) {
      r.active = this;
    }
    if(r.mouseReleased && identical(r.active, this)) {
      if(r.hovered(minusRect)) _fireMinus = true;
      if(r.hovered(plusRect)) _firePlus = true;
    }
    // Keyboard: focused + Enter release increments.
    final bool enterDown = r.enter;
    final bool enterReleased = !enterDown && _prevEnter;
    _prevEnter = enterDown;
    if(isFocused(r) && enterReleased) {
      _firePlus = true;
    }
    if(_fireMinus) {
      value = math.max(min, value - 1);
    }
    if(_firePlus) {
      value = math.min(max, value + 1);
    }
    // For the base class "down" highlight, show down if either half is down.
    down = _downMinus || _downPlus;
    fire = _fireMinus || _firePlus;
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    drawFrameIfNeeded(p, r);
    final DURect c = contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    // Base face for background.
    final DUIColor baseFace = faceColor(r);
    fillContent(p, baseFace);
    // Determine sub-rects again for painting.
    final int mid = c.left + (c.width ~/ 2);
    final DURect minusRect = DURect(
      upperLeft: DUPoint(x: c.left, y: c.top),
      lowerRight: DUPoint(x: mid, y: c.bottom),
    );
    final DURect plusRect = DURect(
      upperLeft: DUPoint(x: mid, y: c.top),
      lowerRight: DUPoint(x: c.right, y: c.bottom),
    );
    // If a half is down, use "down" face for that half only.
    final DUIColor downFace = isFocused(r) ? theme.buttonDownFocused : theme.buttonDown;
    if(_downMinus) {
      fillRect(p, minusRect, glyph: 0x20, color: downFace);
    }
    if(_downPlus) {
      fillRect(p, plusRect, glyph: 0x20, color: downFace);
    }
    // Text color: use theme.text but keep background as face bg.
    final DUIColor textColor = DUIColor(
      fg: theme.text.fg,
      bg: baseFace.bg,
      bold: theme.text.bold,
    );
    // Draw: "[-]  NN  [+]" centered-ish.
    // Keep it simple: one centered label for whole content.
    final String label = '[-]  ${value.toString().padLeft(2, "0")}  [+]';
    drawCenteredLabel(p, label, color: textColor);
  }
}

/// A simple progress bar element.
/// - Uses only theme colors
/// - Animates by calling [advance] from the app loop
final class DUProgress extends DUCustomElement {

  int _ms = 0;

  DUProgress({
    required super.border,
    super.borderLabel,
    super.theme,
  });

  void advance(final int dtMs) {
    _ms += dtMs;
    if(_ms > 1 << 30) _ms = 0;
  }

  @override
  void interact(final DURuntime r) {
    focusOnClick(r, outerRect);
    down = false;
    fire = false;
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    drawFrameIfNeeded(p, r);
    final DURect c = contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    // Background face.
    final DUIColor face = isFocused(r) ? theme.buttonFocused : theme.button;
    fillContent(p, face);
    // Progress fraction (0..1).
    final double t = ((_ms % 2000) / 2000.0);
    final int fill = (c.width * t).floor().clamp(0, c.width);
    // Filled portion uses "down" style as an accent.
    final DUIColor fillColor = isFocused(r) ? theme.buttonDownFocused : theme.buttonDown;
    final DURect filled = DURect(
      upperLeft: DUPoint(x: c.left, y: c.top),
      lowerRight: DUPoint(x: c.left + fill, y: c.bottom),
    );
    if(filled.width > 0) {
      fillRect(p, filled, glyph: 0x20, color: fillColor);
    }
    // Label shows percent.
    final int pct = (t * 100).round().clamp(0, 100);
    final DUIColor textColor = DUIColor(
      fg: theme.text.fg,
      bg: face.bg,
      bold: theme.text.bold,
    );
    drawCenteredLabel(p, 'Progress $pct%', color: textColor);
  }
}
