/// Demonstrates maze generation and A* pathfinding using Dascade.
library;

import 'dart:math';
import 'package:dascade/dascade.dart';

/// Demonstrates maze generation and A* pathfinding using Dascade.
/// Author: Ian Wilkey
Future<void> main() async {

  /// Every Dascade application must be launched through [Dascade.run].
  /// The entire application lives inside this callback.
  await Dascade.run((final DascadeFramework d) async {

    /// Immediate-mode applications require an explicit run loop.
    bool running = true;

    /// Random number generator used for maze creation.
    final Random rng = Random();

    /// Maze data:
    /// - true  = walkable
    /// - false = wall
    List<List<bool>> maze = [];

    /// A* bookkeeping.
    Set<Node> openSet   = {};
    Set<Node> closedSet = {};
    List<Node> path     = [];
    bool solved         = false;

    late Node start;
    late Node goal;

    /// Track previous mouse state to detect a JUST-DOWN click.
    bool prevLeftDown = false;

    /// Track whether the maze has been initialized.
    ///
    /// This is critical: terminal dimensions are NOT guaranteed to be valid
    /// until at least one frame has begun.
    bool mazeInitialized = false;

    /// Picks a random walkable cell from the maze.
    ///
    /// A safety cap is used to prevent infinite loops in pathological cases.
    Node randomOpenCell() {
      for (int i = 0; i < 10000; i++) {
        final int x = rng.nextInt(d.width);
        final int y = rng.nextInt(d.height);
        if (maze[y][x]) return Node(x, y);
      }
      throw StateError('Failed to find an open cell in the maze.');
    }

    /// Generates a new random maze and resets A* state.
    ///
    /// IMPORTANT:
    /// This function assumes [d.width] and [d.height] are valid.
    void generateMaze() {
      final int w = d.width;
      final int h = d.height;

      maze = List.generate(
        h,
        (_) => List.generate(
          w,
          (_) => rng.nextDouble() > (0.05 + rng.nextDouble() * 0.35),
        ),
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

    /// Performs a single A* iteration.
    void stepAStar() {
      if (openSet.isEmpty || solved) return;

      /// Pick node with lowest f-score.
      final Node current = openSet.reduce(
        (a, b) => a.f < b.f ? a : b,
      );

      /// Goal reached — reconstruct path.
      if (current == goal) {
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

      for (final (int dx, int dy) in dirs) {
        final int nx = current.x + dx;
        final int ny = current.y + dy;

        /// Bounds and wall checks.
        if (nx < 0 ||
            ny < 0 ||
            ny >= maze.length ||
            nx >= maze[0].length ||
            !maze[ny][nx]) {
          continue;
        }

        final Node neighbor = Node(nx, ny);
        if (closedSet.contains(neighbor)) continue;

        final double tentativeG = current.g + 1;
        final Node? existing = openSet.lookup(neighbor);

        if (existing == null || tentativeG < existing.g) {
          final Node n = existing ?? neighbor;
          n.parent = current;
          n.g = tentativeG;
          n.h = ((goal.x - n.x).abs() + (goal.y - n.y).abs()).toDouble();
          openSet.add(n);
        }
      }
    }

    /// Main application loop.
    while (running) {
      if (d.escape) running = false;

      /// Detect mouse JUST-DOWN (left click).
      final bool leftJustDown = d.mouseLeftDown && !prevLeftDown;
      prevLeftDown = d.mouseLeftDown;

      /// Begin the frame.
      ///
      /// This is where terminal dimensions become valid.
      d.beginFrame();

      /// Lazily initialize the maze once dimensions are known.
      if (!mazeInitialized && d.width > 0 && d.height > 0) {
        generateMaze();
        mazeInitialized = true;
      }

      /// Regenerate maze on mouse click.
      if (leftJustDown && mazeInitialized) {
        generateMaze();
      }

      /// Advance A* by one step per frame.
      if (mazeInitialized) {
        stepAStar();
      }

      /// Draw maze walls.
      for (int y = 0; y < maze.length; y++) {
        for (int x = 0; x < maze[0].length; x++) {
          if (!maze[y][x]) {
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

      /// Draw closed set.
      for (final Node n in closedSet) {
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

      /// Draw open set.
      for (final Node n in openSet) {
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

      /// Draw final path.
      for (final Node n in path) {
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

      /// Draw start and goal.
      if (mazeInitialized) {
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
      }

      /// Flush the frame to the terminal.
      d.endFrame();

      /// Throttle frame rate.
      await Future.delayed(const Duration(milliseconds: 20));
    }
  });
}

/// Node used for A* pathfinding.
final class Node {
  final int x;
  final int y;

  double g = double.infinity;
  double h = 0;

  Node? parent;

  Node(this.x, this.y);

  double get f => g + h;

  @override
  bool operator ==(Object other) =>
      other is Node && other.x == x && other.y == y;

  @override
  int get hashCode => x * 73856093 ^ y * 19349663;
}
