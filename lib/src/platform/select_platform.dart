/// Platform selection entry point for Dascade.
///
/// This file selects the correct platform implementation at compile time
/// using conditional imports. The exported factory function is used by
/// the Dascade runtime to construct platform specific backends without
/// exposing platform details to higher level code.
library;

import 'platform.dart';

import 'native_platform.dart'
  if(dart.library.html) 'web_platform.dart';

/// Compile time flag indicating whether the current build target is web.
const bool kIsWeb = bool.fromEnvironment('dart.library.html');

/// Creates the active platform implementation.
///
/// The returned platform is selected at compile time using conditional
/// imports. On native targets this returns the native platform
/// implementation. On web targets this returns the web platform
/// implementation.
DascadePlatform createPlatform() {
  return DascadePlatformImpl();
}

