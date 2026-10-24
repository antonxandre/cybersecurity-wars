import 'package:flutter/services.dart';

void togglePlatformFullscreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

bool isPlatformFullscreen() => true;
