/// Immediate-mode UI facade for Dascade.
///
/// `DascadeUI` provides a small, declarative API for describing terminal
/// user interfaces each frame. Layout is explicit, deterministic, and
/// evaluated top-down every frame.
///
/// Usage pattern:
/// ```dart
/// ui.begin();
/// ui.row(() {
///   ui.column(() {
///     ui.textBox(...);
///   }, children: 1, weights: [1]);
/// }, children: 1, weights: [1]);
/// ui.end();
/// ```
///
/// All widgets are stateless declarations; persistent state, interaction,
/// focus, clipping, and scrolling are handled internally.
library;

import 'package:dascade/dascade.dart';
import 'package:dascade/src/ui/context.dart';
import 'package:dascade/src/ui/element/bar_chart_box.dart';
import 'package:dascade/src/ui/element/braille_line_chart_box.dart';
import 'package:dascade/src/ui/element/dot_line_chart_box.dart';
import 'package:dascade/src/ui/element/gauge_box.dart';
import 'package:dascade/src/ui/element/list_box.dart';
import 'package:dascade/src/ui/element/sparkline_box.dart';
import 'package:dascade/src/ui/element/text_box.dart';
import 'package:dascade/src/ui/gfx/layout.dart';
import 'package:dascade/src/ui/math/point.dart';
import 'package:dascade/src/ui/math/rect.dart';

/// Immediate-mode UI facade for Dascade.
final class DascadeUI {
  
  /// Underlying Dascade framework instance.
  final DascadeFramework d;

  final DascadeUIContext _ctx;

  /// Creates a UI facade bound to a running [DascadeFramework].
  DascadeUI(this.d) : _ctx = DascadeUIContext(d);

  /// Begins a new UI frame.
  ///
  /// Must be called once per frame before emitting any layout or widgets.
  void begin() => _ctx.begin();

  /// Ends the current UI frame.
  ///
  /// Finalizes layout validation, interaction resolution, and rendering.
  void end() => _ctx.end();

  /// Rectangle representing the full terminal surface.
  ///
  /// Mostly useful for overlays or absolute positioning helpers.
  DURect get root => DURect(
    upperLeft: DUPoint(x: 0, y: 0),
    lowerRight: DUPoint(x: d.width, y: d.height),
  );

  /// Lays out children horizontally.
  ///
  /// [children] specifies how many widgets/layouts must be emitted inside
  /// [call]. [weights] controls how available space is divided between them.
  ///
  /// Optional [gap] inserts spacing between children.
  /// Optional [pad] insets the entire layout.
  void row(
    void Function() call, {
    required int children,
    required List<double> weights,
    int gap = 0,
    int pad = 0,
  }) {
    _ctx.beginLayout(
      axis: DULayoutAxis.horizontal,
      children: children,
      weights: weights,
      gap: gap,
      pad: pad,
    );
    call();
    _ctx.endLayout();
  }

  /// Lays out children vertically.
  ///
  /// Semantics are identical to [row], but space is divided top-to-bottom.
  void column(
    void Function() call, {
    required int children,
    required List<double> weights,
    int gap = 0,
    int pad = 0,
  }) {
    _ctx.beginLayout(
      axis: DULayoutAxis.vertical,
      children: children,
      weights: weights,
      gap: gap,
      pad: pad,
    );
    call();
    _ctx.endLayout();
  }

  /// Displays a block of text, optionally bordered and editable.
  ///
  /// When [editable] is true, the widget can receive focus and text input.
  void textBox({
    String? title,
    required List<String> lines,
    bool border = true,
    bool editable = false,
  }) {
    final DUSlot slot = _ctx.consumeSlot(kind: 'textBox', label: title ?? '');
    _ctx.emit(
      DUTextBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        initialLines: lines,
        border: border,
        editable: editable,
      ),
    );
  }

  /// Displays a vertically scrollable list of items.
  ///
  /// Scrolling is handled automatically when content exceeds available space.
  void listBox({
    required String title,
    required List<String> items,
    bool border = true,
  }) {
    final DUSlot slot = _ctx.consumeSlot(kind: 'listBox', label: title);
    _ctx.emit(
      DUListBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        items: items,
        border: border,
      ),
    );
  }

  /// Displays two animated sparklines stacked vertically.
  void sparklineBox({
    required String title,
    required String seriesAName,
    required String seriesBName,
    bool border = true,
  }) {
    final DUSlot slot = _ctx.consumeSlot(kind: 'sparklineBox', label: title);
    _ctx.emit(
      DUSparklineBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        seriesAName: seriesAName,
        seriesBName: seriesBName,
        border: border,
      ),
    );
  }

  /// Displays a horizontal gauge representing a value from 0.0 to 1.0.
  void gaugeBox({
    required String title,
    required double value,
    bool border = true,
  }) {
    final DUSlot slot = _ctx.consumeSlot(kind: 'gaugeBox', label: title);
    _ctx.emit(
      DUGaugeBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        value: value,
        border: border,
      ),
    );
  }

  /// Displays a simple vertical bar chart.
  void barChartBox({
    required String title,
    bool border = true,
  }) {
    final DUSlot slot = _ctx.consumeSlot(kind: 'barChartBox', label: title);
    _ctx.emit(
      DUBarChartBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        border: border,
      ),
    );
  }

  /// Displays a line chart rendered using dot glyphs.
  void dotLineChartBox({
    required String title,
    bool border = true,
  }) {
    final DUSlot slot = _ctx.consumeSlot(kind: 'dotLineChartBox', label: title);
    _ctx.emit(
      DUDotLineChartBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        border: border,
      ),
    );
  }

  /// Displays a line chart rendered using braille-style glyphs.
  void brailleLineChartBox({
    required String title,
    bool border = true,
  }) {
    final DUSlot slot =
        _ctx.consumeSlot(kind: 'brailleLineChartBox', label: title);
    _ctx.emit(
      DUBrailleLineChartBoxElement(
        id: slot.id,
        rect: slot.rect,
        title: title,
        border: border,
      ),
    );
  }
}
