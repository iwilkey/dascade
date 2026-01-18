/// Dascade's Windows Virtual Terminal support.
///
/// Enables VT100/ANSI escape sequence processing on Windows.
library;

import 'dart:ffi';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:ffi/ffi.dart';

/// Windows Virtual Terminal mode enabler.
/// 
/// NOTE: GIT BASH (and other mintty terminals) MOUSE EVENTS ARE NOT SUPPORTED AT THIS TIME.
///
/// Windows Console Host (CMD) and older Windows terminals don't process
/// ANSI escape sequences by default. This class uses FFI to enable
/// Virtual Terminal processing via the Windows Console API.
///
/// This is required for:
/// - ANSI color codes
/// - Cursor positioning
/// - Mouse input reporting
/// - Other escape sequences
final class DascadeWindowsVT {

  /// Private constructor; this is a static utility class.
  DascadeWindowsVT._();

  // ═══════════════════════════════════════════════════════════════════════════
  // WINDOWS CONSOLE CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle to standard input.
  static const int _STD_INPUT_HANDLE = -10;

  /// Handle to standard output.
  static const int _STD_OUTPUT_HANDLE = -11;

  /// Enable virtual terminal processing for output.
  /// Allows the console to process ANSI escape sequences for output.
  static const int _ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

  /// Enable virtual terminal input processing.
  /// Allows the console to send ANSI escape sequences for input (including mouse).
  static const int _ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;

  /// Enable mouse input events.
  static const int _ENABLE_MOUSE_INPUT = 0x0010;

  /// Enable extended flags (required for some mouse modes).
  static const int _ENABLE_EXTENDED_FLAGS = 0x0080;

  /// Enable window input events (resize, etc).
  static const int _ENABLE_WINDOW_INPUT = 0x0008;

  /// Disable quick edit mode (allows mouse events to reach the application).
  /// Quick edit mode intercepts mouse for copy/paste; we need to disable it.
  static const int _ENABLE_QUICK_EDIT_MODE = 0x0040;

  static final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

  /// GetStdHandle - retrieves a handle to the specified standard device.
  static final int Function(int) _getStdHandle = _kernel32
      .lookupFunction<IntPtr Function(Uint32), int Function(int)>('GetStdHandle');

  /// GetConsoleMode - retrieves the current input/output mode of a console.
  static final int Function(int, Pointer<Uint32>) _getConsoleMode = _kernel32
      .lookupFunction<Int32 Function(IntPtr, Pointer<Uint32>),
          int Function(int, Pointer<Uint32>)>('GetConsoleMode');

  /// SetConsoleMode - sets the input/output mode of a console.
  static final int Function(int, int) _setConsoleMode = _kernel32
      .lookupFunction<Int32 Function(IntPtr, Uint32),
          int Function(int, int)>('SetConsoleMode');

  /// Original input console mode (for restoration).
  static int? _originalInputMode;

  /// Original output console mode (for restoration).
  static int? _originalOutputMode;

  /// Enables virtual terminal processing for stdout.
  ///
  /// This allows ANSI escape sequences to be processed for:
  /// - Colors
  /// - Cursor movement
  /// - Screen clearing
  /// - Other output formatting
  ///
  /// Returns  true  if successful,  false  otherwise.
  static bool _enableOutput() {
    if (!Platform.isWindows) return true;
    try {
      final int handle = _getStdHandle(_STD_OUTPUT_HANDLE);
      if(handle == -1) return false;
      final Pointer<Uint32> mode = calloc<Uint32>();
      try {
        if(_getConsoleMode(handle, mode) == 0) return false;
        // Save original mode for restoration
        _originalOutputMode ??= mode.value;
        // Enable virtual terminal processing
        final int newMode = mode.value | _ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        return _setConsoleMode(handle, newMode) != 0;
      } finally {
        calloc.free(mode);
      }
    } catch (e) {
      return false;
    }
  }

  /// Enables virtual terminal processing for stdin.
  ///
  /// This allows ANSI escape sequences to be received for:
  /// - Arrow keys
  /// - Function keys
  /// - Mouse events (when mouse reporting is enabled)
  ///
  /// Returns  true  if successful,  false  otherwise.
  static bool _enableInput() {
    if(!Platform.isWindows) return true;
    try {
      final int handle = _getStdHandle(_STD_INPUT_HANDLE);
      if(handle == -1) return false;
      final Pointer<Uint32> mode = calloc<Uint32>();
      try {
        if(_getConsoleMode(handle, mode) == 0) return false;
        // Save original mode for restoration
        _originalInputMode ??= mode.value;
        // Enable virtual terminal input
        final int newMode = mode.value | _ENABLE_VIRTUAL_TERMINAL_INPUT;
        return _setConsoleMode(handle, newMode) != 0;
      } finally {
        calloc.free(mode);
      }
    } catch (e) {
      return false;
    }
  }

  /// Enables mouse input for the Windows Console.
  ///
  /// This does two things:
  /// 1. Enables the ENABLE_MOUSE_INPUT flag
  /// 2. Disables Quick Edit mode (which intercepts mouse for copy/paste)
  ///
  /// **Important:** Quick Edit mode is disabled to allow mouse events to
  /// reach the application. Call [restoreConsoleMode] to restore it.
  ///
  /// Returns  true  if successful,  false  otherwise.
  static bool _enableMouseInput() {
    if(!Platform.isWindows) return true;
    try {
      final int handle = _getStdHandle(_STD_INPUT_HANDLE);
      if (handle == -1) return false;
      final Pointer<Uint32> mode = calloc<Uint32>();
      try {
        if(_getConsoleMode(handle, mode) == 0) return false;
        _originalInputMode ??= mode.value;
        int newMode = mode.value;
        newMode |= _ENABLE_MOUSE_INPUT;
        newMode |= _ENABLE_EXTENDED_FLAGS;
        newMode |= _ENABLE_VIRTUAL_TERMINAL_INPUT;
        newMode |= _ENABLE_WINDOW_INPUT;
        newMode &= ~_ENABLE_QUICK_EDIT_MODE;
        return _setConsoleMode(handle, newMode) != 0;
      } finally {
        calloc.free(mode);
      }
    } catch (e) {
      return false;
    }
  }

  /// Enables all virtual terminal features (input, output, and mouse).
  ///
  /// This is a convenience method that calls:
  /// - [_enableOutput]
  /// - [_enableInput]
  /// - [_enableMouseInput]
  ///
  /// Returns  true  if all operations succeeded,  false  otherwise.
  static bool enable() {
    if(!Platform.isWindows) return true;
    final bool output = _enableOutput();
    final bool input = _enableInput();
    final bool mouse = _enableMouseInput();
    return output && input && mouse;
  }

  /// Restores the original console mode.
  ///
  /// Call this before your application exits to restore the console
  /// to its original state (including Quick Edit mode if it was enabled).
  ///
  /// Returns  true  if successful,  false  otherwise.
  static bool restoreConsoleMode() {
    if(!Platform.isWindows) return true;
    bool success = true;
    try {
      // Restore input mode
      if(_originalInputMode != null) {
        final int handle = _getStdHandle(_STD_INPUT_HANDLE);
        if(handle != -1) {
          if(_setConsoleMode(handle, _originalInputMode!) == 0) {
            success = false;
          }
        }
        _originalInputMode = null;
      }
      // Restore output mode
      if(_originalOutputMode != null) {
        final int handle = _getStdHandle(_STD_OUTPUT_HANDLE);
        if(handle != -1) {
          if(_setConsoleMode(handle, _originalOutputMode!) == 0) {
            success = false;
          }
        }
        _originalOutputMode = null;
      }
    } catch (e) {
      success = false;
    }
    return success;
  }

  /// Checks if the current terminal supports virtual terminal sequences.
  ///
  /// Returns  true  if:
  /// - Not on Windows (assume Unix terminals support ANSI)
  /// - On Windows Terminal (WT_SESSION environment variable)
  /// - VT processing can be enabled successfully
  static bool get isSupported {
    if(!Platform.isWindows) return true;
    // Windows Terminal always supports VT
    if(Platform.environment.containsKey('WT_SESSION')) return true;
    // Try to enable and check if it works
    try {
      final int handle = _getStdHandle(_STD_OUTPUT_HANDLE);
      if(handle == -1) return false;
      final Pointer<Uint32> mode = calloc<Uint32>();
      try {
        if(_getConsoleMode(handle, mode) == 0) return false;
        final int newMode = mode.value | _ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        if(_setConsoleMode(handle, newMode) == 0) return false;
        _setConsoleMode(handle, mode.value);
        return true;
      } finally {
        calloc.free(mode);
      }
    } catch (e) {
      return false;
    }
  }

}
