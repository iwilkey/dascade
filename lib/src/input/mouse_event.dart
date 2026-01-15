/// Dascade's mouse input event reported by terminal.
/// 
/// Strictly a struct for inner-thread message passing. It should never be referenced by user of framework.
library;

/// Mouse input event reported by terminal. This is strictly for message-passing. User's will never have to handle these 
/// objects.
final class DascadeMouseEvent {
  final int x;
  final int y;
  final bool leftDown;
  final bool leftUp;
  final bool middleDown;
  final bool middleUp;
  final bool rightDown;
  final bool rightUp;
  final int scroll;
  const DascadeMouseEvent({
    required this.x,
    required this.y,
    this.leftDown = false,
    this.leftUp = false,
    this.middleDown = false,
    this.middleUp = false,
    this.rightDown = false,
    this.rightUp = false,
    this.scroll = 0,
  });
}
