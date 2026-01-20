/// A vertical layout group that arranges children in a column.
library;

import 'package:dascade/src/ui/geometry/layout/axis.dart';
import 'package:dascade/src/ui/geometry/layout/group.dart';

/// A vertical layout group that arranges children in a column.
///
/// Each child receives a slot based on its corresponding weight,
/// with optional padding around the group and gaps between children.
final class DUColumn extends DULayoutGroup {
  DUColumn(
    super.children, {
    required super.weights,
    required super.gap,
    required super.pad,
  });

  @override
  DULayoutAxis get axis => DULayoutAxis.vertical;
}
