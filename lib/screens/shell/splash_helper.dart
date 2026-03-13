// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html show document;
import 'dart:async';

/// Fades out and removes the HTML splash overlay from the DOM.
/// Called after data providers have started and enough frames have painted
/// for MaterialIcons and other fonts to be fully rasterised.
void removeSplashElement() {
  // Extra safety delay — ensures MaterialIcons.otf font has been loaded
  // and rasterised by the browser before we reveal the app.
  Future.delayed(const Duration(milliseconds: 300), () {
    final splash = html.document.getElementById('splash');
    if (splash == null) return;
    splash.classes.add('fade-out');
    Future.delayed(const Duration(milliseconds: 400), () {
      splash.remove();
    });
  });
}
