/// Windows-only Virtual Terminal (VT) console mode configuration.
library;

import 'dart:ffi';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:ffi/ffi.dart';

/// Windows-only Virtual Terminal (VT) console mode configuration.
///
/// This enables ANSI/VT **input** (so escape sequences like arrow keys can be
/// read from stdin) and ANSI/VT **output** (so escape sequences written to
/// stdout are interpreted by the host).
///
/// Note:
/// - Mouse reporting via ANSI escape sequences is handled by the terminal host.
/// - On Windows, "Quick Edit" can steal mouse input for selection; we disable it
///   when enabling VT input.
final class DascadeWindowsVT {

  DascadeWindowsVT._();

  // Standard handle IDs (GetStdHandle)
  static const int STD_INPUT_HANDLE = -10;
  static const int STD_OUTPUT_HANDLE = -11;

  // Output console mode flags
  static const int ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

  // Input console mode flags
  static const int ENABLE_PROCESSED_INPUT = 0x0001;
  static const int ENABLE_LINE_INPUT = 0x0002;
  static const int ENABLE_ECHO_INPUT = 0x0004;
  static const int ENABLE_WINDOW_INPUT = 0x0008;
  static const int ENABLE_MOUSE_INPUT = 0x0010;
  static const int ENABLE_INSERT_MODE = 0x0020;
  static const int ENABLE_QUICK_EDIT_MODE = 0x0040;
  static const int ENABLE_EXTENDED_FLAGS = 0x0080;
  static const int ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;

  /// Reference to Window kernel32.
  static final DynamicLibrary fK32 = DynamicLibrary.open('kernel32.dll');

  static final int Function(int) fGetStdHandle = fK32.lookupFunction<
    IntPtr Function(Int32), int Function(int)>(
      'GetStdHandle'
    );

  static final int Function(int, Pointer<Uint32>) fGetConsoleMode = fK32.lookupFunction<
    Int32 Function(IntPtr, Pointer<Uint32>), int Function(int, Pointer<Uint32>)>(
      'GetConsoleMode'
    );

  static final int Function(int, int) fSetConsoleMode = fK32.lookupFunction<
    Int32 Function(IntPtr, Uint32), int Function(int, int)>(
      'SetConsoleMode'
    );

  /// Enables Virtual Terminal (ANSI/VT) **input** on Windows, best-effort.
  ///
  /// Returns `true` if the console mode was changed successfully.
  /// Returns `false` if not supported or not a console.
  ///
  /// This method:
  /// - Enables VT input so escape sequences can be read from stdin.
  /// - Disables line+echo so input is not buffered/echoed.
  /// - Disables Quick Edit (selection mode) so the console doesn't steal mouse.
  /// - Disables Win32 mouse input events, to allow VT mouse sequences where
  ///   supported by the host terminal.
  static bool enableInput() {
    if(!Platform.isWindows) return false;
    final int hIn = fGetStdHandle(STD_INPUT_HANDLE);
    if(hIn == 0 || hIn == -1) return false;
    final Pointer<Uint32> modePtr = calloc<Uint32>();
    try {
      final int ok = fGetConsoleMode(hIn, modePtr);
      if(ok == 0) return false;
      final int mode = modePtr.value;
      int newMode = mode;
      // Required for QUICK_EDIT to be changeable.
      newMode |= ENABLE_EXTENDED_FLAGS;
      // Keep basic processed input enabled (Ctrl+C etc. is handled by host).
      newMode |= ENABLE_PROCESSED_INPUT;
      // Disable these so input isn't line-buffered/echoed.
      newMode &= ~ENABLE_LINE_INPUT;
      newMode &= ~ENABLE_ECHO_INPUT;
      // Disable Win32 mouse input events so the host can emit VT mouse sequences.
      newMode &= ~ENABLE_MOUSE_INPUT;
      // Disable Quick Edit so mouse isn't captured by the console for selection.
      newMode &= ~ENABLE_QUICK_EDIT_MODE;
      newMode &= ~ENABLE_INSERT_MODE;
      // VT input: makes escape sequences available on stdin.
      newMode |= ENABLE_VIRTUAL_TERMINAL_INPUT;
      // Window resize events (harmless for VT; useful for some hosts).
      newMode |= ENABLE_WINDOW_INPUT;
      final int ok2 = fSetConsoleMode(hIn, newMode);
      return ok2 != 0;
    } finally {
      calloc.free(modePtr);
    }
  }

  /// Enables Virtual Terminal (ANSI/VT) **output** on Windows, best-effort.
  ///
  /// Returns `true` if the console mode was changed successfully.
  /// Returns `false` if not supported or not a console.
  ///
  /// This method should be called before writing ANSI control sequences
  /// (alternate buffer, cursor hide/show, mouse enable codes, etc.).
  static bool enableOutput() {
    if(!Platform.isWindows) return false;
    final int hOut = fGetStdHandle(STD_OUTPUT_HANDLE);
    if(hOut == 0 || hOut == -1) return false;
    final Pointer<Uint32> modePtr = calloc<Uint32>();
    try {
      final int ok = fGetConsoleMode(hOut, modePtr);
      if(ok == 0) return false;
      int nm = modePtr.value;
      nm |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
      final int ok2 = fSetConsoleMode(hOut, nm);
      return ok2 != 0;
    } finally {
      calloc.free(modePtr);
    }
  }
}
