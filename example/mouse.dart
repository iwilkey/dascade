/// Showcases Dascade's handle of mouse input polling, both from Mouse and Keyboard. This is not to showcase UI functionality; 
/// See other examples for that.
library;

import 'dart:math';
import 'package:dascade/dascade.dart';

/// Example of Dascade's handle of mouse input polling.
Future<void> main() async {

  /// Everytime you want to use Dascade, this is the only correct way to create a new runtime. Your application lives inside
  /// of run()'s callback function.
  await Dascade.run((final Dascade dascade) async {
    
    /// I'm testing with VS code's integrated terminal, so I need this. You might not, especially if this is running in a native
    /// terminal instance.
    dascade.allowRightMouseCallbackStateTracking = false;

    /// Dascade is an immediate-mode framework; this means it draws information as your program runs. Because of this,
    /// it's best practice to define your main thread loop like the one below.
    bool running = true;

    /// Number of subdivisions extending outward from the cursor cross.
    int subdivisions = 1;

    while(running) {
      /// Dascade offers an extremely simple terminal Input API.
      if(dascade.escape) running = false; /// This statement returns true while the "Escape" key is pressed down.
      /// Every time you'd like to issue draw calls to Dascade, you must begin your frame as such.
      dascade.beginFrame();
      /// Scroll wheel dynamically increases / decreases subdivision count.
      subdivisions += dascade.mouseScrollwheelValue;
      subdivisions = subdivisions.clamp(1, 12);
      /// Capture terminal dimensions at render-time to stay responsive to resizes.
      final int width = dascade.width;
      final int height = dascade.height;
      /// Clamp mouse position into bounds (important when resizing).
      final int mx = dascade.mouseX.clamp(0, max(0, width - 1));
      final int my = dascade.mouseY.clamp(0, max(0, height - 1));
      /// Determine color based on button state.
      int fgColor = 39; // default white
      if(dascade.mouseLeftDown) fgColor = 46;   // cyan
      if(dascade.mouseMiddleDown) fgColor = 226; // yellow
      if(dascade.mouseRightDown) fgColor = 196;  // red
      /// Draw a vertical and horizontal cross centered at the mouse position.
      for (int x = 0; x < width; x++) {
        final int cell = DascadeCell.encode(
          glyph: '-'.codeUnitAt(0),
          fg: fgColor,
          bg: 0,
        );
        dascade.draw(x, my, cell);
      }

      for (int y = 0; y < height; y++) {
        final int cell = DascadeCell.encode(
          glyph: '|'.codeUnitAt(0),
          fg: fgColor,
          bg: 0,
        );
        dascade.draw(mx, y, cell);
      }
      /// Draw subdivision markers radiating from the cursor.
      for(int i = 1; i <= subdivisions; i++) {
        final int dx = i * 2;
        final int dy = i;
        final List<(int, int)> points = [
          (mx + dx, my),
          (mx - dx, my),
          (mx, my + dy),
          (mx, my - dy),
        ];
        for(final (int px, int py) in points) {
          if(px < 0 || px >= width || py < 0 || py >= height) continue;
          final int cell = DascadeCell.encode(
            glyph: '+'.codeUnitAt(0),
            fg: fgColor,
            bg: 0,
          );
          dascade.draw(px, py, cell);
        }
      }
      /// Mark the exact mouse position last so it appears on top.
      if(mx >= 0 && mx < width && my >= 0 && my < height) {
        final int cell = DascadeCell.encode(
          glyph: 'X'.codeUnitAt(0),
          fg: 15,
          bg: fgColor,
        );
        dascade.draw(mx, my, cell);
      }
      /// When you're done issuing draw calls, make sure to call endFrame()
      /// so you can see your picture render in the terminal!
      dascade.endFrame();
      /// It's good practice to throttle your loop to ensure that your main thread isn't starved of resources.
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });

}
