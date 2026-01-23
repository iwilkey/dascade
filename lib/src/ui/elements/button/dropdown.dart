/// A collapsible selector element (1-of-many) for Dascade UI.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/color.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// A collapsible selector element (1-of-many).
final class DUDropdown implements DUElement {

  /// Label shown in the header (e.g. "Color").
  final String label;

  /// Options to select from. Must be non-empty.
  final List<String> options;

  /// Whether to draw a border frame around the dropdown.
  final bool border;

  /// Label of the border (if active.)
  final String? borderLabel;

  /// Theme for consistent element styling.
  final DUITheme theme;

  /// Current selected option index.
  int index;

  /// True while the header is being held down this frame.
  bool down = false;

  /// True for exactly one frame when selection changes.
  bool changed = false;

  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  bool _open = false;
  int _highlight = 0;

  // Header keyboard hold semantics (match button/radio).
  bool _prevEnterDown = false;
  bool _keyboardHeld = false;

  // List scrolling (in rows).
  int _scroll = 0;

  DUDropdown({
    required this.label,
    required this.options,
    required this.border,
    this.theme = DUITheme.defaultTheme,
    int initialIndex = 0,
    this.borderLabel
  }) : index = initialIndex {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'options must be non-empty.');
    }
    index = index.clamp(0, options.length - 1);
    _highlight = index;
  }

  /// Current selected option value.
  String value() => options[index];

  /// Whether the dropdown is currently open.
  bool open() => _open;

  /// Immediate-mode “show” hook (kept for API symmetry).
  ///
  /// You can call this each frame; it currently has no parameters because
  /// dropdown owns its internal state and options are fixed at construction.
  DUDropdown show() => this;

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
  }

  DURect get _contentRect => border ? _rect.inset(1) : _rect;

  DURect _headerRect(final DURect c) {
    if(c.height <= 0) {
      return DURect(upperLeft: c.upperLeft, lowerRight: c.upperLeft);
    }
    return DURect(
      upperLeft: DUPoint(x: c.left, y: c.top),
      lowerRight: DUPoint(x: c.right, y: c.top + 1),
    );
  }

  DURect _listRect(final DURect c) {
    if(c.height <= 1) {
      return DURect(upperLeft: c.upperLeft, lowerRight: c.upperLeft);
    }
    return DURect(
      upperLeft: DUPoint(x: c.left, y: c.top + 1),
      lowerRight: DUPoint(x: c.right, y: c.bottom),
    );
  }

  @override
  void interact(final DURuntime r) {
    changed = false;
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    final DURect header = _headerRect(c);
    final DURect list = _listRect(c);
    final bool headerClicked = r.clicked(this, header);
    if(headerClicked) {
      r.focused = this;
      _open = !_open;
      _keyboardHeld = false;
      if(_open) {
        _highlight = index;
        _ensureHighlightVisible(listHeight: list.height);
      }
    }
    final bool focused = (r.focused == this);
    final bool mouseHoldingHeader = (r.active == this) && r.mouseDown;
    final bool enterDown = r.d.enter;
    final bool enterPressed = enterDown && !_prevEnterDown;
    final bool enterReleased = !enterDown && _prevEnterDown;
    _prevEnterDown = enterDown;
    if(focused && enterPressed) {
      _keyboardHeld = true;
    }
    down = mouseHoldingHeader || _keyboardHeld;
    if(_keyboardHeld && enterReleased) {
      _keyboardHeld = false;
      if(!focused) {
        // If we lost focus, cancel.
      } else if (!_open) {
        // Closed -> open.
        _open = true;
        _highlight = index;
        _ensureHighlightVisible(listHeight: list.height);
      } else {
        // Open -> select current highlight + close (standard dropdown behavior).
        if(_highlight != index) {
          index = _highlight;
          changed = true;
        }
        _open = false;
      }
    }
    // If not open, nothing else to do.
    if(!_open) {
      if (!focused) _keyboardHeld = false;
      down = mouseHoldingHeader || _keyboardHeld;
      return;
    }
    // When open:
    // - Escape closes without changing selection.
    if (focused && r.d.escape) {
      _open = false;
      return;
    }
    // Mouse wheel scrolls options when hovered over list.
    if(list.height > 0 && r.hovered(list) && r.wheel != 0) {
      _scroll += (-r.wheel) * 2;
      _clampScroll(listHeight: list.height);
    }
    // Keyboard navigation when focused: Up/Down changes highlight.
    if(focused && list.height > 0) {
      if(r.upPressed) {
        _highlight = (_highlight - 1).clamp(0, options.length - 1);
        _ensureHighlightVisible(listHeight: list.height);
      } else if(r.downPressed) {
        _highlight = (_highlight + 1).clamp(0, options.length - 1);
        _ensureHighlightVisible(listHeight: list.height);
      }
    }
    // Mouse selection: click-release inside an option row selects it.
    if(r.mouseReleased && list.height > 0 && r.hovered(list)) {
      final int localY = (r.my - list.top).clamp(0, list.height - 1);
      final int row = _scroll + localY;
      if(row >= 0 && row < options.length) {
        if (row != index) {
          index = row;
          changed = true;
        }
        _open = false;
      }
    }
    // Click outside closes (without changing selection).
    if(r.mousePressed && !header.contains(r.mx, r.my) && !list.contains(r.mx, r.my)) {
      _open = false;
    }
    // If focus is lost while open, close.
    if(!focused) {
      _open = false;
      _keyboardHeld = false;
      down = mouseHoldingHeader;
    }
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    final bool focused = (r.focused == this);
    // Choose face style from theme (reuse button palettes).
    final DUIColor face = down
      ? (focused ? theme.buttonDownFocused : theme.buttonDown)
      : (focused ? theme.buttonFocused : theme.button);
    // Frame style from theme.
    if(border) {
      final DUIColor frameStyle = focused ? theme.frameFocused : theme.frame;
      p.drawFrame(
        _rect,
        title: borderLabel,
        frameFg: frameStyle.fgClamped,
        frameBg: frameStyle.bgClamped,
      );
    }
    // Clear content to face.
    _clear(p, c, fg: face.fgClamped, bg: face.bgClamped, bold: face.bold);
    // Header.
    final DURect header = _headerRect(c);
    _renderHeader(p, header, face);
    // Option list.
    if(_open) {
      final DURect list = _listRect(c);
      if(list.width > 0 && list.height > 0) {
        _renderList(p, list, face);
      }
    }
  }

  void _renderHeader(final DURenderer p, final DURect header, final DUIColor face) {
    if(header.width <= 0 || header.height <= 0) return;
    final String arrow = _open ? '▲' : '▼';
    final String v = options[index];
    final String s = '$label: $v $arrow';
    final int n = math.min(header.width, s.length);
    final int y = header.top;
    for(int i = 0; i < n; i++) {
      p.draw(
        header.left + i,
        y,
        s.codeUnitAt(i),
        fg: face.fgClamped,
        bg: face.bgClamped,
        bold: face.bold,
      );
    }
  }

  void _renderList(final DURenderer p, final DURect list, final DUIColor face) {
    // Clip list to itself (still inside content, but this avoids bleed if callers clip oddly).
    p.pushClip(list);
    _clampScroll(listHeight: list.height);
    final int start = _scroll;
    final int end = math.min(options.length, start + list.height);
    for(int row = start; row < end; row++) {
      final int y = list.top + (row - start);
      final bool hi = (row == _highlight);
      final bool selected = (row == index);
      final DUIColor rowStyle = hi ? theme.cursor : face;
      // Prefix: selected gets "• " otherwise "  "
      final String prefix = selected ? '• ' : '  ';
      final int avail = list.width;
      final String opt = options[row];
      final int maxOpt = math.max(0, avail - prefix.length);
      final String clippedOpt = (opt.length <= maxOpt) ? opt : opt.substring(0, maxOpt);
      final String line = prefix + clippedOpt;
      // Fill whole row so highlight looks solid.
      for(int x = 0; x < avail; x++) {
        final int glyph = (x < line.length) ? line.codeUnitAt(x) : 0x20;
        p.draw(
          list.left + x,
          y,
          glyph,
          fg: rowStyle.fgClamped,
          bg: rowStyle.bgClamped,
          bold: rowStyle.bold,
        );
      }
    }
    p.popClip();
  }

  void _clear(
    final DURenderer p,
    final DURect r, {
    required final int fg,
    required final int bg,
    required final bool bold,
  }) {
    for(int y = r.top; y < r.bottom; y++) {
      for(int x = r.left; x < r.right; x++) {
        p.draw(x, y, 0x20, fg: fg, bg: bg, bold: bold);
      }
    }
  }

  void _clampScroll({required final int listHeight}) {
    if(listHeight <= 0) {
      _scroll = 0;
      return;
    }
    final int maxScroll = math.max(0, options.length - listHeight);
    _scroll = _scroll.clamp(0, maxScroll);
  }

  void _ensureHighlightVisible({required final int listHeight}) {
    if(listHeight <= 0) {
      _scroll = 0;
      return;
    }
    final int maxScroll = math.max(0, options.length - listHeight);
    if(_highlight < _scroll) {
      _scroll = _highlight.clamp(0, maxScroll);
    } else if (_highlight >= _scroll + listHeight) {
      _scroll = (_highlight - listHeight + 1).clamp(0, maxScroll);
    }
  }

}
