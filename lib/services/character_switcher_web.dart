import 'package:web/web.dart' as web;

/// Safari なら HEVC alpha mp4、それ以外は VP9 alpha webm を使う。
/// (Safariは VP9 alpha 非対応で黒背景になるため)
/// mp4 は assets/mp4/ サブフォルダ、webm は assets/ 直下
String _videoSrc(String baseName) {
  final ua = web.window.navigator.userAgent;
  final isSafari =
      RegExp(r'^((?!chrome|android).)*safari', caseSensitive: false)
          .hasMatch(ua);
  return isSafari ? 'assets/mp4/$baseName.mp4' : 'assets/$baseName.webm';
}

/// index.html内の<video id="character-video">のsrcを差し替えて再読み込み
/// baseName は拡張子なし（例: "bw_idle"）
void setCharacterVideo(String baseName) {
  final el = web.document.getElementById('character-video');
  if (el == null) return;
  final video = el as web.HTMLVideoElement;
  video.src = _videoSrc(baseName);
  video.load();
  video.play();
}
