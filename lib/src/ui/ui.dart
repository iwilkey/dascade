/// Root entry point for building and rendering immediate-mode UI in Dascade.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/elements/element.dart';
import 'package:dascade/src/ui/geometry/layout/column.dart';
import 'package:dascade/src/ui/geometry/layout/layout.dart';
import 'package:dascade/src/ui/geometry/layout/row.dart';
import 'package:dascade/src/ui/geometry/point.dart';
import 'package:dascade/src/ui/geometry/rect.dart';
import 'package:dascade/src/ui/renderer.dart';
import 'package:dascade/src/ui/runtime.dart';

/// Root entry point for building and rendering immediate-mode UI in Dascade.
///
/// This class coordinates layout, interaction, and rendering for all elements
/// each frame. It owns both the [DUIRuntime] (input & focus state)
/// and the [DUIRenderer] (draw API).
///
/// A single [DascadeUI] instance should be created per app, and reused each frame.
final class DascadeUI {

  /// Reference to the active Dascade framework context.
  final DascadeFramework d;

  /// Handles per-frame input state (mouse, focus, text input).
  final DUIRuntime _r;

  /// Handles rendering primitives and clipping.
  final DUIRenderer _p;

  DascadeUI(this.d)
    : _r = DUIRuntime(d),
      _p = DUIRenderer(d);

  /// Begins a new UI frame.
  ///
  /// Must be called after `d.beginFrame()`.
  void begin() => _r.beginFrame();

  /// Ends the current UI frame.
  ///
  /// Must be called before `d.endFrame()`.
  void end() => _r.endFrame();

  /// The full-screen available UI region.
  DURect get root => DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: d.width, y: d.height),
  );

  /// Lays out and renders a row of UI elements.
  ///
  /// This is the top-level `row()` API and automatically applies layout,
  /// interaction, and rendering in a single call.
  void row(
    final List<DUElement> children, {
    required DULayout layout,
    final int gap = 0,
    final int pad = 0,
  }) {
    /// Generate layout weights
    final List<double> weights = layout.generate(children.length);
    /// Validate passed layout parameters; will thrown on issue.
    _validateLayoutParameters(children.length, weights, gap, pad);
    DURow(children, weights: weights, gap: gap, pad: pad)
      ..layout(root)
      ..interact(_r)
      ..render(_p, _r);
  }

  /// Creates a vertical column of elements (layout only).
  ///
  /// The returned [DUColumn] must be manually laid out, interacted, and rendered.
  DUColumn column(
    List<DUElement> children, {
    required DULayout layout,
    final int gap = 0,
    final int pad = 0,
  }) {
    /// Generate layout weights
    final List<double> weights = layout.generate(children.length);
    /// Validate passed layout parameters; will thrown on issue.
    _validateLayoutParameters(children.length, weights, gap, pad);
    return DUColumn(children, weights: weights, gap: gap, pad: pad)
      ..layout(root)
      ..interact(_r)
      ..render(_p, _r);
  }

  /// Validation layer for passed layout weights. Will throw [Exception] on issue.
  void _validateLayoutParameters(final int children, final List<double> weights, final int gap, final int pad) {
    if(gap < 0) {
      /// gap cannot be negative.
      throw Exception("[Dascade UI] \"Gap\" layout parameter cannot be negative.");
    }
    if(pad < 0) {
      /// pad cannot be negative.
      throw Exception("[Dascade UI] \"Pad\" layout parameter cannot be negative.");
    }
    if(children != weights.length) {
      /// weights given don't map children 1-to-1.
      throw Exception("[Dascade UI] \"Weights\" layout parameter doesn't map to amount of given children.");
    }
    double s = 0;
    for(int i = 0; i < weights.length; i++) {
      s += weights[i];
    }
    if((s - 1.0).abs() > 0.001) {
      /// weights don't sum to one.
      throw Exception("[Dascade UI] \"Weights\" layout parameter does not sum to one.");
    }
  }

}
