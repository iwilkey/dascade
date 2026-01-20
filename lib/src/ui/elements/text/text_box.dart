/// A multi-line editable or read-only text box widget for Dascade UI.
library;

import 'dart:math' as math;

import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';

/// A multi-line editable or read-only text box widget for Dascade UI.
///
/// Features:
/// - Multi-line text (Enter inserts newline)
/// - Word-wrapping (prefers breaking at spaces; hard-breaks long words)
/// - Scrolling (mouse wheel + page up/down)
/// - Cursor (caret) with blink
/// - Arrow-key navigation (left/right/up/down) + home/end
/// - Backspace/delete editing with key-repeat
final class DUTextBox implements DUElement {
  
  /// Whether to draw a border frame around the textbox.
  final bool border;

  /// Whether the textbox can be edited (receives input).
  final bool editable;

  /// The text content inside the box.
  String text;

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

  /// Cached text.
  String _cachedText = '';

  /// Enter is edge-triggered (no repeat).
  bool _prevEnterDown = false;

  DUTextBox({
    required String initialText,
    required this.border,
    required this.editable,
  }) : text = initialText {
    _cursor = text.length;
    _desiredCol = 1 << 30;
  }

  @override
  DURect get rect => _rect;

  @override
  void layout(final DURect rect) {
    _rect = rect;
    // Clamp cursor if the user externally changed `text`.
    _clampCursor();
  }

  DURect get _contentRect => border ? _rect.inset(1) : _rect;

  @override
  void interact(final DUIRuntime r) {
    if(!editable) return;
    // Click-to-focus behavior.
    if(r.clicked(this, _rect)) {
      r.focused = this;
    }
    final bool focused = (r.focused == this);
    // Focus transition handling (snap caret to end).
    if(focused && !_wasFocused) {
      // Always snap to end when focus is gained (requested behavior).
      // If you only want this on the *first* focus, gate with _snapToEndOnNextFocus.
      _cursor = text.length;
      _desiredCol = 1 << 30;
      _resetCursorBlink();
      // Optional: when gaining focus, scroll to the caret immediately.
      final DURect c0 = _contentRect;
      if (c0.width > 0 && c0.height > 0) {
        _rebuildWrapIfNeeded(c0.width);
        _ensureCursorVisible(viewHeight: c0.height);
      }
    }
    _wasFocused = focused;
    if(!focused) return;
    final DURect c = _contentRect;
    if(c.width <= 0 || c.height <= 0) return;
    // Ensure wrap model exists before any navigation that depends on visual lines.
    _rebuildWrapIfNeeded(c.width);
    // Mouse wheel scroll (only when hovered over content).
    if(r.hovered(c) && r.wheel != 0) {
      _scrollBy((-r.wheel) * 2, viewHeight: c.height);
    }
    // Key input is read from the framework directly.
    final d = r.d;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if(_repBackspace.consume(d.backspace, now)) {
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
    bool didNav = false;
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
    if(_repPageUp.consume(d.pageUp, now)) {
      _scrollBy(-c.height, viewHeight: c.height);
      didNav = true;
    }
    if(_repPageDown.consume(d.pageDown, now)) {
      _scrollBy(c.height, viewHeight: c.height);
      didNav = true;
    }
    if(didNav) {
      _rebuildWrapIfNeeded(c.width);
      _resetCursorBlink();
      _ensureCursorVisible(viewHeight: c.height);
      return;
    }
    final String t = r.typed;
    if(t.isEmpty) return;
    // Basic filter: ignore control chars. (Enter is handled above.)
    final int code = t.codeUnitAt(0);
    if(code < 32) return;
    _insert(t);
    _resetCursorBlink();
    _desiredCol = _cursorVisualCol(c.width);
    _rebuildWrapIfNeeded(c.width);
    _ensureCursorVisible(viewHeight: c.height);
  }

  @override
  void render(final DUIRenderer p, final DUIRuntime r) {
    final DURect c = _contentRect;
    final bool focused = editable && (r.focused == this);
    if(border) {
      p.renderFrame(
        _rect,
        title: editable ? 'Text Box' : 'Text Box (Read Only)',
        frameFg: focused ? 51 : 15,
        frameBg: 0,
      );
    }
    if(c.width <= 0 || c.height <= 0) return;
    // Keep wrap cache fresh for current width.
    _rebuildWrapIfNeeded(c.width);
    // Clear the content area (important: renderText only draws glyphs it touches).
    _clearContent(p, c, fg: 15, bg: 0);
    // Determine visible window.
    final int maxScroll = math.max(0, _lines.length - c.height);
    _scrollLine = _scrollLine.clamp(0, maxScroll);
    final int start = _scrollLine;
    final int end = math.min(_lines.length, start + c.height);
    final int fg = focused ? 51 : 15;
    final int bg = 0;
    int y = c.top;
    for(int i = start; i < end; i++) {
      final _DUTextLine line = _lines[i];
      _renderLine(p, c.left, y, c.width, line.text, fg: fg, bg: bg);
      y += 1;
    }
    // Cursor (caret) with blink, only if focused and editable.
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
            // Render cursor as an inverted cell.
            //
            // IMPORTANT: Never “reuse” an old glyph when text is shorter/empty.
            // Only sample a glyph if the caret is within the current line text.
            final _DUTextLine ln = _lines[lineIndex];
            final int glyph = (col >= 0 && col < ln.text.length)
                ? ln.text.codeUnitAt(col)
                : 0x20; // space
            p.renderGlyph(
              cx,
              cy,
              glyph,
              fg: 0,
              bg: 51,
              bold: true,
            );
          }
        }
      }
    }
  }

  void _clearContent(
    final DUIRenderer p,
    final DURect c, {
    required final int fg,
    required final int bg,
  }) {
    for(int y = c.top; y < c.bottom; y++) {
      for(int x = c.left; x < c.right; x++) {
        p.renderGlyph(x, y, 0x20, fg: fg, bg: bg);
      }
    }
  }

  void _renderLine(
    final DUIRenderer p,
    final int x,
    final int y,
    final int width,
    final String s, {
    required final int fg,
    required final int bg,
  }) {
    final int len = math.min(width, s.length);
    for(int i = 0; i < len; i++) {
      p.renderGlyph(x + i, y, s.codeUnitAt(i), fg: fg, bg: bg);
    }
  }

  bool _blinkOn() {
    // 500ms period; phase-reset makes it "on" immediately after edits/nav.
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
    _desiredCol = 1 << 30; // reset; will be set to actual col by caller if needed
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

  /// Forces the caret to be visible immediately (resets blink phase).
  void _resetCursorBlink() {
    _blinkPhaseMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _moveDown(final int wrapWidth) {
    _rebuildWrapIfNeeded(wrapWidth);
    final _DUVisualPos pos = _cursorVisualPos(wrapWidth);
    final int curLine = pos.line;
    final int curCol = pos.col;
    if(_desiredCol == (1 << 30)) _desiredCol = curCol;
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
    } else if(line >= _scrollLine + viewHeight) {
      _scrollLine = (line - viewHeight + 1).clamp(0, maxScroll);
    }
  }

  void _rebuildWrapIfNeeded(final int wrapWidth) {
    if(wrapWidth <= 0) {
      _cachedWrapWidth = wrapWidth;
      _cachedText = text;
      _lines.clear();
      // IMPORTANT: If the text is empty, ensure our model is exactly one empty line.
      // This prevents stale glyph sampling and makes clearing deterministic.
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
    // Word-wrap strategy:
    // - Build lines by scanning code-units.
    // - Track the last break opportunity (space/tab) within the current line.
    // - When exceeding width:
    //   - If we have a break point, wrap there.
    //   - Otherwise hard-wrap at current index (long word).
    //
    // Hard newlines ('\n') always create a new visual line (newline is not rendered).
    final String s = text;
    int lineStart = 0;
    int lineLen = 0;
    int lastBreakTextIndex = -1;
    int i = 0;
    while (true) {
      final bool atEnd = (i >= s.length);
      final int ch = atEnd ? -1 : s.codeUnitAt(i);
      // Hard newline or end -> flush current line.
      if(atEnd || ch == 0x0A /* \n */) {
        _addLineFromRange(lineStart, i);
        // Move to next line after newline.
        if (atEnd) break;
        i += 1;
        lineStart = i;
        lineLen = 0;
        lastBreakTextIndex = -1;
        continue;
      }
      // If we can still fit in this line, consume char.
      if(lineLen < wrapWidth) {
        lineLen += 1;
        if(_isBreakChar(ch)) {
          lastBreakTextIndex = i;
        }
        i += 1;
        continue;
      }
      // lineLen == wrapWidth -> need to wrap BEFORE consuming s[i].
      if(lastBreakTextIndex != -1 && lastBreakTextIndex >= lineStart) {
        // Wrap BEFORE the whitespace so we don't waste a column on trailing spaces.
        _addLineFromRange(lineStart, lastBreakTextIndex);
        // Start next line AFTER any whitespace run.
        int j = lastBreakTextIndex;
        while(j < s.length) {
          final int cch = s.codeUnitAt(j);
          if(!_isBreakChar(cch)) break;
          j += 1;
        }
        lineStart = j;
        lineLen = 0;
        lastBreakTextIndex = -1;
        // Reprocess current char in the new line.
        i = lineStart;
        continue;
      }
      // No break point -> hard wrap.
      _addLineFromRange(lineStart, i);
      lineStart = i;
      lineLen = 0;
      lastBreakTextIndex = -1;
      // Don't advance i; re-process current char in new line.
    }
    if(_lines.isEmpty) {
      _lines.add(_DUTextLine(text: '', start: 0, endExclusive: 0));
    }
    _clampCursor();
  }

  bool _isBreakChar(final int ch) {
    // Space or tab are break opportunities.
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
    // Find the first line such that start <= idx <= endExclusive.
    for(int li = 0; li < _lines.length; li++) {
      final _DUTextLine ln = _lines[li];
      if(idx < ln.start) continue;
      if(idx > ln.endExclusive) continue;
      // Cursor within this line segment.
      final int col = (idx - ln.start).clamp(0, ln.text.length);
      return _DUVisualPos(line: li, col: col);
    }
    // Fallback: clamp to last line end.
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
/// Behavior:
/// - Fires immediately on first press.
/// - Then repeats after [initialDelayMs].
/// - Then repeats every [repeatEveryMs] while held.
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
