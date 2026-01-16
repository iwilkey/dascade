/// Dascade's Sidecar backend interface.
///
/// Defines the minimal contract required for a Dascade sidecar
/// implementation. Platform-specific backends (such as macOS)
/// must implement this interface to receive redirected log output
/// and handle lifecycle cleanup.
///
library;

/// Shared interface for sidecar implementations.
abstract interface class DascadeSidecarImpl {

  /// Writes a message to the sidecar output.
  void write(final String message);

  /// Disposes of the sidecar and releases all associated resources.
  void dispose();
  
}
