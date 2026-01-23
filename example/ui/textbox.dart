/// Showcases Dascade's UI layout system, basic API syntax, and the management of elements (in this case,
/// a bunch of simple textboxes.)
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dascade/dascade.dart';

Future<void> main() async {
  int lt = DateTime.now().millisecondsSinceEpoch;
  await Dascade.run((d) async {
    d.forceNoSidecar = true;
    bool running = true;

    // Create UI elements with persistent state outside the main loop...

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

    // Main UI loop
    while (running) {
      if(d.escape) running = false;
      d.beginFrame();
      // Layout: row with 3 children.
      // - First: full-width editable textbox (element0)
      // - Second: vertical column of 3 readonly boxes (element1-3)
      // - Third: full-width editable textbox (element4)
      d.ui.row(
        <DUElement>[
          element0,
          d.ui.column(
            <DUElement>[element1, element2, element3],
            layout: DULayout.custom([0.6, 0.2, 0.2]),
            gap: 0,
            pad: 0,
          ),
          element4,
        ],
        layout: DULayout.equal(),
        gap: 0,
        pad: 0,
      );
      d.endFrame();
      // Global signal to quit.
      if(element0.text == "quit") running = false;
      if(DateTime.now().millisecondsSinceEpoch - lt > 1000) {
        element1.text += "\n${math.Random().nextInt(100).toString()}";
        lt = DateTime.now().millisecondsSinceEpoch;
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}
