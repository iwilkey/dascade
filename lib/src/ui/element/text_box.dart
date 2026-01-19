/// TODO: Dart docs.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/interaction/input.dart';
import 'package:dascade/src/ui/interaction/scroll.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';

final class DUTextBoxState {
  final List<String> lines;
  int cursorX = 0;
  int cursorY = 0;
  DUScrollState scroll = DUScrollState();
  DUTextBoxState(this.lines);
}

final class DUTextBoxElement implements DUElement {
  
  @override
  final int id;
  @override
  final DURect rect;

  final String? title;
  final List<String> initialLines;
  final bool border;
  final bool editable;

  DUTextBoxElement({
    required this.id,
    required this.rect,
    required this.title,
    required this.initialLines,
    required this.border,
    required this.editable,
  });

  DURect _contentRect() => border ? rect.inset(1) : rect;

  @override
  void interact(DUIRuntime r) {
    if (!editable) return;

    // This now works because clicked() sets active on press internally.
    if (r.clicked(id, rect)) {
      r.requestFocus(id);
    }

    if (!r.focused(id)) return;

    final DUTextBoxState st = r.state.getOrCreate<DUTextBoxState>(
      id,
      () => DUTextBoxState(List<String>.from(initialLines)),
    );

    final DURect c = _contentRect();

    // Scroll wheel support.
    r.applyScrollWheel(c, st.scroll, vertical: true, speed: 2);

    // Clamp scroll.
    final int contentHeight = math.max(1, st.lines.length);
    final int maxY = math.max(0, contentHeight - c.height);
    st.scroll.clamp(maxX: 0, maxY: maxY);

    // Key edges for editing.
    if (r.keyPressed(DUKey.backspace)) {
      _backspace(st);
      return;
    }
    if (r.keyPressed(DUKey.delete)) {
      _delete(st);
      return;
    }

    final String typed = r.typed;
    if (typed.isEmpty) return;

    final int code = typed.codeUnitAt(0);
    if (code == 10 || code == 13 || code == 9) return;

    _append(st, typed);
  }

  void _append(DUTextBoxState st, String s) {
    if (st.lines.isEmpty) st.lines.add('');
    st.lines[st.lines.length - 1] = st.lines.last + s;
  }

  void _backspace(DUTextBoxState st) {
    if (st.lines.isEmpty) return;
    final String s = st.lines.last;
    if (s.isEmpty) return;
    st.lines[st.lines.length - 1] = s.substring(0, s.length - 1);
  }

  void _delete(DUTextBoxState st) {
    _backspace(st);
  }

  @override
  void render(DUIPainter p, DUIRuntime r) {
    final bool focused = editable && r.focused(id);

    final DUTextBoxState? st = editable
        ? r.state.getOrCreate<DUTextBoxState>(
            id,
            () => DUTextBoxState(List<String>.from(initialLines)),
          )
        : null;

    final List<String> lines = st?.lines ?? initialLines;

    if (border) {
      p.drawFrame(
        rect,
        title: title,
        frameFg: focused ? 51 : 15,
        titleFg: 51,
      );
    }

    final DURect c = _contentRect();

    p.pushClip(c);

    final int dy = st == null ? 0 : -st.scroll.y;
    p.pushOffset(0, dy);

    p.drawText(c, lines, fg: focused ? 51 : 15);

    p.popOffset();
    p.popClip();
  }
}
