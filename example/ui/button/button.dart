/// Demonstration of Dascade UI's [DUButton] element; a simple button.
library;

import 'dart:async';

/// You're gonna need this ;)
import 'package:dascade/dascade.dart';

Future<void> main() async {

  /// Remember, Dascade always requires the following framework entry point!
  await Dascade.run((d) async {

    /// Application run state.
    bool running = true;

    // Remember, Dascade UI works by creating UI elements with persistent state outside the main loop.

    final DUTextBox text = DUTextBox(
      initialText: "Try clicking the button (or focusing and pressing 'enter')...\n",
      border: true,
      editable: false,
    );

    final DUTextBox info = DUTextBox(
      borderLabel: "More Information",
      initialText: 'Button elements can trigger events upon completing a full press cycle, or provide continuous feedback while being actively depressed, enabling both discrete actions and responsive, real-time interaction handling.',
      border: true,
      editable: false,
    );

    final DUButton button = DUButton(label: "Press Me!", borderLabel: "Button");

    /// Remember, Dascade is an immediate-mode framework so an application loop is essential for
    /// proper usage.
    while (running) {

      /// Remember, it's always a good idea to have a clean application exit strategy!
      if(d.escape) running = false;

      /// Remember, Dascade requires beginFrame() before you issue any draw calls or UI!
      d.beginFrame();
      
      /// Remember, if you're going to have UI this frame, you must always supply a root()!
      d.ui.root(
        d.ui.column(
          <DUElement>[
            text,
            d.ui.row([
              info,
              button,
            ], layout: DULayout.flex([14, 8]))
          ],
          layout: DULayout.custom([0.90, 0.10]),
          gap: 0,
          pad: 0,
        )
      );

      /// Remember, Dascade always requires an explicit endFrame() to flush drawn elements to the screen!
      d.endFrame();

      /// You can now query button state live in your application loop...
      if(button.fire) { /// Returns true if the button has been completely pressed (down -> up, in the button's encapsulating rect.)
        text.text += "f\n";
      }
      if(button.down) { /// Returns true while the button is held down (best for real-time cursor interaction.)
        text.text += "d";
      }
      

      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}
