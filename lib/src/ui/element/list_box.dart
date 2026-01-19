/// TODO: Dart docs.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/interaction/scroll.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';

final class DUListBoxState {
  final DUScrollState scroll = DUScrollState();
}

final class DUListBoxElement implements DUElement {
  @override
  final int id;
  @override
  final DURect rect;

  final String title;
  final List<String> items;
  final bool border;

  DUListBoxElement({
    required this.id,
    required this.rect,
    required this.title,
    required this.items,
    required this.border,
  });

  DURect _contentRect() => border ? rect.inset(1) : rect;

  @override
  void interact(DUIRuntime r) {
    // Hot support so "click outside clears focus" works as expected.
    if (r.hovered(rect)) {
      r.interaction.hot = id;
    }

    final DUListBoxState st = r.state.getOrCreate<DUListBoxState>(
      id,
      () => DUListBoxState(),
    );

    final DURect c = _contentRect();

    // Scroll wheel only when hovered (applyScrollWheel already checks hover).
    r.applyScrollWheel(c, st.scroll, vertical: true, speed: 2);

    // Clamp scroll to content.
    final int visible = math.max(0, c.height);
    final int maxY = math.max(0, items.length - visible);
    st.scroll.clamp(maxX: 0, maxY: maxY);
  }

  @override
  void render(DUIPainter p, DUIRuntime r) {
    if (border) {
      final bool focused = r.focused(id);
      p.drawFrame(
        rect,
        title: title,
        frameFg: focused ? 51 : 15,
        titleFg: 51,
      );
    }

    final DURect c = _contentRect();
    if (c.width <= 0 || c.height <= 0) return;

    final DUListBoxState st = r.state.getOrCreate<DUListBoxState>(
      id,
      () => DUListBoxState(),
    );

    final int start = st.scroll.y.clamp(0, math.max(0, items.length));
    final int end = (start + c.height).clamp(0, items.length);
    final List<String> window = items.sublist(start, end);

    p.pushClip(c);
    p.drawText(c, window);
    p.popClip();
  }
}