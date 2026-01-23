/// Demonstration of Dascade UI's [DURadio] element; a button type that retains state until it is
/// toggled again.
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
      initialText: 'Select one or more radios below.\n'
          'Click or focus + press Enter to toggle.\n',
      border: true,
      editable: false,
    );

    final DUTextBox info = DUTextBox(
      borderLabel: "More Information",
      initialText: 'Radio elements are well suited for settings, item selection, and variable monitoring, as they maintain their state until explicitly changed through user interaction or programmatic control.',
      border: true,
      editable: false,
    );

    final DURadio radio0 = DURadio(label: 'Option A', border: true, state: false, borderLabel: "Radio");
    final DURadio radio1 = DURadio(label: 'Option B', border: true, state: false, borderLabel: "Radio");
    final DURadio radio2 = DURadio(label: 'Option C', border: true, state: false, borderLabel: "Radio");
    final DURadio radio3 = DURadio(label: 'Option D', border: true, state: false, borderLabel: "Radio");

    /// Let's track state over frames to ensure we print only when states change.
    bool r0s = false;
    bool r1s = false;
    bool r2s = false;
    bool r3s = false;

    /// Remember, Dascade is an immediate-mode framework so an application loop is essential for
    /// proper usage.
    while(running) {

      /// It's always a good idea to have a clean application exit strategy!
      if(d.escape) running = false;

      /// Remember, Dascade requires beginFrame() before you issue any draw calls or UI!
      d.beginFrame();
      
      /// Remember, if you're going to have UI this frame, you must always supply a root()!
      d.ui.root(
        d.ui.column(
          <DUElement>[
            text,
            d.ui.row([
              d.ui.column([
                radio0,
                radio1,
                radio2,
                radio3
              ], layout: DULayout.equal()),
              info
            ], layout: DULayout.flex([2, 8]))
          ],
          layout: DULayout.flex([2, 1]),
          gap: 0,
          pad: 0,
        )
      );
      
      /// Remember, Dascade always requires an explicit endFrame() to flush drawn elements to the screen!
      d.endFrame();

      /// Simple state machine and output of radio states to our text canvas.
      if(r0s != radio0.state) {
        r0s = radio0.state;
        text.text += "\nRadio 0: $r0s";
      }
      /// radio.value() is the same as radio.state; whatever makes more sense to you!
      if(r1s != radio1.value()) {
        r1s = radio1.state;
        text.text += "\nRadio 1: $r1s";
      }
      if(r2s != radio2.state) {
        r2s = radio2.state;
        text.text += "\nRadio 2: $r2s";
      }
      if(r3s != radio3.value()) {
        r3s = radio3.state;
        text.text += "\nRadio 3: $r3s";
      }
      
      /// Remember, it's always a good idea to throttle the frame rate!
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}
