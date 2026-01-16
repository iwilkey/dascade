/// Simple Snake game implemented using Dascade's immediate-mode API using a primitive rendering approach. This is not to showcase UI functionality; 
/// See other examples for that.
/// 
/// This example demonstrates:
/// - Keyboard input polling
/// - Discrete-time game updates
/// - Primitive rendering
/// - Resize-safe logic
library;

import 'dart:math';

import 'package:dascade/dascade.dart';

enum SnakeDirection { up, down, left, right }

/// Simple Snake game implemented using the Dascade framework.
/// Author: Ian Wilkey
Future<void> main() async {

  /// Everytime you want to use Dascade, this is the only correct way to create a new runtime. Your application lives inside
  /// of run()'s callback function.
  await Dascade.run((final DascadeFramework dascade) async {

    /// Snake body, stored head-first.
    final List<Point<int>> snake = [
      const Point(10, 10),
      const Point(9, 10),
      const Point(8, 10),
    ];

    /// Initial direction.
    SnakeDirection direction = SnakeDirection.right;

    /// Food position.
    Point<int> food = const Point(15, 10);

    /// Game timing.
    const int tickMillis = 60;
    int lastTick = DateTime.now().millisecondsSinceEpoch;

    /// Dascade is an immediate-mode framework; this means it draws information as your program runs. Because of this,
    /// it's best practice to define your main thread loop like the one below.
    bool running = true;

    /// Spawns food somewhere not occupied by the snake.
    Point<int> spawnFood(final int w, final int h) {
      final rand = Random();
      Point<int> p;
      do {
        p = Point(rand.nextInt(w), rand.nextInt(h));
      } while (snake.contains(p));
      return p;
    }

    while(running) {
      if(dascade.escape) running = false;
      /// Direction input (no reversing).
      if(dascade.w && direction != SnakeDirection.down) {
        direction = SnakeDirection.up;
      } else if (dascade.s && direction != SnakeDirection.up) {
        direction = SnakeDirection.down;
      } else if (dascade.a && direction != SnakeDirection.right) {
        direction = SnakeDirection.left;
      } else if (dascade.d && direction != SnakeDirection.left) {
        direction = SnakeDirection.right;
      }
      final int now = DateTime.now().millisecondsSinceEpoch;
      if(now - lastTick >= tickMillis) {
        lastTick = now;
        final Point<int> head = snake.first;
        Point<int> next;
        switch(direction) {
          case SnakeDirection.up:
            next = Point(head.x, head.y - 1);
            break;
          case SnakeDirection.down:
            next = Point(head.x, head.y + 1);
            break;
          case SnakeDirection.left:
            next = Point(head.x - 1, head.y);
            break;
          case SnakeDirection.right:
            next = Point(head.x + 1, head.y);
            break;
        }
        /// Collision with walls.
        if(next.x < 0 ||
           next.y < 0 ||
           next.x >= dascade.width ||
           next.y >= dascade.height) {
          dascade.beep();
          break;
        }
        /// Collision with self.
        if(snake.contains(next)) {
          dascade.beep();
          break;
        }
        /// Move snake.
        snake.insert(0, next);
        if(next == food) {
          food = spawnFood(dascade.width, dascade.height);
        } else {
          snake.removeLast();
        }
      }
      /// Rendering
      dascade.beginFrame();
      /// Draw food.
      dascade.draw(
        food.x,
        food.y,
        DascadeCell.encode(
          glyph: '@'.codeUnitAt(0),
          fg: 196,
          bg: 0,
        ),
      );
      /// Draw snake.
      for(int i = 0; i < snake.length; i++) {
        final Point<int> p = snake[i];
        dascade.draw(
          p.x,
          p.y,
          DascadeCell.encode(
            glyph: i == 0 ? 'O'.codeUnitAt(0) : 'o'.codeUnitAt(0),
            fg: 46,
            bg: 0,
          ),
        );
      }
      dascade.endFrame();
      await Future.delayed(const Duration(milliseconds: 8));
    }
  });
}
