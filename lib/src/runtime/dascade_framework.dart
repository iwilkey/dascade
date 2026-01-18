/// Immediate-mode renderer for Dascade.
///
/// Defines the [Dascade] class, which is the main interface for Dascade; syncing rendering state
/// and terminal peripherals.
library;

import 'dart:async';

typedef DascadeApp = Future<void> Function(DascadeFramework d);

/// The main interface of Dascade. All framework calls should be made through this object.
/// 
/// It's main function is to dispatch high-level API calls to the correct Dascade modules.
abstract class DascadeFramework {

  // //////////////////////////////////////////////
  // CONFIGURATION
  // ///////////////////////////////////////////////

  /// Whether or not Sidecar is allowed to bind during print() statements. If you decide to opt-out of Sidecar, your
  /// print statements will essentially be completely ignored. Note that you need to ensure you set this state before
  /// your first print statement invokes, otherwise it will do nothing but ignore statements.
  set forceNoSidecar(final bool ns);

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
  set allowRightMouseCallbackStateTracking(final bool state);

  // //////////////////////////////////////////////
  // INPUT API
  // //////////////////////////////////////////////
  
  /// Returns the current mouse X position (hovering supported)
  int get mouseX;

  /// Returns the current mouse Y position (hovering supported)
  int get mouseY;

  /// Returns the current state of the left mouse button.
  bool get mouseLeftDown;
  
  /// Returns the current state of the middle mouse button.
  bool get mouseMiddleDown;
  
  /// Returns the current state of the right mouse button.
  bool get mouseRightDown;

  /// Returns the current state of the mouse's scrollwheel value.
  /// 
  /// By Dascade convention, a value < 0 means "your finger is coming toward you" and > 0 means "your finger is going away from you" on vertical-only mice.
  /// 
  /// That said, you can easily invert by multipling the value by negative 1.
  int get mouseScrollwheelValue;

  // Lowercase key shortcuts.

  bool get a;
  bool get b;
  bool get c;
  bool get d;
  bool get e;
  bool get f;
  bool get g;
  bool get h;
  bool get i;
  bool get j;
  bool get k;
  bool get l;
  bool get m;
  bool get n;
  bool get o;
  bool get p;
  bool get q;
  bool get r;
  bool get s;
  bool get t;
  bool get u;
  bool get v;
  bool get w;
  bool get x;
  bool get y;
  bool get z;

  // Uppercase key shortcuts (Shift+Letter)

  bool get A;
  bool get B;
  bool get C;
  bool get D;
  bool get E;
  bool get F;
  bool get G;
  bool get H;
  bool get I;
  bool get J;
  bool get K;
  bool get L;
  bool get M;
  bool get N;
  bool get O;
  bool get P;
  bool get Q;
  bool get R;
  bool get S;
  bool get T;
  bool get U;
  bool get V;
  bool get W;
  bool get X;
  bool get Y;
  bool get Z;

  // Modifier key shortcuts.

  bool get ctrlA;
  bool get ctrlB;
  bool get ctrlC;
  bool get ctrlD;
  bool get ctrlE;
  bool get ctrlF;
  bool get ctrlG;
  bool get ctrlH;
  bool get ctrlI;
  bool get ctrlJ;
  bool get ctrlK;
  bool get ctrlL;
  bool get ctrlM;
  bool get ctrlN;
  bool get ctrlO;
  bool get ctrlP;
  bool get ctrlQ;
  bool get ctrlR;
  bool get ctrlS;
  bool get ctrlT;
  bool get ctrlU;
  bool get ctrlV;
  bool get ctrlW;
  bool get ctrlX;
  bool get ctrlY;
  bool get ctrlZ;

  // Navigation / special key shortcuts.

  bool get up;
  bool get down;
  bool get left;
  bool get right;
  bool get pageUp;
  bool get pageDown;
  bool get home;
  bool get end;
  bool get escape;
  bool get delete;
  bool get backspace;
  bool get space;

  // Function key shortcuts.

  bool get f1;
  bool get f2;
  bool get f3;
  bool get f4;

  // Number key shortcuts.

  bool get num0;
  bool get num1;
  bool get num2;
  bool get num3;
  bool get num4;
  bool get num5;
  bool get num6;
  bool get num7;
  bool get num8;
  bool get num9;

  /// Returns whether or not the given char is currently held down.
  bool key(final String key);

  /// Returns the last typed character's char value. This WILL NOT return modifier key events, or other special input. If you want to know
  /// about those events, you should poll for them using the shortcut methods defined in [DascadeNativeInput].
  String? get lastInputChar;

  // //////////////////////////////////////////////
  // OUTPUT API
  // //////////////////////////////////////////////
  
  /// Begins a new rendering frame.
  ///
  /// Must be called before issuing any draw commands.
  void beginFrame();
  
  /// The current width of the available rendering plane.
  int get width;

  /// The current height of the available rendering plane.
  int get height;

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
  void draw(final int x, final int y, final int cell);

  /// Ends the current frame, computes diffs, and renders changes.
  void endFrame();

  /// beep :)
  /// 
  /// No guarentee this works on every terminal environment, but it certainly works on most native shells.
  void beep();

}
