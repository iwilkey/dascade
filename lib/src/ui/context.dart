/// Internal UI runtime and layout coordinator.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/element/element.dart';
import 'package:dascade/src/ui/gfx/layout.dart';
import 'package:dascade/src/ui/gfx/painter.dart';
import 'package:dascade/src/ui/interaction/input.dart';
import 'package:dascade/src/ui/interaction/interaction.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';
import 'package:dascade/src/ui/runtime.dart';
import 'package:dascade/src/ui/state.dart';

/// Internal UI runtime and layout coordinator.
///
/// This is the engine behind [DascadeUI]. It is responsible for:
///
/// - managing layout scopes (row / column)
/// - allocating deterministic rectangles and stable IDs
/// - dispatching interaction + rendering
/// - tracking focus, hot/active states, and input edges
/// - supporting overlays rendered after normal layout
///
/// This type is intentionally *not* user-facing.
/// Users interact exclusively through [DascadeUI].
final class DascadeUIContext {
  
  /// Backing Dascade framework instance.
  final DascadeFramework d;

  /// Low-level drawing and clipping primitives.
  final DUIPainter painter;

  /// Persistent cross-frame state storage for elements.
  final DUIStateStore state = DUIStateStore();

  /// Mouse focus / hot / active interaction state.
  final DUIInteraction interaction = DUIInteraction();

  /// Keyboard edge tracking.
  final DUKeyTracker keys = DUKeyTracker();

  /// Active layout scopes (row/column).
  final List<DULayoutScope> _layoutStack = [];

  /// Seed stack used to generate stable IDs down the layout tree.
  final List<int> _seedStack = [0];

  /// Optional manual ID scoping for advanced/custom widgets.
  final List<int> _manualIdStack = [];

  /// Elements rendered after normal layout (e.g. popups, tooltips).
  final List<DUElement> _overlays = [];

  /// Per-frame runtime passed to elements.
  late DUIRuntime _runtime;

  DascadeUIContext(this.d) : painter = DUIPainter(d);

  /// Begins a new UI frame.
  ///
  /// Clears all layout state, prepares input tracking,
  /// and constructs the per-frame [DUIRuntime].
  void begin() {
    _layoutStack.clear();
    _seedStack
      ..clear()
      ..add(0);

    _manualIdStack.clear();
    _overlays.clear();

    interaction.beginFrame();
    keys.beginFrame(d);

    final String typed = d.lastInputChar ?? '';
    _runtime = DUIRuntime(
      d: d,
      state: state,
      interaction: interaction,
      keys: keys,
      typed: typed,
      idStack: _manualIdStack,
    );
  }

  /// Ends the current UI frame.
  ///
  /// - Verifies all layout scopes were closed
  /// - Dispatches overlay interaction + rendering
  /// - Applies global focus resolution
  /// - Finalizes input edge tracking
  void end() {
    if (_layoutStack.isNotEmpty) {
      throw StateError(
        'DascadeUI: end() called with unterminated layout scopes.',
      );
    }

    for (final DUElement e in _overlays) {
      e.interact(_runtime);
      e.render(painter, _runtime);
    }

    // Global focus policy:
    // - mouse release over a hot element => focus it
    // - mouse release over empty space => clear focus
    if (interaction.mouseReleased(d)) {
      final int? h = interaction.hot;
      if (h == null) {
        interaction.clearFocus();
      } else if (interaction.focused != h) {
        interaction.requestFocus(h);
      }
    }

    interaction.endFrame(d);
    keys.endFrame();
  }

  /// Begins a new layout scope.
  ///
  /// The layout itself consumes a slot from the parent scope,
  /// allowing layouts to be nested arbitrarily.
  ///
  /// Throws if weights/counts are invalid.
  void beginLayout({
    required DULayoutAxis axis,
    required int children,
    required List<double> weights,
    required int gap,
    required int pad,
  }) {
    if (children <= 0) {
      throw StateError('DascadeUI layout error: children must be > 0.');
    }
    if (weights.length != children) {
      throw StateError(
        'DascadeUI layout error: expected $children weights, '
        'got ${weights.length}.',
      );
    }

    // Layout is itself a child; consumes a slot.
    final DUSlot slot = _consumeSlotInternal(kind: 'layout');

    // Push new seed for deterministic IDs.
    _seedStack.add(slot.id);

    final DULayoutScope scope = DULayoutScope(
      axis: axis,
      rect: (pad > 0) ? slot.rect.inset(pad) : slot.rect,
      children: children,
      weights: weights,
      gap: gap,
    );

    _layoutStack.add(scope);
  }

  /// Ends the current layout scope.
  ///
  /// Throws if the number of emitted children does not
  /// match the declared count.
  void endLayout() {
    final DULayoutScope scope = _layoutStack.removeLast();
    _seedStack.removeLast();

    if (scope.index != scope.children) {
      throw StateError(
        'DascadeUI layout error: scope expected ${scope.children} children, '
        'but ${scope.index} were emitted.',
      );
    }
  }

  /// Allocates a layout slot for a widget.
  ///
  /// Public labels are accepted for API stability but do not
  /// influence layout or identity.
  DUSlot consumeSlot({
    required String kind,
    required String label,
  }) {
    return _consumeSlotInternal(kind: kind);
  }

  /// Immediately dispatches interaction and rendering for an element.
  void emit(DUElement element) {
    element.interact(_runtime);
    element.render(painter, _runtime);
  }

  /// Registers an overlay element rendered after normal layout.
  void emitOverlay(DUElement element) {
    _overlays.add(element);
  }

  DUSlot _consumeSlotInternal({required String kind}) {
    // Root-most consumer gets full screen.
    if (_layoutStack.isEmpty) {
      final DURect rect = DURect(
        upperLeft: DUPoint(x: 0, y: 0),
        lowerRight: DUPoint(x: d.width, y: d.height),
      );
      final int id = _hash(_seedStack.last, '$kind|root');
      return DUSlot(rect: rect, id: id);
    }

    final DULayoutScope scope = _layoutStack.last;

    if (scope.index >= scope.children) {
      throw StateError(
        'DascadeUI layout error: too many children emitted in '
        '${scope.axis.name}(). Expected ${scope.children}.',
      );
    }

    final int slotIndex = scope.index;
    final DURect rect = _childRect(scope, slotIndex);
    scope.index += 1;

    // Stable as long as structure and order are stable.
    final int id = _hash(_seedStack.last, '$kind|$slotIndex');
    return DUSlot(rect: rect, id: id);
  }

  /// Computes the rectangle for a child slot within a layout scope.
  DURect _childRect(DULayoutScope scope, int i) {
    final DURect p = scope.rect;

    final int mainSize =
        (scope.axis == DULayoutAxis.horizontal) ? p.width : p.height;
    final int crossSize =
        (scope.axis == DULayoutAxis.horizontal) ? p.height : p.width;

    final int totalGap = scope.gap * (scope.children - 1);
    final int available = mainSize - totalGap;

    if (available <= 0 || crossSize <= 0) {
      return DURect(
        upperLeft: DUPoint(x: p.left, y: p.top),
        lowerRight: DUPoint(x: p.left, y: p.top),
      );
    }

    final double sum = scope.weights.fold(0.0, (a, b) => a + b);
    if (sum <= 0) {
      return DURect(
        upperLeft: DUPoint(x: p.left, y: p.top),
        lowerRight: DUPoint(x: p.left, y: p.top),
      );
    }

    final List<int> sizes = List<int>.filled(scope.children, 0);
    int used = 0;

    for (int k = 0; k < scope.children; k++) {
      final int s = (available * (scope.weights[k] / sum)).floor();
      sizes[k] = s;
      used += s;
    }

    int rem = available - used;
    for (int k = 0; k < scope.children && rem > 0; k++, rem--) {
      sizes[k] += 1;
    }

    int cursor =
        (scope.axis == DULayoutAxis.horizontal) ? p.left : p.top;

    for (int k = 0; k < i; k++) {
      cursor += sizes[k] + scope.gap;
    }

    final int size = sizes[i];

    return (scope.axis == DULayoutAxis.horizontal)
        ? DURect(
            upperLeft: DUPoint(x: cursor, y: p.top),
            lowerRight: DUPoint(x: cursor + size, y: p.bottom),
          )
        : DURect(
            upperLeft: DUPoint(x: p.left, y: cursor),
            lowerRight: DUPoint(x: p.right, y: cursor + size),
          );
  }

  int _hash(int seed, String s) {
    int h = seed;
    for (int i = 0; i < s.length; i++) {
      h = 31 * h + s.codeUnitAt(i);
    }
    return h;
  }
}
