import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _windowChannel = MethodChannel('promptsec.arena/window');
bool _autoFullscreen = false;
bool _isDesktopFullscreen = false;

bool get _isDesktopPlatform {
  try {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  } catch (_) {
    return false;
  }
}

void initPlatformDefaultFullscreen() {
  if (_isDesktopPlatform) {
    if (_autoFullscreen) {
      enterPlatformFullscreen();
    } else {
      maximizePlatformWindow();
    }
  } else {
    if (_autoFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}

void enterPlatformFullscreen() {
  _isDesktopFullscreen = true;
  if (_isDesktopPlatform) {
    try {
      _windowChannel.invokeMethod<bool>('enterFullscreen').then((res) {
        if (res != null) _isDesktopFullscreen = res;
      }).catchError((_) {});
    } catch (_) {}
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}

void exitPlatformFullscreen() {
  _isDesktopFullscreen = false;
  if (_isDesktopPlatform) {
    try {
      _windowChannel.invokeMethod<bool>('exitFullscreen').then((res) {
        if (res != null) _isDesktopFullscreen = res;
      }).catchError((_) {});
    } catch (_) {}
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

void maximizePlatformWindow() {
  _isDesktopFullscreen = false;
  if (_isDesktopPlatform) {
    try {
      _windowChannel.invokeMethod<bool>('maximize').then((res) {
        if (res != null) _isDesktopFullscreen = false;
      }).catchError((_) {});
    } catch (_) {}
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

void togglePlatformFullscreen() {
  if (_isDesktopPlatform) {
    try {
      _windowChannel.invokeMethod<bool>('toggleFullscreen').then((res) {
        if (res != null) _isDesktopFullscreen = res;
      }).catchError((_) {
        _isDesktopFullscreen = !_isDesktopFullscreen;
      });
    } catch (_) {
      _isDesktopFullscreen = !_isDesktopFullscreen;
    }
  } else {
    if (_isDesktopFullscreen) {
      exitPlatformFullscreen();
    } else {
      enterPlatformFullscreen();
    }
  }
}

bool isPlatformFullscreen() => _isDesktopFullscreen;
bool getPlatformAutoFullscreen() => _autoFullscreen;

void setPlatformAutoFullscreen(bool enabled) {
  _autoFullscreen = enabled;
  if (enabled) {
    enterPlatformFullscreen();
  } else {
    exitPlatformFullscreen();
  }
}


