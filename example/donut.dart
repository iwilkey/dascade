import 'dart:math';
import 'package:dascade/dascade.dart';

Future<void> main() async {
  final Dascade d = Dascade();

  // Rotation angles
  double A = 0.0;
  double B = 0.0;

  // Constants (classic donut)
  const double thetaSpacing = 0.07;
  const double phiSpacing = 0.02;
  const double r1 = 1.0;
  const double r2 = 2.0;
  const double k2 = 100.0;

  const String luminance = '.,-~:;=!*#\$@';

  bool running = true;

  while(running) {
    if (d.escape) break;

    d.beginFrame();

    final int width = d.width;
    final int height = d.height;

    // Derived projection constant
    final double zoom = 0.5; // < 1 = zoom out, > 1 = zoom in
    final double k1 = width * k2 * 3 / (8 * (r1 + r2)) * zoom;

    // Z-buffer
    final List<double> zbuf =
        List<double>.filled(width * height, 0.0);

    final double cosA = cos(A), sinA = sin(A);
    final double cosB = cos(B), sinB = sin(B);

    for (double theta = 0; theta < 2 * pi; theta += thetaSpacing) {
      final double costheta = cos(theta);
      final double sintheta = sin(theta);

      for (double phi = 0; phi < 2 * pi; phi += phiSpacing) {
        final double cosphi = cos(phi);
        final double sinphi = sin(phi);

        final double circlex = r2 + r1 * costheta;
        final double circley = r1 * sintheta;

        final double x =
            circlex * (cosB * cosphi + sinA * sinB * sinphi) -
            circley * cosA * sinB;
        final double y =
            circlex * (sinB * cosphi - sinA * cosB * sinphi) +
            circley * cosA * cosB;
        final double z =
            k2 + cosA * circlex * sinphi + circley * sinA;

        final double ooz = 1 / z;

        const double aspect = 2.0; // try 1.5–2.5 depending on font

        final int xp =
            (width / 2 + aspect * k1 * ooz * x).toInt();
        final int yp =
            (height / 2 - k1 * ooz * y).toInt();

        if (xp < 0 || xp >= width || yp < 0 || yp >= height) {
          continue;
        }

        final double L =
            cosphi * costheta * sinB -
            cosA * costheta * sinphi -
            sinA * sintheta +
            cosB * (cosA * sintheta - costheta * sinA * sinphi);

        if (L > 0) {
          final int idx = xp + yp * width;
          if (ooz > zbuf[idx]) {
            zbuf[idx] = ooz;

            final int lumIndex =
                min((L * 8).toInt(), luminance.length - 1);

            final int cell = DascadeCell.encode(
              glyph: luminance.codeUnitAt(lumIndex),
              fg: 14,
              bg: 0,
            );

            d.draw(xp, yp, cell);
          }
        }
      }
    }

    d.endFrame();

    // Rotate
    A += 0.04;
    B += 0.02;

    // ~60 FPS
    await Future.delayed(const Duration(milliseconds: 16));
  }

  d.dispose();
}
