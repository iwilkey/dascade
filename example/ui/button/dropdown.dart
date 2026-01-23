/// Demonstration of Dascade UI's [element] element; [element desc]
library;

import 'dart:async';

/// You're gonna need this ;)
import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/elements/button/dropdown.dart';

Future<void> main() async {

  /// Remember, Dascade always requires the following framework entry point!
  await Dascade.run((d) async {

    /// Application run state.
    bool running = true;

    // Remember, Dascade UI works by creating UI elements with persistent state outside the main loop.

    final DUTextBox text = DUTextBox(
      borderLabel: "List View (Demo)",
      initialText: "Dropdowns are great for multiple-line text-based option menus where one selection is true until the next selection has been made.",
      border: true,
      editable: false,
    );

    final DUTextBox info = DUTextBox(
      borderLabel: "More Information",
      initialText: 'Dropdown menu elements allow selection from a list of plain text options and retain the selected state until a new choice is explicitly made by the user or programmatically updated.',
      border: true,
      editable: false,
    );

    final DUDropdown dd = DUDropdown(
      borderLabel: "Dropdown",
      label: 'Color',
      options: <String>[
        'Red', 
        'Orange', 
        'Yellow', 
        'Green', 
        'Blue', 
        'Indigo', 
        'Violet'
      ],
      border: true,
    );

    /// Remember, Dascade is an immediate-mode framework so an application loop is essential for
    /// proper usage.
    while(running) {

      /// It's always a good idea to have a clean application exit strategy!
      if(d.escape) running = false;

      /// Remember, Dascade requires beginFrame() before you issue any draw calls or UI!
      d.beginFrame();
      
      /// Remember, if you're going to have UI this frame, you must always supply a root()!
      d.ui.root(
        /// Define layout here.
        d.ui.column(
          [
            text,
            d.ui.row([
              dd.show(),
              info
            ], layout: DULayout.flex([5, 15]))
          ], layout: DULayout.flex([16, dd.open() ? 6 : 1]) /// Notice how I change the layout based on Dropdown state.
        )
      );
      
      /// Let's output the current dropdown menu state to the text field, for fun.
      if(dd.changed) {
        text.text += "\nNew color: ${dd.value()}";
      }
      
      /// Remember, Dascade always requires an explicit endFrame() to flush drawn elements to the screen!
      d.endFrame();

      /// Remember, it's always a good idea to throttle the frame rate!
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });

}
