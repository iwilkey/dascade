/// Platform agnostic rendering system interface for Dascade.
///
/// This interface defines the public API exposed to application code
/// for issuing rendering commands. Implementations manage internal
/// buffering, frame lifecycle, and platform specific output.
library;

/// Defines the renderer contract for Dascade.
///
/// Renderers follow a strict frame based lifecycle. Drawing commands
/// are issued between [begin] and [end] calls and are applied using
/// buffered, differential rendering.
abstract interface class DascadeRenderingInterface {

  /// Begins a new rendering frame.
  ///
  /// This must be called before issuing any draw commands.
  void begin();

  /// Ends the current rendering frame.
  ///
  /// Implementations compute differences and emit the resulting output
  /// to the underlying terminal backend.
  void end();

  /// The current width of the available rendering plane.
  int get width;

  /// The current height of the available rendering plane.
  int get height;

  /// Draws a single cell into the current frame buffer. This is the most primitive way of rendering through Dascade.
  ///
  /// This method writes only to the front buffer. The cell will not
  /// appear on screen until [end] is called.
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
  void draw(int x, int y, int cell);

  /// Disposes of renderer resources.
  ///
  /// This is intended for platform specific cleanup that cannot be
  /// handled by garbage collection alone.
  void dispose();

}
