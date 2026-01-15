/// Immediate-mode renderer for Dascade.
///
/// Defines the [Dascade] class, which is the main interface for Dascade; syncing rendering state
/// and terminal peripherals.
library;

import 'dart:async';
import 'dart:io';

import 'package:dascade/src/input/input.dart';
import 'package:dascade/src/output/renderer.dart';
import 'package:dascade/src/sidecar/sidecar.dart';
import 'package:dascade/src/output/terminal.dart';

typedef DascadeApp = Future<void> Function(Dascade d);

/// The main interface of Dascade. All framework calls should be made through this object.
/// 
/// It's main function is to dispatch high-level API calls to the correct Dascade modules.
final class Dascade {

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
  late final DascadeTerminal _terminal;

  /// The origin of the renderer interface for Dascade. This class should be the only class that
  /// instantiates it.
  late final DascadeRenderer _renderer;

  /// The origin of the input module of Dascade. This class should be the only class that
  /// instantiates it.
  late final DascadeInput _input;

  /// Constructs the Dascade object at beginning of application runtime.
  Dascade._internal() {
    if(_activeInstance) {
      throw Exception("Only one Dascade instance allowed.");
    }
    _terminal = DascadeTerminal()..enableMouse();
    _renderer = DascadeRenderer(_terminal);
    _input = DascadeInput()..start();
    _activeInstance = true;
    _installSignalHandlers(this);
  }

  // //////////////////////////////////////////////
  // ENTRY API
  // //////////////////////////////////////////////

  /// Runs a new instance of Dascade. It defines the main entry point to every Dascade application and is the only
  /// correct usage of initializing a runtime of Dascade. See examples or API documentation on how to use it correctly.
  static Future<void> run(final DascadeApp app) async {
    late Dascade d;
    await runZonedGuarded(() async {
      d = Dascade._internal();
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
  set allowRightMouseCallbackStateTracking(final bool state) => _input.allowRightMouseCallbackStateTracking = state;

  // //////////////////////////////////////////////
  // INPUT API
  // //////////////////////////////////////////////
  
  /// Returns the current mouse X position (hovering supported)
  int get mouseX => _input.mouseX;

  /// Returns the current mouse Y position (hovering supported)
  int get mouseY => _input.mouseY;

  /// Returns the current state of the left mouse button.
  bool get mouseLeftDown => _input.mouseLeftDown;
  
  /// Returns the current state of the middle mouse button.
  bool get mouseMiddleDown => _input.mouseMiddleDown;
  
  /// Returns the current state of the right mouse button.
  bool get mouseRightDown => _input.mouseRightDown;

  /// Returns the current state of the mouse's scrollwheel value.
  /// 
  /// By Dascade convention, a value < 0 means "your finger is coming toward you" and > 0 means "your finger is going away from you" on vertical-only mice.
  /// 
  /// That said, you can easily invert by multipling the value by negative 1.
  int get mouseScrollwheelValue => _input.mouseScrollwheelValue;

  // Lowercase key shortcuts.

  bool get a => _input.a;
  bool get b => _input.b;
  bool get c => _input.c;
  bool get d => _input.d;
  bool get e => _input.e;
  bool get f => _input.f;
  bool get g => _input.g;
  bool get h => _input.h;
  bool get i => _input.i;
  bool get j => _input.j;
  bool get k => _input.k;
  bool get l => _input.l;
  bool get m => _input.m;
  bool get n => _input.n;
  bool get o => _input.o;
  bool get p => _input.p;
  bool get q => _input.q;
  bool get r => _input.r;
  bool get s => _input.s;
  bool get t => _input.t;
  bool get u => _input.u;
  bool get v => _input.v;
  bool get w => _input.w;
  bool get x => _input.x;
  bool get y => _input.y;
  bool get z => _input.z;

  // Uppercase key shortcuts (Shift+Letter)

  bool get A => _input.A;
  bool get B => _input.B;
  bool get C => _input.C;
  bool get D => _input.D;
  bool get E => _input.E;
  bool get F => _input.F;
  bool get G => _input.G;
  bool get H => _input.H;
  bool get I => _input.I;
  bool get J => _input.J;
  bool get K => _input.K;
  bool get L => _input.L;
  bool get M => _input.M;
  bool get N => _input.N;
  bool get O => _input.O;
  bool get P => _input.P;
  bool get Q => _input.Q;
  bool get R => _input.R;
  bool get S => _input.S;
  bool get T => _input.T;
  bool get U => _input.U;
  bool get V => _input.V;
  bool get W => _input.W;
  bool get X => _input.X;
  bool get Y => _input.Y;
  bool get Z => _input.Z;

  // Modifier key shortcuts.

  bool get ctrlA => _input.ctrlA;
  bool get ctrlB => _input.ctrlB;
  bool get ctrlC => _input.ctrlC;
  bool get ctrlD => _input.ctrlD;
  bool get ctrlE => _input.ctrlE;
  bool get ctrlF => _input.ctrlF;
  bool get ctrlG => _input.ctrlG;
  bool get ctrlH => _input.ctrlH;
  bool get ctrlI => _input.ctrlI;
  bool get ctrlJ => _input.ctrlJ;
  bool get ctrlK => _input.ctrlK;
  bool get ctrlL => _input.ctrlL;
  bool get ctrlM => _input.ctrlM;
  bool get ctrlN => _input.ctrlN;
  bool get ctrlO => _input.ctrlO;
  bool get ctrlP => _input.ctrlP;
  bool get ctrlQ => _input.ctrlQ;
  bool get ctrlR => _input.ctrlR;
  bool get ctrlS => _input.ctrlS;
  bool get ctrlT => _input.ctrlT;
  bool get ctrlU => _input.ctrlU;
  bool get ctrlV => _input.ctrlV;
  bool get ctrlW => _input.ctrlW;
  bool get ctrlX => _input.ctrlX;
  bool get ctrlY => _input.ctrlY;
  bool get ctrlZ => _input.ctrlZ;

  // Navigation / special key shortcuts.

  bool get up => _input.up;
  bool get down => _input.down;
  bool get left => _input.left;
  bool get right => _input.right;
  bool get pageUp => _input.pageUp;
  bool get pageDown => _input.pageDown;
  bool get home => _input.home;
  bool get end => _input.end;
  bool get escape => _input.escape;
  bool get delete => _input.delete;
  bool get backspace => _input.backspace;

  // Function key shortcuts.

  bool get f1 => _input.f1;
  bool get f2 => _input.f2;
  bool get f3 => _input.f3;
  bool get f4 => _input.f4;

  // Number key shortcuts.

  bool get num0 => _input.num0;
  bool get num1 => _input.num1;
  bool get num2 => _input.num2;
  bool get num3 => _input.num3;
  bool get num4 => _input.num4;
  bool get num5 => _input.num5;
  bool get num6 => _input.num6;
  bool get num7 => _input.num7;
  bool get num8 => _input.num8;
  bool get num9 => _input.num9;

  /// Returns whether or not the given char is currently held down.
  bool key(final String key) => _input.key(key);

  /// Returns the last typed character's char value. This WILL NOT return modifier key events, or other special input. If you want to know
  /// about those events, you should poll for them using the shortcut methods defined in [DascadeInput].
  String? get lastInputChar => _input.last;

  // //////////////////////////////////////////////
  // OUTPUT API
  // //////////////////////////////////////////////
  
  /// Begins a new rendering frame.
  ///
  /// Must be called before issuing any draw commands.
  void beginFrame() {
    _renderer.begin();
  }
  
  /// The current width of the available rendering plane.
  int get width => _renderer.width;

  /// The current height of the available rendering plane.
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
  void draw(final int x, final int y, final int cell) {
    _renderer.draw(x, y, cell);
  }

  /// Ends the current frame, computes diffs, and renders changes.
  void endFrame() {
    _renderer.end();
    _input.flush();
  }

  /// beep :)
  /// 
  /// No guarentee this works on every terminal environment, but it certainly works on most native shells.
  void beep() => _terminal.beep();

  // //////////////////////////////////////////////
  // PRIVATE (NOT API!)
  // ///////////////////////////////////////////////

  /// Watches POSIX signals and safely shuts Dascade down to restore funcationality to the user's terminal.
  void _installSignalHandlers(final Dascade dascade) {
    ProcessSignal.sigint.watch().listen((_) {
      dascade._dispose();
    });
    ProcessSignal.sigterm.watch().listen((_) {
      dascade._dispose();
    });
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
