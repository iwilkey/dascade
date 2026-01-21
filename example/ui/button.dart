/// Demonstration of button interaction in Dascade UI.
library;

import 'dart:async';

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/elements/button/button.dart';
import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/elements/layout/spacer.dart';
import 'package:dascade/src/ui/elements/text/textbox.dart';
import 'package:dascade/src/ui/geometry/layout/layout.dart';

Future<void> main() async {

  await Dascade.run((d) async {
    d.forceNoSidecar = true;
    bool running = true;

    // Create UI elements with persistent state outside the main loop...

    final DUTextBox text = DUTextBox(
      initialText: "Try clicking the button (or focusing and pressing 'enter')...\n",
      border: true,
      editable: false,
    );

    final DUButton button = DUButton(label: "Press Me!");

    // Main UI loop
    while (running) {
      if(d.escape) running = false;

      d.beginFrame();
      
      /// Simple layout:
      /// A large vertical column that extends the entire rendering plane, with the text box taking up
      /// 80% of the space, then a simple spacer at 1% of the remaining space and button at 19%.
      d.ui.column(
        <DUElement>[
          text,
          DUSpacer(color: 0),
          button
        ],
        layout: DULayout.custom([0.80, 0.01, 0.19]),
        gap: 0,
        pad: 0,
      );

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
