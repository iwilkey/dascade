/// A multi-line editable or read-only text box widget for Dascade UI.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/style/color.dart';
import 'package:dascade/src/ui/style/theme.dart';

/// A multi-line editable or read-only text box widget for Dascade UI. 
/// 
/// See example/ui/textbox.dart for usage.
final class DUTextBox implements DUElement {

  /// Whether to draw a border frame around the textbox.
  final bool border;

  /// Whether the textbox can be edited (receives input mutations).
  ///
  /// Non-editable boxes can still focus, scroll, and move the caret.
  final bool editable;

  /// The text to render at the upper left hand corner of the border (if it's active.)
  final String? borderLabel;

  /// Theme for consistent widget styling.
  final DUITheme theme;

  /// Current lines of text.
  final List<_DUTextLine> _lines = <_DUTextLine>[];

  final _DURepeat _repLeft = _DURepeat();
  final _DURepeat _repRight = _DURepeat();
  final _DURepeat _repUp = _DURepeat();
  final _DURepeat _repDown = _DURepeat();
  final _DURepeat _repHome = _DURepeat();
  final _DURepeat _repEnd = _DURepeat();
  final _DURepeat _repPageUp = _DURepeat();
  final _DURepeat _repPageDown = _DURepeat();
  final _DURepeat _repBackspace = _DURepeat();
  final _DURepeat _repDelete = _DURepeat();

  /// The text content inside the box.
  String text;

  /// The rectangle occupied by this element (updated by layout()).
  DURect _rect = DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: 0, y: 0),
  );

  /// Cursor position (caret) in [text], as a code-unit index.
  int _cursor = 0;

  /// Preferred visual column when moving vertically (up/down).
  int _desiredCol = 0;

  /// Top-most visible wrapped line index.
  int _scrollLine = 0;

  /// Tracks whether we were focused last frame (to detect focus transitions).
  bool _wasFocused = false;

  /// Cursor blink phase offset (ms). Bumped to force caret visible immediately.
  int _blinkPhaseMs = 0;

  /// Wrap patch for word wrapping.
  bool _wrapDirty = true;

  /// Word wrap width cache.
  int _cachedWrapWidth = -1;

  /// Cached text (used for wrap caching).
  String _cachedText = '';

  /// Cached text for non-editable auto-scroll (separate from wrap caching).
  String _autoScrollCachedText = '';

  /// Enter is edge-triggered (no repeat).
  bool _prevEnterDown = false;

  DUTextBox({
    required String initialText,
    required this.border,
    required this.editable,
    this.theme = DUITheme.defaultTheme,
    this.borderLabel
  }) : text = initialText {
    _cursor = text.length;
    _desiredCol = 1 << 30;
    _autoScrollCachedText = initialText;
  }

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
    _clampCursor();
  }

  DURect get _contentRect => border ? _rect.inset(1) : _rect;

  @override
  void interact(final DURuntime r) {
    // Click-to-focus always (editable or not).
    if(r.clicked(this, _rect)) {
      r.focused = this;
    }
    final bool focused = (r.focused == this);
    // Focus transition handling (snap caret to end).
    if(focused && !_wasFocused) {
      _cursor = text.length;
      _desiredCol = 1 << 30;
      _resetCursorBlink();
      final DURect c0 = _contentRect;
      if(c0.width > 0 && c0.height > 0) {
        _rebuildWrapIfNeeded(c0.width);
        _ensureCursorVisible(viewHeight: c0.height);
      }
    }
    _wasFocused = focused;
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    // Wrap model may be needed for scrolling/clamping.
    _rebuildWrapIfNeeded(c.width);
    // Mouse wheel scroll when hovered (focus not required).
    if(r.hovered(c) && r.wheel != 0) {
      _scrollBy((-r.wheel) * 2, viewHeight: c.height);
    }
    // Keyboard interactions only when focused.
    if(!focused) return;
    final d = r.d;
    final int now = DateTime.now().millisecondsSinceEpoch;
    // Page scrolling works regardless of editable.
    bool didNav = false;
    if(_repPageUp.consume(d.pageUp, now)) {
      _scrollBy(-c.height, viewHeight: c.height);
      didNav = true;
    }
    if(_repPageDown.consume(d.pageDown, now)) {
      _scrollBy(c.height, viewHeight: c.height);
      didNav = true;
    }
    // Caret navigation works regardless of editable.
    if(_repLeft.consume(d.left, now)) {
      _moveLeft();
      didNav = true;
    }
    if(_repRight.consume(d.right, now)) {
      _moveRight();
      didNav = true;
    }
    if(_repUp.consume(d.up, now)) {
      _moveUp(c.width);
      didNav = true;
    }
    if(_repDown.consume(d.down, now)) {
      _moveDown(c.width);
      didNav = true;
    }
    if(_repHome.consume(d.home, now)) {
      _moveHome(c.width);
      didNav = true;
    }
    if(_repEnd.consume(d.end, now)) {
      _moveEnd(c.width);
      didNav = true;
    }
    if(didNav) {
      _rebuildWrapIfNeeded(c.width);
      _resetCursorBlink();
      _ensureCursorVisible(viewHeight: c.height);
      return;
    }
    // From here on: mutations are gated by editable.
    if(!editable) return;
    if (_repBackspace.consume(d.backspace, now)) {
      _backspace();
      _resetCursorBlink();
      _rebuildWrapIfNeeded(c.width);
      _ensureCursorVisible(viewHeight: c.height);
      return;
    }
    if(_repDelete.consume(d.delete, now)) {
      _deleteForward();
      _resetCursorBlink();
      _rebuildWrapIfNeeded(c.width);
      _ensureCursorVisible(viewHeight: c.height);
      return;
    }
    final bool enterDown = d.enter;
    final bool enterPressed = enterDown && !_prevEnterDown;
    _prevEnterDown = enterDown;
    if(enterPressed) {
      _insert('\n');
      _resetCursorBlink();
      _desiredCol = _cursorVisualCol(c.width);
      _rebuildWrapIfNeeded(c.width);
      _ensureCursorVisible(viewHeight: c.height);
      return;
    }
    final String t = r.typed;
    if(t.isEmpty) return;
    // Basic filter: ignore control chars. (Enter handled above.)
    final int code = t.codeUnitAt(0);
    if(code < 32) return;
    _insert(t);
    _resetCursorBlink();
    _desiredCol = _cursorVisualCol(c.width);
    _rebuildWrapIfNeeded(c.width);
    _ensureCursorVisible(viewHeight: c.height);
  }

  @override
  void render(final DURenderer p, final DURuntime r) {
    final DURect c = _contentRect;
    final bool focused = (r.focused == this);
    if(border) {
      final DUIColor frameStyle = focused ? theme.frameFocused : theme.frame;
      final String bt = borderLabel == null ? (editable ? 'Text Box' : 'Text Box (Read Only)') : borderLabel!;
      p.drawFrame(
        _rect,
        title: bt,
        frameFg: frameStyle.fgClamped,
        frameBg: frameStyle.bgClamped,
      );
    }
    if(c.width <= 0 || c.height <= 0) return;
    // Keep wrap cache fresh for current width.
    _rebuildWrapIfNeeded(c.width);
    // Auto-scroll in non-editable mode when text changes.
    if(!editable && text != _autoScrollCachedText) {
      _autoScrollCachedText = text;
      final int maxScroll = math.max(0, _lines.length - c.height);
      _scrollLine = maxScroll;
    }
    // Clear the content area (important: renderText only draws glyphs it touches).
    _clearContent(p, c, fg: theme.text.fgClamped, bg: theme.text.bgClamped);
    // Determine visible window.
    final int maxScroll = math.max(0, _lines.length - c.height);
    _scrollLine = _scrollLine.clamp(0, maxScroll);
    final int start = _scrollLine;
    final int end = math.min(_lines.length, start + c.height);
    int y = c.top;
    for(int i = start; i < end; i++) {
      final _DUTextLine line = _lines[i];
      _renderLine(
        p,
        c.left,
        y,
        c.width,
        line.text,
        fg: theme.text.fgClamped,
        bg: theme.text.bgClamped,
        bold: theme.text.bold,
      );
      y += 1;
    }
    // Cursor (caret) with blink when focused and editable.
    if(focused && editable) {
      final bool blinkOn = _blinkOn();
      if(blinkOn) {
        final _DUVisualPos pos = _cursorVisualPos(c.width);
        final int lineIndex = pos.line;
        final int col = pos.col;
        if(lineIndex >= start && lineIndex < end) {
          final int cx = c.left + col;
          final int cy = c.top + (lineIndex - start);
          if(cx >= c.left && cx < c.right && cy >= c.top && cy < c.bottom) {
            final _DUTextLine ln = _lines[lineIndex];
            final int glyph = (col >= 0 && col < ln.text.length)
              ? ln.text.codeUnitAt(col)
              : 0x20;
            p.draw(
              cx,
              cy,
              glyph,
              fg: theme.cursor.fgClamped,
              bg: theme.cursor.bgClamped,
              bold: theme.cursor.bold,
            );
          }
        }
      }
    }
  }

  void _clearContent(
    final DURenderer p,
    final DURect c, {
    required final int fg,
    required final int bg,
  }) {
    for(int y = c.top; y < c.bottom; y++) {
      for(int x = c.left; x < c.right; x++) {
        p.draw(x, y, 0x20, fg: fg, bg: bg);
      }
    }
  }

  void _renderLine(
    final DURenderer p,
    final int x,
    final int y,
    final int width,
    final String s, {
    required final int fg,
    required final int bg,
    required final bool bold,
  }) {
    final int len = math.min(width, s.length);
    for(int i = 0; i < len; i++) {
      p.draw(x + i, y, s.codeUnitAt(i), fg: fg, bg: bg, bold: bold);
    }
  }

  bool _blinkOn() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int t = now - _blinkPhaseMs;
    return ((t ~/ 500) % 2) == 0;
  }

  void _clampCursor() {
    _cursor = _cursor.clamp(0, text.length);
    _desiredCol = _desiredCol.clamp(0, 1 << 30);
  }

  void _markDirty() {
    _wrapDirty = true;
  }

  void _insert(final String s) {
    if(s.isEmpty) return;
    _cursor = _cursor.clamp(0, text.length);
    text = text.substring(0, _cursor) + s + text.substring(_cursor);
    _cursor += s.length;
    _markDirty();
  }

  void _backspace() {
    if(_cursor <= 0 || text.isEmpty) return;
    _cursor = _cursor.clamp(0, text.length);
    text = text.substring(0, _cursor - 1) + text.substring(_cursor);
    _cursor -= 1;
    _markDirty();
  }

  void _deleteForward() {
    if(_cursor >= text.length || text.isEmpty) return;
    _cursor = _cursor.clamp(0, text.length);
    text = text.substring(0, _cursor) + text.substring(_cursor + 1);
    _markDirty();
  }

  void _moveLeft() {
    if(_cursor > 0) _cursor -= 1;
    _desiredCol = 1 << 30;
  }

  void _moveRight() {
    if(_cursor < text.length) _cursor += 1;
    _desiredCol = 1 << 30;
  }

  void _moveUp(final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    final _DUVisualPos pos = _cursorVisualPos(wrapWidth);
    final int curLine = pos.line;
    final int curCol = pos.col;
    if(_desiredCol == (1 << 30)) _desiredCol = curCol;
    final int targetLine = math.max(0, curLine - 1);
    _setCursorByVisual(targetLine, _desiredCol, wrapWidth);
  }

  void _resetCursorBlink() {
    _blinkPhaseMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _moveDown(final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    final _DUVisualPos pos = _cursorVisualPos(wrapWidth);
    final int curLine = pos.line;
    final int curCol = pos.col;
    if (_desiredCol == (1 << 30)) _desiredCol = curCol;
    final int targetLine = math.min(_lines.length - 1, curLine + 1);
    _setCursorByVisual(targetLine, _desiredCol, wrapWidth);
  }

  void _moveHome(final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    final _DUVisualPos pos = _cursorVisualPos(wrapWidth);
    _setCursorByVisual(pos.line, 0, wrapWidth);
    _desiredCol = 0;
  }

  void _moveEnd(final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    final _DUVisualPos pos = _cursorVisualPos(wrapWidth);
    final int lineLen = _lines[pos.line].text.length;
    _setCursorByVisual(pos.line, lineLen, wrapWidth);
    _desiredCol = lineLen;
  }

  void _scrollBy(final int delta, {required final int viewHeight}) {
    if(_lines.isEmpty) return;
    final int maxScroll = math.max(0, _lines.length - viewHeight);
    _scrollLine = (_scrollLine + delta).clamp(0, maxScroll);
  }

  void _ensureCursorVisible({required final int viewHeight}) {
    if(_lines.isEmpty) return;
    final _DUVisualPos pos = _cursorVisualPos(_cachedWrapWidth);
    final int line = pos.line;
    final int maxScroll = math.max(0, _lines.length - viewHeight);
    if(line < _scrollLine) {
      _scrollLine = line.clamp(0, maxScroll);
    } else if (line >= _scrollLine + viewHeight) {
      _scrollLine = (line - viewHeight + 1).clamp(0, maxScroll);
    }
  }

  void _rebuildWrapIfNeeded(final int wrapWidth) {
    if(wrapWidth <= 0) {
      _cachedWrapWidth = wrapWidth;
      _cachedText = text;
      _lines.clear();
      if(text.isEmpty) {
        _lines.add(const _DUTextLine(text: '', start: 0, endExclusive: 0));
        _clampCursor();
        return;
      }
      return;
    }
    if(!_wrapDirty && _cachedWrapWidth == wrapWidth && _cachedText == text) {
      return;
    }
    _cachedWrapWidth = wrapWidth;
    _cachedText = text;
    _wrapDirty = false;
    _lines.clear();
    final String s = text;
    int lineStart = 0;
    int lineLen = 0;
    int lastBreakTextIndex = -1;
    int i = 0;
    while(true) {
      final bool atEnd = (i >= s.length);
      final int ch = atEnd ? -1 : s.codeUnitAt(i);
      if(atEnd || ch == 0x0A) {
        _addLineFromRange(lineStart, i);
        if(atEnd) break;
        i += 1;
        lineStart = i;
        lineLen = 0;
        lastBreakTextIndex = -1;
        continue;
      }
      if(lineLen < wrapWidth) {
        lineLen += 1;
        if(_isBreakChar(ch)) {
          lastBreakTextIndex = i;
        }
        i += 1;
        continue;
      }
      if(lastBreakTextIndex != -1 && lastBreakTextIndex >= lineStart) {
        _addLineFromRange(lineStart, lastBreakTextIndex);
        int j = lastBreakTextIndex;
        while (j < s.length) {
          final int cch = s.codeUnitAt(j);
          if (!_isBreakChar(cch)) break;
          j += 1;
        }
        lineStart = j;
        lineLen = 0;
        lastBreakTextIndex = -1;
        i = lineStart;
        continue;
      }
      _addLineFromRange(lineStart, i);
      lineStart = i;
      lineLen = 0;
      lastBreakTextIndex = -1;
    }
    if(_lines.isEmpty) {
      _lines.add(const _DUTextLine(text: '', start: 0, endExclusive: 0));
    }
    _clampCursor();
  }

  bool _isBreakChar(final int ch) {
    return ch == 0x20 /* space */ || ch == 0x09 /* tab */;
  }

  void _addLineFromRange(final int start, final int endExclusive) {
    final int a = start.clamp(0, text.length);
    final int b = endExclusive.clamp(0, text.length);
    final String slice = (b >= a) ? text.substring(a, b) : '';
    _lines.add(_DUTextLine(text: slice, start: a, endExclusive: b));
  }

  _DUVisualPos _cursorVisualPos(final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    final int idx = _cursor.clamp(0, text.length);
    for (int li = 0; li < _lines.length; li++) {
      final _DUTextLine ln = _lines[li];
      if (idx < ln.start) continue;
      if (idx > ln.endExclusive) continue;
      final int col = (idx - ln.start).clamp(0, ln.text.length);
      return _DUVisualPos(line: li, col: col);
    }
    final int last = _lines.length - 1;
    final _DUTextLine ln = _lines[last];
    return _DUVisualPos(line: last, col: (idx - ln.start).clamp(0, ln.text.length));
  }

  int _cursorVisualCol(final int wrapWidth) => _cursorVisualPos(wrapWidth).col;

  void _setCursorByVisual(final int line, final int col, final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    if(_lines.isEmpty) {
      _cursor = 0;
      return;
    }
    final int li = line.clamp(0, _lines.length - 1);
    final _DUTextLine ln = _lines[li];
    final int c = col.clamp(0, ln.text.length);
    _cursor = (ln.start + c).clamp(0, text.length);
  }
}

/// Internal helper for TextBox element. No dart docs on this since it's not something
/// anyone should mess with.
final class _DUTextLine {
  final String text;
  final int start;
  final int endExclusive;
  const _DUTextLine({
    required this.text,
    required this.start,
    required this.endExclusive,
  });
}

/// Internal helper for TextBox element. No dart docs on this since it's not something
/// anyone should mess with.
final class _DUVisualPos {
  final int line;
  final int col;
  const _DUVisualPos({required this.line, required this.col});
}

/// Key repeat helper for “held” key states.
///
/// Internal helper for TextBox element. No dart docs on this since it's not something
/// anyone should mess with.
final class _DURepeat {
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
