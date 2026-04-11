// プラットフォーム別実装の条件付きエクスポート
export 'character_switcher_stub.dart'
    if (dart.library.js_interop) 'character_switcher_web.dart';
