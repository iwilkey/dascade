/// Dascade — Dart ASCII Console Application Development Environment.
///
/// Dascade is a lightweight, immediate-mode terminal UI framework for Dart.
/// It provides buffered and differential rendering, ANSI color support,
/// and a simple, expressive API for building performant terminal-based
/// applications.
///
/// Dascade is designed to be:
/// - Immediate-mode and stateless at the API level
/// - Efficient through buffered and differential rendering
/// - Portable across macOS, Linux, and Windows terminals
/// - Minimal in dependencies and runtime overhead
///
/// Import this library to access the public Dascade API:
/// ```dart
/// import 'package:dascade/dascade.dart';
/// ```
library;

/// Top-level.
export 'src/dascade.dart';

/// Framework.
export 'src/runtime/dascade_framework.dart';

/// UI.
export 'src/ui/ui.dart';
export 'src/ui/renderer.dart';
export '/src/ui/renderer_utils.dart';
export 'src/ui/runtime.dart';
export 'src/ui/elements/element.dart';
export 'src/ui/geometry/layout/layout.dart';
export 'src/ui/geometry/rect.dart';
export 'src/ui/geometry/point.dart';
export 'src/ui/style/theme.dart';
export 'src/ui/style/color.dart';

export 'src/ui/elements/text/textbox.dart';
export 'src/ui/elements/button/button.dart';
export 'src/ui/elements/button/radio.dart';
export 'src/ui/elements/layout/spacer.dart';
export 'src/ui/elements/layout/list.dart';
export 'src/ui/elements/misc/native.dart';

/// Rendering primitives.
export 'src/output/cell.dart';
