/// Asynchronous & immediate-mode native keyboard and mouse input management for Dascade.
///
/// IMPORTANT:
/// This design mirrors traditional terminal UI libraries (ncurses,
/// libtermkey, etc.) and is the only correct way to handle terminal
/// input without blocking rendering.
library;

import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:dascade/src/input/input_interface.dart';
import 'package:dascade/src/input/native/mouse_event.dart';
import 'package:dascade/src/input/native/poller.dart';

/// Asynchronous & immediate-mode native keyboard and mouse input management for Dascade.
/// 
/// NOTE (iwilkey): There are several places this can be refined. One nice feature would be the tracking of key state transitions: just down, just up, etc.
final class DascadeNativeInput implements DascadeInputInterface {

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
  @override
  void start() async {
    _port = ReceivePort();
    _isolate = await Isolate.spawn(DascadeNativeInputPoller.routine, _port.sendPort);
    _isolateRunning = true;
    _port.listen((final dynamic message) {
      if(message is Key) {
        _last = message;
        if (message.isControl) {
          _modifiers[message.controlChar] = true;
        } else if (message.char.isNotEmpty) {
          _keys[message.char] = true;
        }
      } else if (message is DascadeNativeMouseEvent) {
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
  @override
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
  @override
  void stop() {
    _port.close();
    if(_isolateRunning) {
      _isolate?.kill(priority: Isolate.immediate);
    }
    _isolateRunning = false;
  }

  /// Controls whether the right mouse button is treated as a stateful input.
  @override
  set allowRightMouseCallbackStateTracking(final bool state) => _allowRightMouseCallbackStateTracking = state;

  /// Returns whether or not the given char is currently held down.
  @override
  bool key(final String key) => _keys[key] ?? false;

  /// Returns the last typed character's char value. This WILL NOT return modifier key events, or other special input. If you want to know
  /// about those events, you should poll for them using the shortcut methods defined in [DascadeNativeInput].
  @override
  String? get last => _last?.char;
  
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

  @override bool get A => _keys['A'] ?? false;
  @override bool get B => _keys['B'] ?? false;
  @override bool get C => _keys['C'] ?? false;
  @override bool get D => _keys['D'] ?? false;
  @override bool get E => _keys['E'] ?? false;
  @override bool get F => _keys['F'] ?? false;
  @override bool get G => _keys['G'] ?? false;
  @override bool get H => _keys['H'] ?? false;
  @override bool get I => _keys['I'] ?? false;
  @override bool get J => _keys['J'] ?? false;
  @override bool get K => _keys['K'] ?? false;
  @override bool get L => _keys['L'] ?? false;
  @override bool get M => _keys['M'] ?? false;
  @override bool get N => _keys['N'] ?? false;
  @override bool get O => _keys['O'] ?? false;
  @override bool get P => _keys['P'] ?? false;
  @override bool get Q => _keys['Q'] ?? false;
  @override bool get R => _keys['R'] ?? false;
  @override bool get S => _keys['S'] ?? false;
  @override bool get T => _keys['T'] ?? false;
  @override bool get U => _keys['U'] ?? false;
  @override bool get V => _keys['V'] ?? false;
  @override bool get W => _keys['W'] ?? false;
  @override bool get X => _keys['X'] ?? false;
  @override bool get Y => _keys['Y'] ?? false;
  @override bool get Z => _keys['Z'] ?? false;

  // Modifier key shortcuts.
  
  @override bool get ctrlA => _modifiers[ControlCharacter.ctrlA] ?? false;
  @override bool get ctrlB => _modifiers[ControlCharacter.ctrlB] ?? false;
  @override bool get ctrlC => _modifiers[ControlCharacter.ctrlC] ?? false;
  @override bool get ctrlD => _modifiers[ControlCharacter.ctrlD] ?? false;
  @override bool get ctrlE => _modifiers[ControlCharacter.ctrlE] ?? false;
  @override bool get ctrlF => _modifiers[ControlCharacter.ctrlF] ?? false;
  @override bool get ctrlG => _modifiers[ControlCharacter.ctrlG] ?? false;
  @override bool get ctrlH => _modifiers[ControlCharacter.ctrlH] ?? false;
  @override bool get ctrlI => _modifiers[ControlCharacter.tab] ?? false;
  @override bool get ctrlJ => _modifiers[ControlCharacter.ctrlJ] ?? false;
  @override bool get ctrlK => _modifiers[ControlCharacter.ctrlK] ?? false;
  @override bool get ctrlL => _modifiers[ControlCharacter.ctrlL] ?? false;
  @override bool get ctrlM => _modifiers[ControlCharacter.enter] ?? false;
  @override bool get ctrlN => _modifiers[ControlCharacter.ctrlN] ?? false;
  @override bool get ctrlO => _modifiers[ControlCharacter.ctrlO] ?? false;
  @override bool get ctrlP => _modifiers[ControlCharacter.ctrlP] ?? false;
  @override bool get ctrlQ => _modifiers[ControlCharacter.ctrlQ] ?? false;
  @override bool get ctrlR => _modifiers[ControlCharacter.ctrlR] ?? false;
  @override bool get ctrlS => _modifiers[ControlCharacter.ctrlS] ?? false;
  @override bool get ctrlT => _modifiers[ControlCharacter.ctrlT] ?? false;
  @override bool get ctrlU => _modifiers[ControlCharacter.ctrlU] ?? false;
  @override bool get ctrlV => _modifiers[ControlCharacter.ctrlV] ?? false;
  @override bool get ctrlW => _modifiers[ControlCharacter.ctrlW] ?? false;
  @override bool get ctrlX => _modifiers[ControlCharacter.ctrlX] ?? false;
  @override bool get ctrlY => _modifiers[ControlCharacter.ctrlY] ?? false;
  @override bool get ctrlZ => _modifiers[ControlCharacter.ctrlZ] ?? false;

  // Navigation / special key shortcuts.

  @override bool get up => _modifiers[ControlCharacter.arrowUp] ?? false;
  @override bool get down => _modifiers[ControlCharacter.arrowDown] ?? false;
  @override bool get left => _modifiers[ControlCharacter.arrowLeft] ?? false;
  @override bool get right => _modifiers[ControlCharacter.arrowRight] ?? false;
  @override bool get pageUp => _modifiers[ControlCharacter.pageUp] ?? false;
  @override bool get pageDown => _modifiers[ControlCharacter.pageDown] ?? false;
  @override bool get home => _modifiers[ControlCharacter.home] ?? false;
  @override bool get end => _modifiers[ControlCharacter.end] ?? false;
  @override bool get escape => _modifiers[ControlCharacter.escape] ?? false;
  @override bool get delete => _modifiers[ControlCharacter.delete] ?? false;
  @override bool get backspace => _modifiers[ControlCharacter.backspace] ?? false;

  // Function key shortcuts.

  @override bool get f1 => _modifiers[ControlCharacter.F1] ?? false;
  @override bool get f2 => _modifiers[ControlCharacter.F2] ?? false;
  @override bool get f3 => _modifiers[ControlCharacter.F3] ?? false;
  @override bool get f4 => _modifiers[ControlCharacter.F4] ?? false;

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
