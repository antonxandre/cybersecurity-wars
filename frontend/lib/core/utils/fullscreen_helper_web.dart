// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void togglePlatformFullscreen() {
  if (html.document.fullscreenElement != null) {
    html.document.exitFullscreen();
  } else {
    html.document.documentElement?.requestFullscreen();
  }
}

bool isPlatformFullscreen() {
  return html.document.fullscreenElement != null;
}
