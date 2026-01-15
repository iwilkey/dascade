/// Immediate-mode renderer for Dascade.
///
/// Defines the [Dascade] class, which is the main interface for Dascade; syncing rendering state
/// and terminal peripherals.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/renderer.dart';
import 'package:dascade/src/terminal.dart';

/// The main interface of Dascade. All framework calls should be made through this object.
/// 
/// It's main function is to dispatch high-level API calls to the correct Dascade modules.
final class Dascade {

  /// The origin of the terminal interface for Dascade. This class should be the only class that
  /// instantiates it.
  late final DascadeTerminal _terminal;

  /// The origin of the renderer interface for Dascade. This class should be the only class that
  /// instantiates it.
  late final DascadeRenderer _renderer;

  /// The origin of the input module of Dascade. This class should be the only class that
  /// instantiates it.
  late final DascadeInput _input;

  Dascade() {
    /// Initializes backend modules to ready for terminal I/O.
    _terminal = DascadeTerminal();
    _renderer = DascadeRenderer(_terminal);
    _input = DascadeInput(_terminal)..start();
  }

  /// Begins a new rendering frame.
  ///
  /// Must be called before issuing any draw commands.
  void begin() {
    _renderer.begin();
  }

  /// Returns the current input module for input polling.
  DascadeInput get input => _input;
  
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
  void end() {
    _renderer.end();
  }

  /// Disposes of runtime artifacts and gives user back control of their terminal. This should be called in every project at the end of runtime.
  void dispose() {
    _renderer.dispose();
  }

}
