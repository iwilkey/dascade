/// A horizontal layout group that arranges children in a row.
library;

import 'package:dascade/src/ui/geometry/layout/axis.dart';
import 'package:dascade/src/ui/geometry/layout/group.dart';

/// A horizontal layout group that arranges children in a row.
///
/// Each child receives a slot based on its corresponding weight,
/// with optional padding around the group and gaps between children.
final class DURow extends DULayoutGroup {

  DURow(
    super.children, {
    required super.weights,
    required super.gap,
    required super.pad,
  });

  @override
  DULayoutAxis get axis => DULayoutAxis.horizontal;

}
