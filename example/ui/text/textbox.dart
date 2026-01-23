/// Showcases Dascade UI's [DUTextBox] element; a editable (or read-only) canvas to render
/// plaintext.
library;

import 'dart:async';
import 'dart:math' as math;

/// You're gonna need this ;)
import 'package:dascade/dascade.dart';

Future<void> main() async {

  int lt = DateTime.now().millisecondsSinceEpoch;
  
  /// Remember, Dascade always requires the following framework entry point!
  await Dascade.run((d) async {

    /// Application run state.
    bool running = true;

    // Remember, Dascade UI works by creating UI elements with persistent state outside the main loop.

    final DUTextBox element0 = DUTextBox(
      initialText: "Simple borderless text box. Type in me! Try making me say 'quit'...",
      border: false,
      editable: true,
    );

    final DUTextBox element1 = DUTextBox(
      initialText: "Simple text box. You cannot type in me. Watch me grow with data!",
      border: true,
      editable: false,
    );

    final DUTextBox element2 = DUTextBox(
      initialText: "Smaller non-editable text box.",
      border: true,
      editable: false,
    );

    final DUTextBox element3 = DUTextBox(
      borderLabel: "Custom Border Label",
      initialText: "Smaller non-editable text box.",
      border: true,
      editable: false,
    );

    final DUTextBox element4 = DUTextBox(
      initialText: "Simple bordered text box. Type in me!",
      border: true,
      editable: true,
    );

    /// Remember, Dascade is an immediate-mode framework so an application loop is essential for
    /// proper usage.
    while(running) {
      
      /// Remember, it's always a good idea to have a clean application exit strategy!
      if(d.escape) running = false;

      /// Remember, Dascade requires beginFrame() before you issue any draw calls or UI!
      d.beginFrame();

      /// Remember, if you're going to have UI this frame, you must always supply a root()!
      d.ui.root(
        // Layout: row with 3 children.
        // - First: full-width editable textbox (element0)
        // - Second: vertical column of 3 readonly boxes (element1-3)
        // - Third: full-width editable textbox (element4)
        d.ui.row(
          <DUElement>[
            element0,
            d.ui.column(
              <DUElement>[
                element1, 
                element2, 
                element3
              ],
              layout: DULayout.custom([0.6, 0.2, 0.2]),
              gap: 0,
              pad: 0,
            ),
            element4,
          ],
          layout: DULayout.equal(),
          gap: 0,
          pad: 0,
        )
      );

      /// Remember, Dascade always requires an explicit endFrame() to flush drawn elements to the screen!
      d.endFrame();

      // Global signal to quit.
      if(element0.text == "quit") running = false;
      if(DateTime.now().millisecondsSinceEpoch - lt > 1000) {
        element1.text += "\n${math.Random().nextInt(100).toString()}";
        lt = DateTime.now().millisecondsSinceEpoch;
      }

      /// Remember, it's always a good idea to throttle the frame rate!
      await Future.delayed(const Duration(milliseconds: 16));

    }
  });
}
