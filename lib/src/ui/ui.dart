/// Root entry point for building and rendering immediate-mode UI in Dascade.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/geometry/layout/column.dart';
import 'package:dascade/src/ui/geometry/layout/row.dart';

/// Root entry point for building and rendering immediate-mode UI in Dascade.
///
/// This class coordinates layout, interaction, and rendering for all elements
/// each frame. It owns both the [DURuntime] (input & focus state)
/// and the [DURenderer] (draw API).
///
/// A single [DascadeUI] instance should be created per app, and reused each frame.
final class DascadeUI {

  /// Whether or not there is a current overflow of UI.
  static bool overflow = false;

  /// Reference to the active Dascade framework context.
  final DascadeFramework d;

  /// Handles per-frame input state (mouse, focus, text input).
  final DURuntime _r;

  /// Handles rendering primitives and clipping.
  final DURenderer _p;

  /// Is a UI frame current active?
  bool _frameActive = false;

  /// Did the user ask for Dascade UI this frame?
  bool _uiUsedThisFrame = false;

  /// Counting the number of current roots. There should only 1 if column() or row()'s are asked for, no more, no less.
  int _rootsThisFrame = 0;

  /// "Semaphore" for ensuring one render cycle has completed before throwing.
  int _st = 0;

  DascadeUI(this.d)
    : _r = DURuntime(d),
      _p = DURenderer(d);

  /// Begins a new UI frame.
  ///
  /// Must be called after `d.beginFrame()`.
  void begin() {
    _rootsThisFrame = 0;
    _uiUsedThisFrame = false;
    overflow = false;
    _r.beginFrame();
    _frameActive = true;
  }

  /// Ends the current UI frame.
  ///
  /// Must be called before `d.endFrame()`.
  void end() {
    if(_uiUsedThisFrame && _rootsThisFrame == 0) {
      _st++;
      if(_st > 2) {
        throw Exception('[Dascade UI] UI was built this frame, but there was no top-level dascade.ui.root(...)! See docs or examples for correct usage.');
      }
    }
    _r.endFrame();
    _frameActive = false;
  }

  /// The full-screen available UI region.
  DURect get screen => DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: d.width, y: d.height),
  );

  /// Lays out, interacts, and renders any element as the root for this frame.
  void root(final DUElement child) {
    if(!_frameActive) {
      throw Exception('[Dascade UI] UI can only exist between Dascade\'s beginFrame() and endFrame()! See docs or examples for correct usage.');
    }
    _rootsThisFrame++;
    if(_rootsThisFrame > 1) {
      throw Exception('[Dascade UI] Only one dascade.ui.root(...) is allowed per frame! See docs or examples for correct usage.');
    }
    child
      ..layout(screen)
      ..interact(_r)
      ..render(_p, _r);
  }

  /// Lays out and renders a row of UI elements.
  ///
  /// This is the top-level `row()` API and automatically applies layout,
  /// interaction, and rendering in a single call.
  DURow row(
    final List<DUElement> children, {
    required DULayout layout,
    final int gap = 0,
    final int pad = 0,
  }) {
    if(!_frameActive) {
      throw Exception('[Dascade UI] UI can only exist between Dascade\'s beginFrame() and endFrame()! See docs or examples for correct usage.');
    }
    _uiUsedThisFrame = true;
    /// Generate layout weights
    final List<double> weights = layout.generate(children.length);
    /// Validate passed layout parameters; will thrown on issue.
    _validateLayoutParameters(children.length, weights, gap, pad);
    return DURow(children, weights: weights, gap: gap, pad: pad);
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
    if(!_frameActive) {
      throw Exception('[Dascade UI] UI can only exist between Dascade\'s beginFrame() and endFrame()! See docs or examples for correct usage.');
    }
    _uiUsedThisFrame = true;
    /// Generate layout weights
    final List<double> weights = layout.generate(children.length);
    /// Validate passed layout parameters; will thrown on issue.
    _validateLayoutParameters(children.length, weights, gap, pad);
    return DUColumn(children, weights: weights, gap: gap, pad: pad);
  }

  /// Validation layer for passed layout weights. Will throw [Exception] on issue.
  void _validateLayoutParameters(final int children, final List<double> weights, final int gap, final int pad) {
    if(gap < 0) {
      /// gap cannot be negative.
      throw Exception("[Dascade UI] \"Gap\" layout parameter cannot be negative! See docs or examples for correct usage.");
    }
    if(pad < 0) {
      /// pad cannot be negative.
      throw Exception("[Dascade UI] \"Pad\" layout parameter cannot be negative! See docs or examples for correct usage.");
    }
    if(children != weights.length) {
      /// weights given don't map children 1-to-1.
      throw Exception("[Dascade UI] \"Weights\" layout parameter doesn't map to amount of given children! See docs or examples for correct usage.");
    }
    double s = 0;
    for(int i = 0; i < weights.length; i++) {
      s += weights[i];
    }
    if((s - 1.0).abs() > 0.001) {
      /// weights don't sum to one.
      throw Exception("[Dascade UI] \"Weights\" layout parameter does not sum to one! See docs or examples for correct usage.");
    }
  }

}
