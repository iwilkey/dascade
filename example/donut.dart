/// Showcases Dascade's excellent handle of primitive rendering and performance. This is not to showcase UI functionality; 
/// See other examples for that.
library;

import 'dart:math';
import 'package:dascade/dascade.dart';

/// Example of Dascade's excellent handle of primitive rendering and performance capabilities.
/// Author: Ian Wilkey
Future<void> main() async {

  /// Everytime you want to use Dascade, this is the only correct way to create a new runtime. Your application lives inside
  /// of run()'s callback function.
  await Dascade.run((final DascadeFramework dascade) async {
    
    dascade.forceNoSidecar = true;

    /// Sure, I'll take a donut.
    final Donut donut = Donut();
  
    /// Dascade is an immediate-mode framework; this means it draws information as your program runs. Because of this,
    /// it's best practice to define your main thread loop like the one below.
    bool running = true;

    /// Let's count the frames. For fun. And because I want to show you Sidecar.
    int frames = 0;

    while(running) {

      /// Dascade offers an extremely simple terminal Input API. Here's a couple rules we'll poll for to exit the application.
      if(dascade.escape) running = false;

      /// Every time you'd like to issue draw calls to Dascade, you must begin your frame as such.
      dascade.beginFrame();

      /// All of your draw calls exist inside, like so.
      donut.draw(dascade);

      /// When you're done issue draw calls, make sure to call endFrame() so you can see your picture render in the terminal!
      dascade.endFrame();

      /// Let's go ahead and update the Donut's internal state for the next frame. In this case, we're just rotating it.
      donut.update();

      /// It's good practice to throttle your loop to ensure that your main thread isn't starved of resources.
      await Future.delayed(const Duration(milliseconds: 16));

      /// Dascade Native CAN handle print() statements! It just does so with the "Sidecar" system. After the first print() statement is
      /// invoked, a new Sidecar instance (your platform's native terminal) will popup and show you all statements thereafter in
      /// real-time. Note you may opt-out of Sidecar by using dascade.forceNoSidecar = true, but make sure to set that before your first print
      /// statement is invoked.
      /// 
      /// On web-based runtimes, you can just use the developer tools to see your print statements.
      frames++;
      if(frames % 10 == 0) {
        /// Before uncommenting this, set forceNoSidecar to false to open Sidecar!
        //print("Frame: $frames");
      }
    }
  });

}

/// This is a one-to-one Dart port of Aikon's donut.c found here: https://www.a1k0n.net/2011/07/20/donut-math.html
/// 
/// It also includes an example of using Dascade's primitive rendering API correctly.
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
  void draw(final DascadeFramework dascade) {

    /// Capturing the current dimensions of your rendering plane right before draw calls is a great way to enture that
    /// your pictures remain responsive during terminal resize events.
    final int width = dascade.width;
    final int height = dascade.height;

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

            /// Finally, we issue our draw call. This adds one cell to the next frame buffer, ready to be blitted.
            dascade.draw(xp, yp, cell);
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
