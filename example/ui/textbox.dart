/// Showcases Dascade's UI system. THIS IS EXPERIMENTAL IN THIS COMMIT.
///
/// This example demonstrates how to define and arrange UI elements using
/// the Dascade immediate-mode UI framework. It highlights persistent
/// state, layout composition (row/column), editable vs non-editable elements,
/// and frame lifecycle usage.
///
/// This file intentionally avoids external layout managers or declarative
/// UI systems. Instead, it leans on the low-level primitives exposed by
/// `DascadeUI`, including layout weights and rendering control.
library;

import 'dart:async';

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/elements/text/text_box.dart';
import 'package:dascade/src/ui/geometry/layout/layout.dart';

Future<void> main() async {
  await Dascade.run((d) async {
    d.forceNoSidecar = true;
    bool running = true;

    // Create UI elements with persistent state outside the main loop.
    final DUTextBox element0 = DUTextBox(
      initialText: "Simple borderless text box. Type in me! Try making me say 'quit'...",
      border: false,
      editable: true,
    );

    final DUTextBox element1 = DUTextBox(
      initialText: "Simple text box. You cannot type in me.",
      border: true,
      editable: false,
    );

    final DUTextBox element2 = DUTextBox(
      initialText: "Smaller non-editable text box.",
      border: true,
      editable: false,
    );

    final DUTextBox element3 = DUTextBox(
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
      if (d.escape) running = false;

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

      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}
