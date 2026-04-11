import 'package:web/web.dart' as web;

/// index.html内の<video id="character-video">のsrcを差し替えて再読み込み
void setCharacterVideo(String assetFilename) {
  final el = web.document.getElementById('character-video');
  if (el == null) return;
  final video = el as web.HTMLVideoElement;
  video.src = 'assets/$assetFilename';
  video.load();
  video.play();
}
