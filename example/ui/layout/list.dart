/// Demonstration of Dascade UI's [DUList] element; A scrollable, unbounded virtual space to assemble an arbirtary fixed-size
/// elements.
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
      borderLabel: "List View (Demo)",
      initialText: "The List View is one of Dascade's most powerful elements when it comes to layout!",
      border: true,
      editable: false,
    );

    final DUList vlist = DUList(border: true, borderLabel: "Vertical List");
    final DUList hlist = DUList(border: true, borderLabel: "Horizontal List", horizontal: true);

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
        d.ui.column([
          /// Have a text box take up the top half of the screen.
          text,
          /// Have the two lists side-by-side on the bottom half of the screen.
          d.ui.row([
            /// Show a vertical list of 32 different text box elements.
            vlist.show(
              [
                for(int i = 0; i < 32; i++) 
                  DUTextBox(
                    initialText: "Item $i",
                    border: true,
                    editable: true,
                  )
              ], itemSize: 3
            ),
            /// Show a horizontal list of 64 different text box elements, laid out in a column themselves.
            hlist.show(
              [
                for(int i = 0; i < 32; i++) ...[
                  d.ui.column([
                    DUTextBox(
                      initialText: "Top $i",
                      border: true,
                      editable: true,
                    ),
                    DUTextBox(
                      initialText: "Bottom $i",
                      border: true,
                      editable: true,
                    ),
                  ], layout: DULayout.equal())
                ]
              ], itemSize: 8
            ),

          ], layout: DULayout.equal())
        ], layout: DULayout.equal())
      );
      
      /// Remember, Dascade always requires an explicit endFrame() to flush drawn elements to the screen!
      d.endFrame();

      /// Remember, it's always a good idea to throttle the frame rate!
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });

}
