import 'package:dascade/dascade.dart';

Future<void> main() async {
  final Dascade dascade = Dascade();
  bool running = true;
  int x = 0;
  while(running) {

    dascade.begin();

    final int w = dascade.width;
    final int h = dascade.height;

    final int cell = DascadeCell.encode(
      glyph: '#'.codeUnitAt(0),
      fg: 10,
      bg: 0,
      bold: true,
    );

    x++;
    x %= w;

    for(int y = 0; y < h; y++) {
      dascade.draw(x, y, cell);
    }

    dascade.end();
    await Future.delayed(const Duration(milliseconds: 16));

    dascade.input.readKey();
  }
  // unreachable here, but correct API usage
  // ignore: dead_code
  dascade.dispose();
}
