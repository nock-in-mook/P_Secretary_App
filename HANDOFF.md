# P_Secretary_App - 申し送り

## 次タスク: Macウォッチャーで透過動画をHEVC alpha mp4に自動変換（**Mac側Claudeで作業**）

### 背景
- Flutter Webのキャラ透過動画は現状 `VP9 alpha webm` のみ。
- Chrome系は透過再生OKだが **iOS Safariは透過にならず黒背景で表示**される。iOSアプリ化後もネイティブAVPlayerが同じく。
- iOSで透過を出すには **HEVC alpha付きMP4**（Apple独自仕様）が必須。エンコードには Apple の VideoToolbox（ffmpeg `hevc_videotoolbox`）が必要で **Mac限定**。
- ユーザーは今後キャラの所作・表情動画を大量生成する計画。毎回Macを手動操作するのは現実的でない → **常時起動Macで自動変換するウォッチャー**を設置する。

### 対応ブラウザ/環境の整理
| 環境 | 必要フォーマット |
|---|---|
| Chrome系（PC/Android Web） | VP9 alpha webm ✓既に持ってる |
| Safari（iOS Web） | HEVC alpha mp4 ←このタスク |
| iOSネイティブアプリ（将来） | HEVC alpha mp4 ←同じファイル使い回せる |
| Androidネイティブアプリ（将来） | VP9 alpha webm ←既存流用 |

つまり **1キャラ/動作につき webm + mp4 の2ファイル持っておけば全環境カバー**できる。

### ウォッチャー仕様
1. **監視対象**: `G:/マイドライブ/_Apps2026/P_Secretary_App/web/assets/` （Mac側の同等パス: `/Users/nock_re/Library/CloudStorage/GoogleDrive-yagukyou@gmail.com/マイドライブ/_Apps2026/P_Secretary_App/web/assets/`）
2. **トリガー**: `*.webm` の新規追加・更新を検知
3. **処理**:
   - 同名 `.mp4` が既に存在し、webmより新しい → スキップ
   - なければ `ffmpeg -i foo.webm -c:v hevc_videotoolbox -allow_sw 1 -alpha_quality 0.75 -tag:v hvc1 foo.mp4` を実行
   - 同じフォルダに `foo.mp4` を出力
4. **常駐方法**: `launchd` の `.plist` に登録。Mac起動時に自動起動、クラッシュしても再起動。
5. **ログ出力**: `~/Library/Logs/p_secretary_video_watcher.log`（ローテーション or サイズ上限）

### 実装チェックリスト（Mac側Claude向け）
- [ ] `ffmpeg` がインストール済みか確認（`which ffmpeg`）。なければ `brew install ffmpeg`
- [ ] **hevc_videotoolbox が使えるか確認**: `ffmpeg -codecs | grep hevc_videotoolbox`
- [ ] `fswatch` インストール確認。なければ `brew install fswatch`
- [ ] 既存 `web/assets/bw_idle.webm` `f06_idle.webm` を手動変換テスト
  - 変換後のmp4を実機iOS Safariで直接開いて透過されるか検証（背景が黒じゃなく透過ならOK）
- [ ] ウォッチャー本体（シェルスクリプト or Python）を `G:/マイドライブ/_Apps2026/_mac_scripts/` あたりに配置
  - ローカル保存禁止ルールがあるので、スクリプト本体もGoogle Drive同期領域に置く
- [ ] launchd plist 作成 → `launchctl load` で登録
- [ ] 動作確認: `web/assets/` に test.webm をコピーして数秒以内にmp4が生成されるか

### Flutter側の対応（Mac側で完結しなくてOK、あとから）
- index.html の `<video>` タグに `<source type="video/mp4; codecs=hvc1" src="...mp4">` と `<source type="video/webm" src="...webm">` の2本立てにする
- ブラウザが自動で選ぶ（Safari→mp4、Chrome→webm）
- `character_switcher_web.dart` も src ではなく source切り替え or video.load() ロジック調整

---

## 現在の状況（今日のセッションで到達した状態）

### 完成した機能
- **キャラ切り替え（仮実装）**: AppBarの顔アイコン（PopupMenu）で bookworm ⇄ 銀髪ボブ 切り替え。動画も性格プロンプトも連動して切り替わる
  - Web版: `character_switcher_web.dart` でDOM経由に `<video>` の src 差し替え
  - バックエンド: `personality` パラメータで `bw` / `f06` を送信
- **性格プロンプト2キャラ実装済**:
  - `bw` = シオリ: メガネ読書家、隠れガチゲーマー、弟と同居、慢性寝不足、元空手黒帯（本人は秘密）、ですます調でノリよくツッコむ
  - `f06` = ミサキ: 銀髪ボブ、元気系タメ口
- **.env 整備**: `api/.env` に GEMINI_API_KEY 設定済み。`.gitignore` に `.env` 追加済み
- **スマホ（iOS Safari）動作確認済**: Tailscale経由で Flutter Web + FastAPI 接続、シオリ/ミサキの応答確認
- **チャット画面の改善**:
  - キャラパネル被り防止の末尾余白（画面高の30% + 16px）
  - 初回ビルド時に最新メッセージへ自動ジャンプ
- **ガチャ画像生成（セッション027）**: `imagen_batch_027.py` で新プロンプト書き下ろし。**女性123枚 + 男性45枚 = 168枚生成済み** → `realistic/pending/20260411/` に出力

### 既知の問題（Mac側タスクで解消予定）
- **iOS Safari/Safariで透過動画の背景が黒**（VP9 alpha webm 非対応のため）→ 上記Macウォッチャーで解決

### プロンプト調整履歴（貴重な知見）
- 最初の「丁寧でやわらか」設定 → メール文体になり却下
- 例示を緩めすぎ → シオリがタメ口に転倒 → NG例に「タメ口禁止」明示で復帰
- 無機質すぎる問題 → 具体エピソード（ゲーマー・弟・寝不足・空手）を注入して一気に人格化
- **残課題**: 初対面で全プロフィールを一気に喋る問題。ROADMAPの「キャラ仲深まり度システム」として記録済み（Phase 3で本実装予定）

### インフラ状態
- FastAPI: `0.0.0.0:8888` で `--reload` なしの通常起動（`--reload` は Google Drive上の mtime 検知が不安定だった）
- Flutter Web: `0.0.0.0:8080` で `flutter run -d web-server`
- Tailscale IP: `100.117.249.65`（スマホ検証用）
- LAN IP: `192.168.1.3`
- ファイアウォール: 8080 / 8888 開放済み

---

## 技術スタック
- **フロントエンド**: Flutter（Web確認用、iOS/Android本番）
- **バックエンド**: Python FastAPI + Gemini 2.5 Flash（新SDK: google-genai）
- **インフラ**: 未セットアップ（GCP予定）
- **キャラ動画**: LivePortrait + birefnet-general透過処理

## 次のアクション（Macタスク後の予定）
1. **Macウォッチャー実装**（このHANDOFFの最上部）← 次のセッション
2. HEVC alpha mp4化できたらFlutter側の video タグを `<source>` 2本立てに改修
3. Android Emulator セットアップ（Android Studioで仮想デバイス作成、スマホ表示確認）
4. 会話履歴のDB永続化（現在インメモリ）→ キャラ仲深まり度システムの土台
5. Firebase Auth セットアップ
6. キャラ30種計画の進行（現在は BW / F06 の2キャラのみ実装）

## 重要ルール（メモリに記録済み）
- チャットの自然言語処理は全てGeminiに任せる（プログラム側パース禁止）
- キャラ画像は胸上+両腕完全に写る構図
- 画像生成: gemini-2.5-flash-image（上限なし）、imagen-4.0系（1日70枚）
- 「imagen」= 毎日のガチャ用新規生成のこと

## ファイアウォール開放済み
- ポート8080（Flutter Web Dev）
- ポート8888（FastAPI Dev）
