/// Keyboard input handling for Dascade.
///
/// Asynchronous & immediate-mode keyboard and mouse input management for Dascade.
///
/// IMPORTANT:
/// This design mirrors traditional terminal UI libraries (ncurses,
/// libtermkey, etc.) and is the only correct way to handle terminal
/// input without blocking rendering.
///
/// Only keyboard input is supported at this time.
library;

import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:dascade/src/input/mouse_event.dart';
import 'package:dascade/src/input/poller.dart';

/// Asynchronous & immediate-mode keyboard input management for Dascade.
/// 
/// NOTE (iwilkey): There are several places this can be refined. One nice feature would be the tracking of key state transitions: just down, just up, etc.
final class DascadeInput {

  /// Key states.
  final Map<String, bool> _keys = {};

  /// Modifer & special key states.
  final Map<ControlCharacter, bool> _modifiers = {};

  /// The return port of key events, as polled from the input manager's isolate.
  late final ReceivePort _port;

  /// The isolate responsible for polling input state off the main rendering thread.
  late final Isolate? _isolate;

  /// The last key.
  Key? _last;

  /// Current mouse X position (hovering supported)
  int _mouseX = 0;

  /// Current mouse Y position (hovering supported)
  int _mouseY = 0;

  /// Current state of the left mouse button.
  bool _mouseLeftDown = false;

  /// Current state of the middle mouse button.
  bool _mouseMiddleDown = false;

  /// Current state of the right mouse button.
  bool _mouseRightDown = false;

  /// Current scroll value, from the mouse.
  int _scroll = 0;
  
  /// State of whether not not Dascade handles right mouse events in callback or not. See [Dascade] documentation for why this
  /// is needed.
  bool _allowRightMouseCallbackStateTracking = true;

  /// Whether or not the isolate is currently running.
  bool _isolateRunning = false;

  /// Begins listening for input in isolate. Should only be called by the [Dascade] instance.
  void start() async {
    _port = ReceivePort();
    _isolate = await Isolate.spawn(DascadeInputPoller.routine, _port.sendPort);
    _isolateRunning = true;
    _port.listen((final dynamic message) {
      if(message is Key) {
        _last = message;
        if (message.isControl) {
          _modifiers[message.controlChar] = true;
        } else if (message.char.isNotEmpty) {
          _keys[message.char] = true;
        }
      } else if (message is DascadeMouseEvent) {
        _mouseX = message.x;
        _mouseY = message.y;
        if(message.leftDown) _mouseLeftDown = true;
        if(message.leftUp) _mouseLeftDown = false;
        if(message.middleDown) _mouseMiddleDown = true;
        if(message.middleUp) _mouseMiddleDown = false;
        if(message.rightDown) _mouseRightDown = true;
        if(_allowRightMouseCallbackStateTracking) {
          if(message.rightUp) _mouseRightDown = false;
        }
        _scroll += message.scroll;
      }
    });
  }

  /// Resets the state of input for next frame. Should only be called internally at runtime dispose time by the [Dascade] object.
  void flush() {
    _keys.clear();
    _modifiers.clear();
    /// We must reset right mouse programatically if they are in an environment like VSCode.
    if(!_allowRightMouseCallbackStateTracking) {
      _mouseRightDown = false;
    }
    /// We must reset scroll as it is impossible to make it stateful. TODO: Might make this user-configurable later.
    _scroll = 0;
    _last = null;
  }

  /// Kills the input listener isolate. Should only be called internally at runtime dispose time by the [Dascade] object.
  void stop() {
    _port.close();
    if(_isolateRunning) {
      _isolate?.kill(priority: Isolate.immediate);
    }
    _isolateRunning = false;
  }

  /// Controls whether the right mouse button is treated as a stateful input.
  set allowRightMouseCallbackStateTracking(final bool state) => _allowRightMouseCallbackStateTracking = state;

  /// Returns whether or not the given char is currently held down.
  bool key(final String key) => _keys[key] ?? false;

  /// Returns the last typed character's char value. This WILL NOT return modifier key events, or other special input. If you want to know
  /// about those events, you should poll for them using the shortcut methods defined in [DascadeInput].
  String? get last => _last?.char;
  
  /// Returns the current mouse X position (hovering supported)
  int get mouseX => _mouseX;

  /// Returns the current mouse Y position (hovering supported)
  int get mouseY => _mouseY;

  /// Returns the current state of the left mouse button.
  bool get mouseLeftDown => _mouseLeftDown;
  
  /// Returns the current state of the middle mouse button.
  bool get mouseMiddleDown => _mouseMiddleDown;
  
  /// Returns the current state of the right mouse button.
  bool get mouseRightDown => _mouseRightDown;

  /// Returns the current state of the mouse's scrollwheel value.
  int get mouseScrollwheelValue => -_scroll;

  // Lowercase key shortcuts.

  bool get a => _keys['a'] ?? false;
  bool get b => _keys['b'] ?? false;
  bool get c => _keys['c'] ?? false;
  bool get d => _keys['d'] ?? false;
  bool get e => _keys['e'] ?? false;
  bool get f => _keys['f'] ?? false;
  bool get g => _keys['g'] ?? false;
  bool get h => _keys['h'] ?? false;
  bool get i => _keys['i'] ?? false;
  bool get j => _keys['j'] ?? false;
  bool get k => _keys['k'] ?? false;
  bool get l => _keys['l'] ?? false;
  bool get m => _keys['m'] ?? false;
  bool get n => _keys['n'] ?? false;
  bool get o => _keys['o'] ?? false;
  bool get p => _keys['p'] ?? false;
  bool get q => _keys['q'] ?? false;
  bool get r => _keys['r'] ?? false;
  bool get s => _keys['s'] ?? false;
  bool get t => _keys['t'] ?? false;
  bool get u => _keys['u'] ?? false;
  bool get v => _keys['v'] ?? false;
  bool get w => _keys['w'] ?? false;
  bool get x => _keys['x'] ?? false;
  bool get y => _keys['y'] ?? false;
  bool get z => _keys['z'] ?? false;

  // Uppercase key shortcuts (Shift+Letter)

  bool get A => _keys['A'] ?? false;
  bool get B => _keys['B'] ?? false;
  bool get C => _keys['C'] ?? false;
  bool get D => _keys['D'] ?? false;
  bool get E => _keys['E'] ?? false;
  bool get F => _keys['F'] ?? false;
  bool get G => _keys['G'] ?? false;
  bool get H => _keys['H'] ?? false;
  bool get I => _keys['I'] ?? false;
  bool get J => _keys['J'] ?? false;
  bool get K => _keys['K'] ?? false;
  bool get L => _keys['L'] ?? false;
  bool get M => _keys['M'] ?? false;
  bool get N => _keys['N'] ?? false;
  bool get O => _keys['O'] ?? false;
  bool get P => _keys['P'] ?? false;
  bool get Q => _keys['Q'] ?? false;
  bool get R => _keys['R'] ?? false;
  bool get S => _keys['S'] ?? false;
  bool get T => _keys['T'] ?? false;
  bool get U => _keys['U'] ?? false;
  bool get V => _keys['V'] ?? false;
  bool get W => _keys['W'] ?? false;
  bool get X => _keys['X'] ?? false;
  bool get Y => _keys['Y'] ?? false;
  bool get Z => _keys['Z'] ?? false;

  // Modifier key shortcuts.
  
  bool get ctrlA => _modifiers[ControlCharacter.ctrlA] ?? false;
  bool get ctrlB => _modifiers[ControlCharacter.ctrlB] ?? false;
  bool get ctrlC => _modifiers[ControlCharacter.ctrlC] ?? false;
  bool get ctrlD => _modifiers[ControlCharacter.ctrlD] ?? false;
  bool get ctrlE => _modifiers[ControlCharacter.ctrlE] ?? false;
  bool get ctrlF => _modifiers[ControlCharacter.ctrlF] ?? false;
  bool get ctrlG => _modifiers[ControlCharacter.ctrlG] ?? false;
  bool get ctrlH => _modifiers[ControlCharacter.ctrlH] ?? false;
  bool get ctrlI => _modifiers[ControlCharacter.tab] ?? false;
  bool get ctrlJ => _modifiers[ControlCharacter.ctrlJ] ?? false;
  bool get ctrlK => _modifiers[ControlCharacter.ctrlK] ?? false;
  bool get ctrlL => _modifiers[ControlCharacter.ctrlL] ?? false;
  bool get ctrlM => _modifiers[ControlCharacter.enter] ?? false;
  bool get ctrlN => _modifiers[ControlCharacter.ctrlN] ?? false;
  bool get ctrlO => _modifiers[ControlCharacter.ctrlO] ?? false;
  bool get ctrlP => _modifiers[ControlCharacter.ctrlP] ?? false;
  bool get ctrlQ => _modifiers[ControlCharacter.ctrlQ] ?? false;
  bool get ctrlR => _modifiers[ControlCharacter.ctrlR] ?? false;
  bool get ctrlS => _modifiers[ControlCharacter.ctrlS] ?? false;
  bool get ctrlT => _modifiers[ControlCharacter.ctrlT] ?? false;
  bool get ctrlU => _modifiers[ControlCharacter.ctrlU] ?? false;
  bool get ctrlV => _modifiers[ControlCharacter.ctrlV] ?? false;
  bool get ctrlW => _modifiers[ControlCharacter.ctrlW] ?? false;
  bool get ctrlX => _modifiers[ControlCharacter.ctrlX] ?? false;
  bool get ctrlY => _modifiers[ControlCharacter.ctrlY] ?? false;
  bool get ctrlZ => _modifiers[ControlCharacter.ctrlZ] ?? false;

  // Navigation / special key shortcuts.

  bool get up => _modifiers[ControlCharacter.arrowUp] ?? false;
  bool get down => _modifiers[ControlCharacter.arrowDown] ?? false;
  bool get left => _modifiers[ControlCharacter.arrowLeft] ?? false;
  bool get right => _modifiers[ControlCharacter.arrowRight] ?? false;
  bool get pageUp => _modifiers[ControlCharacter.pageUp] ?? false;
  bool get pageDown => _modifiers[ControlCharacter.pageDown] ?? false;
  bool get home => _modifiers[ControlCharacter.home] ?? false;
  bool get end => _modifiers[ControlCharacter.end] ?? false;
  bool get escape => _modifiers[ControlCharacter.escape] ?? false;
  bool get delete => _modifiers[ControlCharacter.delete] ?? false;
  bool get backspace => _modifiers[ControlCharacter.backspace] ?? false;

  // Function key shortcuts.

  bool get f1 => _modifiers[ControlCharacter.F1] ?? false;
  bool get f2 => _modifiers[ControlCharacter.F2] ?? false;
  bool get f3 => _modifiers[ControlCharacter.F3] ?? false;
  bool get f4 => _modifiers[ControlCharacter.F4] ?? false;

  // Number key shortcuts.
  
  bool get num0 => _keys['0'] ?? false;
  bool get num1 => _keys['1'] ?? false;
  bool get num2 => _keys['2'] ?? false;
  bool get num3 => _keys['3'] ?? false;
  bool get num4 => _keys['4'] ?? false;
  bool get num5 => _keys['5'] ?? false;
  bool get num6 => _keys['6'] ?? false;
  bool get num7 => _keys['7'] ?? false;
  bool get num8 => _keys['8'] ?? false;
  bool get num9 => _keys['9'] ?? false;

}
