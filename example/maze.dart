/// Demonstrates maze generation and A* pathfinding using Dascade.
/// 
/// This example visualizes the internal state of the A* algorithm
/// (open set, closed set, current node, and final path) in real time.
library;

import 'dart:math';
import 'package:dascade/dascade.dart';

/// Needed for A*. This isn't really a tutorial on A* so I'm not going to comment
/// a lot of this.
final class Node {
  final int x;
  final int y;
  double g = double.infinity;
  double h = 0;
  Node? parent;
  Node(this.x, this.y);
  double get f => g + h;
  @override
  bool operator ==(Object other) => other is Node && other.x == x && other.y == y;
  @override
  int get hashCode => x * 73856093 ^ y * 19349663;
}

/// Demonstrates maze generation and A* pathfinding using Dascade.
/// Author: Ian Wilkey
Future<void> main() async {

  /// Everytime you want to use Dascade, this is the only correct way to create a new runtime. Your application lives inside
  /// of run()'s callback function.
  await Dascade.run((final Dascade d) async {

    /// Dascade is an immediate-mode framework; this means it draws information as your program runs. Because of this,
    /// it's best practice to define your main thread loop like the one below.
    bool running = true;

    /// A* stuff. this isn't a tutorial on A* so I'll spare you the details.
    
    final Random rng = Random();
    List<List<bool>> maze      = [];
    Set<Node>        openSet   = {};
    Set<Node>        closedSet = {};
    List<Node>       path      = [];
    bool             solved    = false;
    late Node start;
    late Node goal;

    /// Track previous mouse state to detect JUST DOWN.
    bool prevLeftDown = false;

    /// Picks a random walkable position.
    Node randomOpenCell() {
      while(true) {
        final int x = rng.nextInt(d.width);
        final int y = rng.nextInt(d.height);
        if(maze[y][x]) return Node(x, y);
      }
    }

    /// Generates a random maze with random start & goal.
    void generateMaze() {
      final int w = d.width;
      final int h = d.height;
      maze = List.generate(
        h,
        (_) => List.generate(w, (_) => rng.nextDouble() > (0.05 + rng.nextDouble() * 0.35)),
      );
      start = randomOpenCell();
      do {
        goal = randomOpenCell();
      } while (goal == start);
      openSet.clear();
      closedSet.clear();
      path.clear();
      start.g = 0;
      start.h = ((goal.x - start.x).abs() + (goal.y - start.y).abs()).toDouble();
      openSet.add(start);
      solved = false;
    }
    generateMaze();
    /// A* single-step update.
    void stepAStar() {
      if(openSet.isEmpty || solved) return;
      final Node current = openSet.reduce(
        (a, b) => a.f < b.f ? a : b,
      );
      if(current == goal) {
        solved = true;
        Node? n = current;
        while (n != null) {
          path.add(n);
          n = n.parent;
        }
        return;
      }
      openSet.remove(current);
      closedSet.add(current);
      const List<(int, int)> dirs = [
        (1, 0),
        (-1, 0),
        (0, 1),
        (0, -1),
      ];
      for(final (int dx, int dy) in dirs) {
        final int nx = current.x + dx;
        final int ny = current.y + dy;
        if(nx < 0 ||
           ny < 0 ||
           ny >= maze.length ||
           nx >= maze[0].length ||
           !maze[ny][nx]) {
          continue;
        }
        final Node neighbor = Node(nx, ny);
        if(closedSet.contains(neighbor)) continue;
        final double tentativeG = current.g + 1;
        final Node? existing = openSet.lookup(neighbor);
        if(existing == null || tentativeG < existing.g) {
          final Node n = existing ?? neighbor;
          n.parent = current;
          n.g = tentativeG;
          n.h = ((goal.x - n.x).abs() + (goal.y - n.y).abs()).toDouble();
          openSet.add(n);
        }
      }
    }
    while(running) {
      if(d.escape) running = false;
      /// Mouse JUST DOWN (left click) regenerates maze.
      final bool leftJustDown = d.mouseLeftDown && !prevLeftDown;
      prevLeftDown = d.mouseLeftDown;
      if(leftJustDown) {
        generateMaze();
      }
      stepAStar();
      d.beginFrame();
      /// Draw maze
      for(int y = 0; y < maze.length; y++) {
        for(int x = 0; x < maze[0].length; x++) {
          if(!maze[y][x]) {
            d.draw(
              x,
              y,
              DascadeCell.encode(
                glyph: '#'.codeUnitAt(0),
                fg: 240,
                bg: 0,
              ),
            );
          }
        }
      }
      /// Draw closed set
      for(final Node n in closedSet) {
        d.draw(
          n.x,
          n.y,
          DascadeCell.encode(
            glyph: '.'.codeUnitAt(0),
            fg: 244,
            bg: 0,
          ),
        );
      }
      /// Draw open set
      for(final Node n in openSet) {
        d.draw(
          n.x,
          n.y,
          DascadeCell.encode(
            glyph: 'o'.codeUnitAt(0),
            fg: 33,
            bg: 0,
          ),
        );
      }
      /// Draw final path
      for(final Node n in path) {
        d.draw(
          n.x,
          n.y,
          DascadeCell.encode(
            glyph: '*'.codeUnitAt(0),
            fg: 46,
            bg: 0,
          ),
        );
      }
      /// Draw start and goal
      d.draw(
        start.x,
        start.y,
        DascadeCell.encode(
          glyph: 'S'.codeUnitAt(0),
          fg: 82,
          bg: 0,
        ),
      );
      d.draw(
        goal.x,
        goal.y,
        DascadeCell.encode(
          glyph: 'G'.codeUnitAt(0),
          fg: 196,
          bg: 0,
        ),
      );
      d.endFrame();
      await Future.delayed(const Duration(milliseconds: 20));
    }
  });

}
