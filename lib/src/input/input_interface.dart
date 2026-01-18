/// Platform-agnostic input interface for Dascade.
///
/// This interface defines the complete input surface exposed by Dascade.
/// All platform specific input implementations must implement this
/// interface exactly to ensure consistent behavior across native and
/// web targets.
///
/// Input is immediate-mode and frame-based. Key and mouse states are
/// accumulated during a frame and cleared by [flush].
library;

/// Platform-agnostic input interface for Dascade.
abstract interface class DascadeInputInterface {

  /// Starts listening for input events.
  ///
  /// Platform implementations should begin collecting keyboard and
  /// mouse state when this method is called.
  void start();

  /// Clears transient input state for the next frame.
  ///
  /// This resets per-frame key presses, mouse scroll state, and the
  /// last typed character.
  void flush();

  /// Stops listening for input events and releases any resources.
  void stop();

  /// Controls whether the right mouse button is treated as a stateful input.
  ///
  /// Some environments suppress right mouse release events. Disabling
  /// state tracking allows platforms to synthesize consistent behavior.
  set allowRightMouseCallbackStateTracking(bool state);

  /// Returns whether the given character key is currently held down.
  bool key(String key);

  /// Returns the last typed printable character.
  ///
  /// Modifier keys and special keys are not reported here.
  String? get last;

  /// Current mouse X position in terminal cell coordinates.
  int get mouseX;

  /// Current mouse Y position in terminal cell coordinates.
  int get mouseY;

  /// Returns whether the left mouse button is currently held down.
  bool get mouseLeftDown;

  /// Returns whether the middle mouse button is currently held down.
  bool get mouseMiddleDown;

  /// Returns whether the right mouse button is currently held down.
  bool get mouseRightDown;

  /// Returns the current mouse scroll wheel value for this frame.
  ///
  /// Positive and negative values indicate scroll direction.
  int get mouseScrollwheelValue;

  // Lowercase letter shortcuts.

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

  // Uppercase letter shortcuts.

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

  // Control key shortcuts.

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

  // Navigation and special keys.

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

}
