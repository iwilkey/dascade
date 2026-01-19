/// Cross-frame storage for per-element UI state.
library;

/// Cross-frame storage for per-element UI state.
///
/// [DUIStateStore] provides a stable, ID-keyed container for
/// widget state in an immediate-mode UI. Elements retrieve
/// or create their state using their assigned ID, ensuring
/// continuity across frames without retaining widget instances.
///
/// Stored objects are opaque to the store and managed entirely
/// by the owning element.
final class DUIStateStore {

  final Map<int, Object> _map = {};

  /// Returns an existing state object for [id], or creates and
  /// stores one using [create] if none exists.
  T getOrCreate<T extends Object>(int id, T Function() create) {
    final Object? v = _map[id];
    if(v is T) return v;
    final T created = create();
    _map[id] = created;
    return created;
  }

  /// Returns the stored state object for [id] if it exists
  /// and matches type [T], otherwise `null`.
  T? get<T extends Object>(int id) {
    final Object? v = _map[id];
    if(v is T) return v;
    return null;
  }

  /// Removes any stored state associated with [id].
  ///
  /// Useful when elements are intentionally discarded or
  /// recreated with a new identity.
  void remove(int id) {
    _map.remove(id);
  }

}
