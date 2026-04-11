import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

bool _registered = false;

/// Web版: HTML5 <video> タグで透過webmを再生
Widget buildWebCharacterPanel(double width, double height) {
  const viewType = 'character-video-player';

  // viewFactoryを1回だけ登録
  if (!_registered) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId, {Object? params}) {
        // 透明なdivでvideoを包む
        final container = web.document.createElement('div') as web.HTMLDivElement;
        container.style
          ..width = '100%'
          ..height = '100%'
          ..backgroundColor = 'transparent'
          ..overflow = 'hidden';

        final video = web.document.createElement('video') as web.HTMLVideoElement;
        // Safari は VP9 alpha 非対応なので mp4 を、その他は webm を選ぶ
        final ua = web.window.navigator.userAgent;
        final isSafari = RegExp(
          r'^((?!chrome|android).)*safari',
          caseSensitive: false,
        ).hasMatch(ua);
        video.src = isSafari
            ? 'assets/mp4/character_idle.mp4'
            : 'assets/character_idle.webm';
        video.autoplay = true;
        video.loop = true;
        video.muted = true;
        video.setAttribute('playsinline', '');
        video.style
          ..width = '100%'
          ..height = '100%'
          ..objectFit = 'contain'
          ..backgroundColor = 'transparent';

        container.appendChild(video);
        return container;
      },
    );
    _registered = true;
  }

  return SizedBox(
    width: width,
    height: height,
    child: const HtmlElementView(viewType: viewType),
  );
}
