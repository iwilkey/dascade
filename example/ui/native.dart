/// Demonstration of Dascade UI's powerful [DUNative] element; a sub-rendering canvas, laid out like any other UI element,
/// where one can draw on similar to Dascade's primitive
/// rendering features.
library;

import 'dart:async';
import 'dart:math';

import 'package:dascade/dascade.dart';

Future<void> main() async {

  await Dascade.run((d) async {

    /// I don't want Sidecar to open on print statements.
    d.forceNoSidecar = true;

    /// Should the app be running?
    bool running = true;

    /// Sure, I'll take a donut!
    final Donut donut = Donut();

    // Create UI elements with persistent state outside the main loop...

    /// Our native canvas where our donut will live.
    final DUNative native = DUNative(border: true);

    /// A text box showing FPS.
    final DUTextBox text = DUTextBox(
      borderLabel: "Frame Rate",
      initialText: "Let's do some Donuts!",
      border: true,
      editable: false,
    );

    /// Last time we showed an FPS message.
    int lt = DateTime.now().millisecondsSinceEpoch;

    // True FPS counters (average over ~1 second).
    int frames = 0;

    // Main UI loop
    while (running) {
      if(d.escape) running = false;
      d.beginFrame();
      /// Simple layout:
      /// A large vertical column that extends the entire rendering plane, with the native renderer taking up
      /// 80% and a text box taking up the remaining 20%.
      d.ui.column(
        <DUElement>[
          /// A native element is essentially just a sub-rendering canvas you can draw on similar to Dascade's primitive
          /// rendering features.
          native.draw((final int width, final int height, final DURenderer renderer) {
            donut.draw(width, height, renderer);
          }),
          text
        ],
        layout: DULayout.custom([0.80, 0.20]),
        gap: 0,
        pad: 0,
      );
      d.endFrame();
      donut.update();
      // True FPS: count frames and report average FPS over the last ~1 second.
      frames++;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int elapsed = now - lt;
      if(elapsed > 1000) {
        final double fps = frames * 1000.0 / elapsed;
        text.text += "\nFPS: ${fps.toStringAsFixed(1)}";
        lt = now;
        frames = 0;
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
  });
}

/// This is a one-to-one Dart port of Aikon's donut.c found here: https://www.a1k0n.net/2011/07/20/donut-math.html
/// 
/// It also includes an example of using Dascade's primitive rendering API correctly, in the context of 
/// the [DUNative] UI element.
final class Donut {
  
  static const double kAspectRatio  = 2.0;
  static const double kZoom         = 0.5;
  static const double kThetaSpacing = 0.07;
  static const double kPhiSpacing   = 0.02;
  static const double kR1           = 1.0;
  static const double kR2           = 2.0;
  static const double kK2           = 5.0;
  static const String kLuminance    = '.,-~:;=!*#\$@';

  double a = 0.0;
  double b = 0.0;

  Donut();

  /// Draws one frame of the Donut, based on current a, b rotation values.
  void draw(final int width, final int height, final DURenderer renderer) {

    /// 3D -> 2D = Linear alg. Oh boy.
    final List<double> zbuf = List<double>.filled(width * height, 0.0);
    final double k1 = width * kK2 * 3 / (8 * (kR1 + kR2)) * kZoom;
    final double cosA = cos(a), sinA = sin(a);
    final double cosB = cos(b), sinB = sin(b);
    for(double theta = 0; theta < 2 * pi; theta += kThetaSpacing) {
      /// Linear algebra, and more linear algebra...
      final double costheta = cos(theta);
      final double sintheta = sin(theta);
      for(double phi = 0; phi < 2 * pi; phi += kPhiSpacing) {
        final double cosphi = cos(phi);
        final double sinphi = sin(phi);
        final double circlex = kR2 + kR1 * costheta;
        final double circley = kR1 * sintheta;
        final double x = circlex * (cosB * cosphi + sinA * sinB * sinphi) -
                         circley * cosA * sinB;
        final double y = circlex * (sinB * cosphi - sinA * cosB * sinphi) +
                         circley * cosA * cosB;
        final double z = kK2 + cosA * circlex * sinphi + circley * sinA;
        final double ooz = 1 / z;
        final int xp = (width / 2 + kAspectRatio * k1 * ooz * x).toInt();
        final int yp = (height / 2 - k1 * ooz * y).toInt();
        if(xp < 0 || xp >= width || yp < 0 || yp >= height) {
          continue;
        }
        final double l = cosphi * costheta * sinB -
                         cosA * costheta * sinphi -
                         sinA * sintheta +
                         cosB * (cosA * sintheta - costheta * sinA * sinphi);
        if(l > 0) {
          final int idx = xp + yp * width;
          if(ooz > zbuf[idx]) {
            zbuf[idx] = ooz;
            final int lumIndex = min((l * 8).toInt(), kLuminance.length - 1);
            /// Okay, so we have just calculated xp and yp (position of cell), but Dascade needs to know WHAT to render. 
            /// Below is the most primitive way to define cell properties.
            final int cell = DascadeCell.encode(

              /// What simbol should be rendered? (in this case, one of . , - ~ : ; = ! * # $ @)
              glyph: kLuminance.codeUnitAt(lumIndex),

              /// What ANSI foreground color should it be rendered with? Dascade supports 256 ANSI colors.
              fg: 178,

              /// What ANSI background color should it be rendered on top of? Again, Dascade supports 256 ANSI colors.
              bg: 0,

            );
            /// Issue draw call to UI native renderer (just like Dascade!)
            renderer.draw(xp, yp, cell);
          }
        }
      }
    }
  }

  /// Update rotation for next frame.
  void update() {
    a += 0.04;
    b += 0.02;
  }

}
