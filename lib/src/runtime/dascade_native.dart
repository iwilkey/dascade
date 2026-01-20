/// Native runtime implementation for Dascade.
///
/// This file defines the native (terminal-based) implementation of the
/// Dascade runtime. It is responsible for:
///
/// - Terminal ownership and cleanup
/// - Native input lifecycle
/// - Immediate-mode rendering coordination
/// - POSIX signal handling
/// - Sidecar-backed print() interception
///
/// This file must never be imported on web platforms.
library;

import 'dart:async';
import 'dart:io';

import 'package:dascade/src/input/input_interface.dart';
import 'package:dascade/src/input/native/input.dart';
import 'package:dascade/src/output/rendering_interface.dart';
import 'package:dascade/src/output/terminal_interface.dart';
import 'package:dascade/src/platform/platform.dart';
import 'package:dascade/src/platform/select_platform.dart';
import 'package:dascade/src/runtime/dascade_framework.dart';
import 'package:dascade/src/sidecar/sidecar.dart';
import 'package:dascade/src/ui/ui.dart';

Future<void> execute(Future<void> Function(DascadeFramework) app) => (DascadeNative.execute as dynamic)(app);

/// The main interface of Dascade Native. All framework calls should be made through this object.
/// 
/// It's main function is to dispatch high-level API calls to the correct Dascade modules.
final class DascadeNative implements DascadeFramework {

  /// There can only be one active instance of Dascade in a project.
  static bool _activeInstance = false;

  /// Is Sidecar currently ready for writes?
  static bool _sidecarActive = false;

  /// Is Sidecar bootstrapping to get ready for writes?
  static bool _sidecarBootstrapping = false;

  /// Whether or not Sidecar is allowed to bind during print() statements.
  static bool _forceNoSidecar = false;

  /// Holds Sidecar print() statements during bootstrap to make sure they are shown eventually.
  static final List<String> _sidecarBuffer = [];

  /// The origin of the terminal interface for Dascade. This class should be the only class that
  /// instantiates it.
  static late final DascadeTerminalInterface _terminal;

  /// The origin of the renderer interface for Dascade. This class should be the only class that
  /// instantiates it.
  static late final DascadeRenderingInterface _renderer;

  /// The origin of the input module of Dascade. This class should be the only class that
  /// instantiates it.
  static late final DascadeInputInterface _input;

  /// Reference to the Dascade UI package.
  static late final DascadeUI _ui;

  /// Constructs the Dascade object at beginning of application runtime.
  DascadeNative._internal() {
    if(_activeInstance) {
      throw Exception("Only one Dascade instance allowed.");
    }
    final DascadePlatform platform = createPlatform();
    _terminal = platform.createTerminal();
    _renderer = platform.createRenderer(_terminal);
    _input = platform.createInput();
    _ui = DascadeUI(this);
    _activeInstance = true;
    _installSignalHandlers(this);
  }

  // //////////////////////////////////////////////
  // ENTRY API
  // //////////////////////////////////////////////

  /// Runs a new instance of Dascade. It defines the main entry point to every Dascade application and is the only
  /// correct usage of initializing a runtime of Dascade. See examples or API documentation on how to use it correctly.
  static Future<void> execute(final DascadeApp app) async {
    late DascadeNative d;
    await runZonedGuarded(() async {
      d = DascadeNative._internal();
      await app(d);
    }, (error, stack) {
      d._dispose();
      stderr.writeln("\n================================");
      stderr.writeln("DASCADE APPLICATION FATAL ERROR");
      stderr.writeln("================================\n");
      stderr.writeln(error);
      stderr.writeln(stack);
      if(_sidecarActive) {
        /// Sidecar has been created during this runtime, so we need to dispose of it.
        DascadeSidecar.dispose();
      }
    }, zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {
        /// Dascade handles print() statements using the "Sidecar" system. If a print() statement has been invoked, it will open
        /// or use the existing terminal process to show the statement in another terminal.
        if(_forceNoSidecar) return;
        if(!_sidecarActive) {
          // Sidecar not ready yet: buffer to be seen later.
          _sidecarBuffer.add(message);
          if(_sidecarBootstrapping) return;
          _sidecarBootstrapping = true;
          DascadeSidecar.open().then((_) async {
            // Give the FIFO reader a moment to attach. TODO: 500 ms is arbitrary. It would be better if we had a Future tell us when pipeline is ready.
            await Future.delayed(const Duration(milliseconds: 500));
            _sidecarBootstrapping = false;
            _sidecarActive = true;
            // Flush buffered messages sent during Sidecar initialization.
            for(final String line in _sidecarBuffer) {
              DascadeSidecar.write(line);
            }
            _sidecarBuffer.clear();
          });
        } else {
          // Sidecar ready, so we can write immediately.
          DascadeSidecar.write(message);
        }
      },
    ))?.whenComplete(() {
      d._dispose();
      if(_sidecarActive) {
        /// Sidecar has been created during this runtime, so we need to dispose of it.
        DascadeSidecar.dispose();
      }
    });
  }

  // //////////////////////////////////////////////
  // CONFIGURATION
  // ///////////////////////////////////////////////

  /// Whether or not Sidecar is allowed to bind during print() statements. If you decide to opt-out of Sidecar, your
  /// print statements will essentially be completely ignored. Note that you need to ensure you set this state before
  /// your first print statement invokes, otherwise it will do nothing but ignore statements.
  @override
  set forceNoSidecar(final bool ns) => _forceNoSidecar = ns;

  /// Controls whether the right mouse button is treated as a stateful input.
  ///
  /// IMPORTANT:
  /// Many terminal environments (including VS Code’s integrated terminal,
  /// Windows Terminal, and some Linux terminals) intercept the right mouse
  /// button to display a context menu. When this happens, the terminal
  /// often suppresses the corresponding mouse *release* event.
  ///
  /// This can cause the right mouse button to appear “stuck” in a pressed
  /// state if state tracking is enabled.
  ///
  /// When this option is:
  /// - `true`: Right mouse button presses and releases are tracked as state.
  ///   This may result in a stuck `mouseRight` state in some terminals.
  /// - `false` (default): Right mouse button is treated as an edge-triggered
  ///   event only, and Dascade may synthesize a release to ensure consistent
  ///   behavior across terminal environments.
  ///
  /// This setting exists to allow advanced users to opt into raw behavior
  /// when running in terminals that correctly forward right mouse events.
  @override
  set allowRightMouseCallbackStateTracking(final bool state) => _input.allowRightMouseCallbackStateTracking = state;

  // //////////////////////////////////////////////
  // DASCADE UI
  // ///////////////////////////////////////////////

  @override
  DascadeUI get ui => _ui;

  // //////////////////////////////////////////////
  // INPUT API
  // //////////////////////////////////////////////
  
  /// Returns the current mouse X position (hovering supported)
  @override
  int get mouseX => _input.mouseX;

  /// Returns the current mouse Y position (hovering supported)
  @override
  int get mouseY => _input.mouseY;

  /// Returns the current state of the left mouse button.
  @override
  bool get mouseLeftDown => _input.mouseLeftDown;
  
  /// Returns the current state of the middle mouse button.
  @override
  bool get mouseMiddleDown => _input.mouseMiddleDown;
  
  /// Returns the current state of the right mouse button.
  @override
  bool get mouseRightDown => _input.mouseRightDown;

  /// Returns the current state of the mouse's scrollwheel value.
  /// 
  /// By Dascade convention, a value < 0 means "your finger is coming toward you" and > 0 means "your finger is going away from you" on vertical-only mice.
  /// 
  /// That said, you can easily invert by multipling the value by negative 1.
  @override
  int get mouseScrollwheelValue => _input.mouseScrollwheelValue;

  // Lowercase key shortcuts.

  @override bool get a => _input.a;
  @override bool get b => _input.b;
  @override bool get c => _input.c;
  @override bool get d => _input.d;
  @override bool get e => _input.e;
  @override bool get f => _input.f;
  @override bool get g => _input.g;
  @override bool get h => _input.h;
  @override bool get i => _input.i;
  @override bool get j => _input.j;
  @override bool get k => _input.k;
  @override bool get l => _input.l;
  @override bool get m => _input.m;
  @override bool get n => _input.n;
  @override bool get o => _input.o;
  @override bool get p => _input.p;
  @override bool get q => _input.q;
  @override bool get r => _input.r;
  @override bool get s => _input.s;
  @override bool get t => _input.t;
  @override bool get u => _input.u;
  @override bool get v => _input.v;
  @override bool get w => _input.w;
  @override bool get x => _input.x;
  @override bool get y => _input.y;
  @override bool get z => _input.z;

  // Uppercase key shortcuts (Shift+Letter)

  @override bool get A => _input.A;
  @override bool get B => _input.B;
  @override bool get C => _input.C;
  @override bool get D => _input.D;
  @override bool get E => _input.E;
  @override bool get F => _input.F;
  @override bool get G => _input.G;
  @override bool get H => _input.H;
  @override bool get I => _input.I;
  @override bool get J => _input.J;
  @override bool get K => _input.K;
  @override bool get L => _input.L;
  @override bool get M => _input.M;
  @override bool get N => _input.N;
  @override bool get O => _input.O;
  @override bool get P => _input.P;
  @override bool get Q => _input.Q;
  @override bool get R => _input.R;
  @override bool get S => _input.S;
  @override bool get T => _input.T;
  @override bool get U => _input.U;
  @override bool get V => _input.V;
  @override bool get W => _input.W;
  @override bool get X => _input.X;
  @override bool get Y => _input.Y;
  @override bool get Z => _input.Z;

  // Modifier key shortcuts.

  @override bool get ctrlA => _input.ctrlA;
  @override bool get ctrlB => _input.ctrlB;
  @override bool get ctrlC => _input.ctrlC;
  @override bool get ctrlD => _input.ctrlD;
  @override bool get ctrlE => _input.ctrlE;
  @override bool get ctrlF => _input.ctrlF;
  @override bool get ctrlG => _input.ctrlG;
  @override bool get ctrlH => _input.ctrlH;
  @override bool get ctrlI => _input.ctrlI;
  @override bool get ctrlJ => _input.ctrlJ;
  @override bool get ctrlK => _input.ctrlK;
  @override bool get ctrlL => _input.ctrlL;
  @override bool get ctrlM => _input.ctrlM;
  @override bool get ctrlN => _input.ctrlN;
  @override bool get ctrlO => _input.ctrlO;
  @override bool get ctrlP => _input.ctrlP;
  @override bool get ctrlQ => _input.ctrlQ;
  @override bool get ctrlR => _input.ctrlR;
  @override bool get ctrlS => _input.ctrlS;
  @override bool get ctrlT => _input.ctrlT;
  @override bool get ctrlU => _input.ctrlU;
  @override bool get ctrlV => _input.ctrlV;
  @override bool get ctrlW => _input.ctrlW;
  @override bool get ctrlX => _input.ctrlX;
  @override bool get ctrlY => _input.ctrlY;
  @override bool get ctrlZ => _input.ctrlZ;

  // Navigation / special key shortcuts.

  @override bool get up => _input.up;
  @override bool get down => _input.down;
  @override bool get left => _input.left;
  @override bool get right => _input.right;
  @override bool get pageUp => _input.pageUp;
  @override bool get pageDown => _input.pageDown;
  @override bool get home => _input.home;
  @override bool get end => _input.end;
  @override bool get escape => _input.escape;
  @override bool get delete => _input.delete;
  @override bool get backspace => _input.backspace;
  @override bool get enter => _input.enter;
  @override bool get space => _input.space;
  
  // Function key shortcuts.

  @override bool get f1 => _input.f1;
  @override bool get f2 => _input.f2;
  @override bool get f3 => _input.f3;
  @override bool get f4 => _input.f4;

  // Number key shortcuts.

  @override bool get num0 => _input.num0;
  @override bool get num1 => _input.num1;
  @override bool get num2 => _input.num2;
  @override bool get num3 => _input.num3;
  @override bool get num4 => _input.num4;
  @override bool get num5 => _input.num5;
  @override bool get num6 => _input.num6;
  @override bool get num7 => _input.num7;
  @override bool get num8 => _input.num8;
  @override bool get num9 => _input.num9;

  /// Returns whether or not the given char is currently held down.
  @override
  bool key(final String key) => _input.key(key);

  /// Returns the last typed character's char value. This WILL NOT return modifier key events, or other special input. If you want to know
  /// about those events, you should poll for them using the shortcut methods defined in [DascadeNativeInput].
  @override
  String? get lastInputChar => _input.last;

  // //////////////////////////////////////////////
  // OUTPUT API
  // //////////////////////////////////////////////
  
  /// Begins a new rendering frame.
  ///
  /// Must be called before issuing any draw commands.
  @override
  void beginFrame() {
    _renderer.begin();
    _ui.begin();
  }
  
  /// The current width of the available rendering plane.
  @override
  int get width => _renderer.width;

  /// The current height of the available rendering plane.
  @override
  int get height => _renderer.height;

  /// Draws a single cell into the current frame buffer. This is the most primitive way of rendering through Dascade.
  ///
  /// This method writes only to the front buffer. The cell will not
  /// appear on screen until [end] is called.
  /// 
  /// The renderer will automatically deny requests for any draw call
  /// outside the boundaries of the current rendering plane.
  /// 
  /// Dascade Coordinate System:
  /// 
  /// Left                        Right
  /// --------------------------------- Top
  /// | (0, 0)                        |
  /// |                               |
  /// |                               |
  /// |                               |
  /// |                               |
  /// |                               |
  /// |       (width - 1, height - 1) |
  /// --------------------------------- Bottom
  /// 
  @override
  void draw(final int x, final int y, final int cell) {
    _renderer.draw(x, y, cell);
  }

  /// Ends the current frame, computes diffs, and renders changes.
  @override
  void endFrame() {
    _renderer.end();
    _ui.end();
    _input.flush();
  }

  /// beep :)
  /// 
  /// No guarentee this works on every terminal environment, but it certainly works on most native shells.
  @override
  void beep() => _terminal.beep();

  // //////////////////////////////////////////////
  // PRIVATE (NOT API!)
  // ///////////////////////////////////////////////

  /// Watches POSIX-style signals and safely shuts Dascade down to restore funcationality to the user's terminal.
  void _installSignalHandlers(final DascadeNative dascade) {
    if(Platform.isWindows) {
      /// POSIX-style runtimes operate in raw mode; SIGINT is not supported in that case. You must
      /// listen for Ctrl+C in application code on those platforms.
      ProcessSignal.sigint.watch().listen((_) {
        dascade._dispose();
      });
    } else {
      /// Windows PATCH: most windows-based terminals don't support sigterm listeners.
      ProcessSignal.sigterm.watch().listen((_) {
        dascade._dispose();
      });
    }
  }

  /// Disposes of runtime artifacts and gives user back control of their terminal. This should be called in every project at the end of runtime.
  void _dispose() {
    _terminal.disableInput();
    _input.stop();
    _terminal.cleanup();
    stdout.flush().then((_) {
      _activeInstance = false;
      exit(0);
    });
  }

}
