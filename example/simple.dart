import 'package:dascade/dascade.dart';

Future<void> main() async {
  final DascadeInterface dascade = DascadeInterface();
  int t = 0;
  while(true) {
    if(t > 2000) break;
    t++;
    dascade.begin();

    int h = dascade.height;
    int w = dascade.width;
    
    final int cell = DascadeCell.encode(
      glyph: '#'.codeUnitAt(0),
      fg: 10,
      bg: 0,
      bold: true,
    );

    // Top border (row 0)
    for (int col = 0; col < w; col++) {
      dascade.draw(0, col, cell);
    }

    // Bottom border (row h - 1)
    for (int col = 0; col < w; col++) {
      dascade.draw(h - 1, col, cell);
    }

    // Left border (column 0)
    for (int row = 0; row < h; row++) {
      dascade.draw(row, 0, cell);
    }

    // Right border (column w - 1)
    for (int row = 0; row < h; row++) {
      dascade.draw(row, w - 1, cell);
    }

    dascade.end();
    await Future.delayed(const Duration(milliseconds: 16));
  }
  dascade.dispose();
}
