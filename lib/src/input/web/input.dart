/// Immediate-mode web-based keyboard and mouse input management for Dascade.
///
/// This implementation translates browser keyboard and mouse events
/// into terminal style, cell based input semantics. It normalizes DOM
/// events to match native terminal behavior as closely as possible.
///
/// Key handling is immediate mode and state based. All getters reflect
/// whether a key or button is currently held down.
///
/// Mouse coordinates are reported in terminal cell units, not pixels,
/// and are guaranteed to stay aligned with the web terminal rendering
/// grid defined by [DascadeWebMetrics].
///
/// This class is intended to be used only on web platforms and should
/// be created through the platform abstraction layer.
library;

// ignore: deprecated_member_use
import 'dart:html';

import 'package:dascade/src/input/input_interface.dart';
import 'package:dascade/src/output/web/metrics.dart';

/// Immediate-mode web-based keyboard and mouse input management for Dascade.
final class DascadeWebInput implements DascadeInputInterface {

  /// Map of active key states indexed by normalized key name.
  final Map<String, bool> _keys = {};

  /// Last printable character received this frame.
  String? _last;

  /// Current shift modifier state.
  bool _shift = false;

  /// Current control modifier state.
  bool _ctrl = false;

    /// Current mouse X position in cell coordinates.
  int _mouseX = 0;

  /// Current mouse Y position in cell coordinates.
  int _mouseY = 0;

  /// Current left mouse button state.
  bool _mouseLeftDown = false;

  /// Current middle mouse button state.
  bool _mouseMiddleDown = false;

  /// Current right mouse button state.
  bool _mouseRightDown = false;

  /// Accumulated scroll wheel delta for the current frame.
  int _scroll = 0;

  /// Controls whether right mouse button state is tracked across frames.
  ///
  /// Some environments consume right click events before release.
  bool _allowRightMouseCallbackStateTracking = true;

  /// Begins listening for browser keyboard and mouse events.
  ///
  /// This should be called once during application startup.
  @override
  void start() {
    window.onKeyDown.listen(_onKeyDown);
    window.onKeyUp.listen(_onKeyUp);
    window.onMouseMove.listen(_onMouseMove);
    window.onMouseDown.listen(_onMouseDown);
    window.onMouseUp.listen(_onMouseUp);
    window.onWheel.listen(_onWheel);
  }

  /// Resets per frame input state.
  ///
  /// This clears transient input such as last typed character and
  /// scroll wheel movement. Held key and mouse button state is
  /// preserved unless explicitly disabled.
  @override
  void flush() {
    _keys.clear();
    _last = null;
    if(!_allowRightMouseCallbackStateTracking) {
      _mouseRightDown = false;
    }
    _scroll = 0;
  }

  /// Stops input processing.
  ///
  /// This is a no op for the web backend.
  @override
  void stop() {}

  /// Handles browser key down events and updates internal key state.
  void _onKeyDown(KeyboardEvent e) {
    _shift = e.shiftKey;
    _ctrl = e.ctrlKey;
    final String key = e.key ?? '';
    if(key.isEmpty) return;
    if(key.length == 1) {
      _keys[key] = true;
      _last = key;
      return;
    }
    // Special keys...
    _keys[_normalizeSpecialKey(key)] = true;
  }

  /// Handles browser key up events and updates internal key state.
  void _onKeyUp(KeyboardEvent e) {
    _shift = e.shiftKey;
    _ctrl = e.ctrlKey;
    final String key = e.key ?? '';
    if(key.isEmpty) return;
    if(key.length == 1) {
      _keys[key] = false;
      return;
    }
    _keys[_normalizeSpecialKey(key)] = false;
  }

  /// Handles mouse movement and converts pixel coordinates to cell space.
  void _onMouseMove(MouseEvent e) {
    final int x = (e.offset.x ~/ DascadeWebMetrics.cellWidth);
    final int y = (e.offset.y ~/ DascadeWebMetrics.cellHeight);
    _mouseX = x.clamp(0, 0x7fffffff);
    _mouseY = y.clamp(0, 0x7fffffff);
  }

  /// Handles mouse button press events.
  void _onMouseDown(MouseEvent e) {
    if(e.button == 0) _mouseLeftDown = true;
    if(e.button == 1) _mouseMiddleDown = true;
    if(e.button == 2) _mouseRightDown = true;
  }

  /// Handles mouse button release events.
  void _onMouseUp(MouseEvent e) {
    if(e.button == 0) _mouseLeftDown = false;
    if(e.button == 1) _mouseMiddleDown = false;
    if(e.button == 2 && _allowRightMouseCallbackStateTracking) {
      _mouseRightDown = false;
    }
  }

  /// Handles mouse scroll wheel events.
  void _onWheel(WheelEvent e) {
    _scroll += e.deltaY.sign.toInt();
  }

  /// Converts browser specific key identifiers into terminal style names.
  String _normalizeSpecialKey(String key) {
    switch (key) {
      case 'ArrowUp': return 'up';
      case 'ArrowDown': return 'down';
      case 'ArrowLeft': return 'left';
      case 'ArrowRight': return 'right';
      case 'PageUp': return 'pageUp';
      case 'PageDown': return 'pageDown';
      case 'Home': return 'home';
      case 'End': return 'end';
      case 'Escape': return 'escape';
      case 'Delete': return 'delete';
      case 'Backspace': return 'backspace';
      case 'F1': return 'f1';
      case 'F2': return 'f2';
      case 'F3': return 'f3';
      case 'F4': return 'f4';
      default:
        return key;
    }
  }

  /// Returns whether a control modified character key is held.
  bool _ctrlKey(String char) {
    return _ctrl && (_keys[char.toLowerCase()] ?? false);
  }

  /// Returns whether a shifted character key is held.
  bool _upper(String c) => _shift && (_keys[c] ?? false);

  /// Controls whether the right mouse button is treated as stateful.
  @override
  set allowRightMouseCallbackStateTracking(bool state) => _allowRightMouseCallbackStateTracking = state;

  /// Returns whether the given printable key is currently held.
  @override
  bool key(String key) => _keys[key] ?? false;

  /// Returns the last printable character typed this frame.
  ///
  /// Modifier and special keys are not reported here.
  @override
  String? get last => _last;

  /// Returns the current mouse X position (hovering supported)
  @override
  int get mouseX => _mouseX;

  /// Returns the current mouse Y position (hovering supported)
  @override
  int get mouseY => _mouseY;

  /// Returns the current state of the left mouse button.
  @override
  bool get mouseLeftDown => _mouseLeftDown;
  
  /// Returns the current state of the middle mouse button.
  @override
  bool get mouseMiddleDown => _mouseMiddleDown;
  
  /// Returns the current state of the right mouse button.
  @override
  bool get mouseRightDown => _mouseRightDown;

  /// Returns the current state of the mouse's scrollwheel value.
  @override
  int get mouseScrollwheelValue => -_scroll;

  // Lowercase key shortcuts.

  @override bool get a => _keys['a'] ?? false;
  @override bool get b => _keys['b'] ?? false;
  @override bool get c => _keys['c'] ?? false;
  @override bool get d => _keys['d'] ?? false;
  @override bool get e => _keys['e'] ?? false;
  @override bool get f => _keys['f'] ?? false;
  @override bool get g => _keys['g'] ?? false;
  @override bool get h => _keys['h'] ?? false;
  @override bool get i => _keys['i'] ?? false;
  @override bool get j => _keys['j'] ?? false;
  @override bool get k => _keys['k'] ?? false;
  @override bool get l => _keys['l'] ?? false;
  @override bool get m => _keys['m'] ?? false;
  @override bool get n => _keys['n'] ?? false;
  @override bool get o => _keys['o'] ?? false;
  @override bool get p => _keys['p'] ?? false;
  @override bool get q => _keys['q'] ?? false;
  @override bool get r => _keys['r'] ?? false;
  @override bool get s => _keys['s'] ?? false;
  @override bool get t => _keys['t'] ?? false;
  @override bool get u => _keys['u'] ?? false;
  @override bool get v => _keys['v'] ?? false;
  @override bool get w => _keys['w'] ?? false;
  @override bool get x => _keys['x'] ?? false;
  @override bool get y => _keys['y'] ?? false;
  @override bool get z => _keys['z'] ?? false;

  // Uppercase key shortcuts (Shift+Letter)

  @override bool get A => _upper('a');
  @override bool get B => _upper('b');
  @override bool get C => _upper('c');
  @override bool get D => _upper('d');
  @override bool get E => _upper('e');
  @override bool get F => _upper('f');
  @override bool get G => _upper('g');
  @override bool get H => _upper('h');
  @override bool get I => _upper('i');
  @override bool get J => _upper('j');
  @override bool get K => _upper('k');
  @override bool get L => _upper('l');
  @override bool get M => _upper('m');
  @override bool get N => _upper('n');
  @override bool get O => _upper('o');
  @override bool get P => _upper('p');
  @override bool get Q => _upper('q');
  @override bool get R => _upper('r');
  @override bool get S => _upper('s');
  @override bool get T => _upper('t');
  @override bool get U => _upper('u');
  @override bool get V => _upper('v');
  @override bool get W => _upper('w');
  @override bool get X => _upper('x');
  @override bool get Y => _upper('y');
  @override bool get Z => _upper('z');

  // Modifier key shortcuts.
  
  @override bool get ctrlA => _ctrlKey('a');
  @override bool get ctrlB => _ctrlKey('b');
  @override bool get ctrlC => _ctrlKey('c');
  @override bool get ctrlD => _ctrlKey('d');
  @override bool get ctrlE => _ctrlKey('e');
  @override bool get ctrlF => _ctrlKey('f');
  @override bool get ctrlG => _ctrlKey('g');
  @override bool get ctrlH => _ctrlKey('h');
  @override bool get ctrlI => _ctrlKey('i');
  @override bool get ctrlJ => _ctrlKey('j');
  @override bool get ctrlK => _ctrlKey('k');
  @override bool get ctrlL => _ctrlKey('l');
  @override bool get ctrlM => _ctrlKey('m');
  @override bool get ctrlN => _ctrlKey('n');
  @override bool get ctrlO => _ctrlKey('o');
  @override bool get ctrlP => _ctrlKey('p');
  @override bool get ctrlQ => _ctrlKey('q');
  @override bool get ctrlR => _ctrlKey('r');
  @override bool get ctrlS => _ctrlKey('s');
  @override bool get ctrlT => _ctrlKey('t');
  @override bool get ctrlU => _ctrlKey('u');
  @override bool get ctrlV => _ctrlKey('v');
  @override bool get ctrlW => _ctrlKey('w');
  @override bool get ctrlX => _ctrlKey('x');
  @override bool get ctrlY => _ctrlKey('y');
  @override bool get ctrlZ => _ctrlKey('z');

  // Navigation / special key shortcuts.

  @override bool get up => _keys['up'] ?? false;
  @override bool get down => _keys['down'] ?? false;
  @override bool get left => _keys['left'] ?? false;
  @override bool get right => _keys['right'] ?? false;
  @override bool get pageUp => _keys['pageUp'] ?? false;
  @override bool get pageDown => _keys['pageDown'] ?? false;
  @override bool get home => _keys['home'] ?? false;
  @override bool get end => _keys['end'] ?? false;
  @override bool get escape => _keys['escape'] ?? false;
  @override bool get delete => _keys['delete'] ?? false;
  @override bool get backspace => _keys['backspace'] ?? false;

  // Function key shortcuts.

  @override bool get f1 => _keys['f1'] ?? false;
  @override bool get f2 => _keys['f2'] ?? false;
  @override bool get f3 => _keys['f3'] ?? false;
  @override bool get f4 => _keys['f4'] ?? false;

  // Number key shortcuts.
  
  @override bool get num0 => _keys['0'] ?? false;
  @override bool get num1 => _keys['1'] ?? false;
  @override bool get num2 => _keys['2'] ?? false;
  @override bool get num3 => _keys['3'] ?? false;
  @override bool get num4 => _keys['4'] ?? false;
  @override bool get num5 => _keys['5'] ?? false;
  @override bool get num6 => _keys['6'] ?? false;
  @override bool get num7 => _keys['7'] ?? false;
  @override bool get num8 => _keys['8'] ?? false;
  @override bool get num9 => _keys['9'] ?? false;

}
