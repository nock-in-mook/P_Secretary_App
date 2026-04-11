# P_Secretary_App - 申し送り

## 直近の状態（2026-04-12 セッション終了時点）

### ✅ 完了：透過動画 webm→mp4 自動変換ウォッチャー（Mac常駐）

**目的**: iOS Safari は VP9 alpha webm を透過再生できず黒背景になるため、HEVC alpha mp4 を別途用意する必要があった。Apple独自仕様で Mac の `hevc_videotoolbox` でしか作れない。新キャラ動画を量産する予定なので常駐ウォッチャー化。

**構成**:
- 監視対象: `web/assets/*.webm`
- 出力先: `web/assets/mp4/<basename>.mp4`（サブフォルダ）
- 常駐: `launchd` (Mac起動時に自動起動・クラッシュ時再起動)
- 方式: **5秒ポーリング**（fswatchはGoogle Drive CloudStorage上のFSEventsが不安定なため不採用）

**ファイル配置**:
- 正本スクリプト: `_Apps2026/_mac_scripts/p_secretary_video_watcher.sh`
- 正本plist: `_Apps2026/_mac_scripts/com.psecretary.video-watcher.plist`
- インストーラ: `_Apps2026/_mac_scripts/install_video_watcher.sh`
- 実行コピー: `~/bin/p_secretary_video_watcher.sh`（launchdが実際に読むのはこちら）
- launchd登録: `~/Library/LaunchAgents/com.psecretary.video-watcher.plist`
- ログ: `~/Library/Logs/p_secretary_video_watcher.log`

**スクリプト編集の運用**:
1. `_mac_scripts/p_secretary_video_watcher.sh` を編集
2. `bash _mac_scripts/install_video_watcher.sh` を実行（コピー＆launchctl reload）

**ffmpegエンコード設定（実機検証で確定）**:
```
-c:v libvpx-vp9 -i input.webm -an -vf format=yuva420p
-c:v hevc_videotoolbox -allow_sw 1 -alpha_quality 0.5 -b:v 350k
-tag:v hvc1 -f mp4
```
→ 25fps / 864x1008 / α0.5 / 350k で webm の約1.6〜2.9倍サイズ（1ファイル~1MB前後）

**必須設定（このMacのみ・初回手動）**:
- システム設定 → プライバシーとセキュリティ → フルディスクアクセス → `/bin/bash` を追加してON
- 理由: launchd起動のbashがGoogle Drive(CloudStorage)を読み書きするため

### ✅ 完了：Flutter側のwebm/mp4自動切り替え

**Safari判定でファイルを切り替え**：
- Safari → `assets/mp4/<name>.mp4`
- それ以外 → `assets/<name>.webm`

修正ファイル：
- `web/index.html` … 起動時に `window.__pickCharVideoExt()` で判定して初期srcを設定
- `lib/services/character_switcher_web.dart` … `setCharacterVideo(baseName)` がUA判定
- `lib/services/character_switcher_stub.dart` … 引数名のみ更新
- `lib/screens/chat_screen.dart` … `_characters` マップを拡張子なしに変更
- `lib/widgets/character_panel_web.dart` … 同様にUA判定追加

`flutter analyze` 通過済み。

### 既存webmは変換済み
- `bw_idle` (568KB) → `mp4/bw_idle.mp4` (1.07MB)
- `character_idle` (340KB) → `mp4/character_idle.mp4` (992KB)
- `f06_idle` (655KB) → `mp4/f06_idle.mp4` (1.07MB)

---

## 次のアクション

### 最優先：iOS実機確認
- Flutter Web起動 → iOS Safari (Tailscale経由) で透過＆切替動作確認
- 起動コマンド：
  - `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`
  - FastAPI: `cd api && python main.py`（または既存の起動方法）
- このMacのTailscale IP: **`100.82.114.118`**
  - ⚠️ 旧Windows機の `100.117.249.65` は別マシン

### その他のロードマップ
1. Android Emulator セットアップ（Android Studioで仮想デバイス作成）
2. 会話履歴のDB永続化（現在インメモリ）→ キャラ仲深まり度システムの土台
3. Firebase Auth セットアップ
4. キャラ30種計画の進行（現在は BW / F06 の2キャラ）

---

## 現在の状態（前回セッションからの引き継ぎ）

### 完成した機能
- **キャラ切り替え（仮実装）**: AppBarの顔アイコン（PopupMenu）で bookworm ⇄ 銀髪ボブ 切り替え。動画も性格プロンプトも連動して切り替わる
- **性格プロンプト2キャラ実装済**:
  - `bw` = シオリ: メガネ読書家、隠れガチゲーマー、弟と同居、慢性寝不足、元空手黒帯（本人は秘密）、ですます調でノリよくツッコむ
  - `f06` = ミサキ: 銀髪ボブ、元気系タメ口
- **.env 整備**: `api/.env` に GEMINI_API_KEY 設定済み
- **チャット画面の改善**:
  - キャラパネル被り防止の末尾余白（画面高の30% + 16px）
  - 初回ビルド時に最新メッセージへ自動ジャンプ
- **ガチャ画像生成（セッション027）**: 女性123枚 + 男性45枚 = 168枚生成済 → `realistic/pending/20260411/`

### プロンプト調整履歴（貴重な知見）
- 最初の「丁寧でやわらか」設定 → メール文体になり却下
- 例示を緩めすぎ → シオリがタメ口に転倒 → NG例に「タメ口禁止」明示で復帰
- 無機質すぎる問題 → 具体エピソード（ゲーマー・弟・寝不足・空手）を注入して人格化
- **残課題**: 初対面で全プロフィールを一気に喋る問題。ROADMAPの「キャラ仲深まり度システム」として記録済み（Phase 3で実装予定）

### インフラ状態
- FastAPI: `0.0.0.0:8888`（`--reload` なし、Google Drive上の mtime 検知が不安定だったため）
- Flutter Web: `0.0.0.0:8080`
- Tailscale IP（**Mac**）: `100.82.114.118`
- ファイアウォール: macOS側はFW無効、Windows側で 8080/8888 開放済

---

## 技術スタック
- **フロントエンド**: Flutter（Web確認用、iOS/Android本番）
- **バックエンド**: Python FastAPI + Gemini 2.5 Flash（新SDK: google-genai）
- **インフラ**: 未セットアップ（GCP予定）
- **キャラ動画**: LivePortrait + birefnet-general透過処理 → Macウォッチャーで mp4 自動生成

## 重要ルール（メモリに記録済み）
- チャットの自然言語処理は全てGeminiに任せる（プログラム側パース禁止）
- キャラ画像は胸上+両腕完全に写る構図
- 画像生成: gemini-2.5-flash-image（上限なし）、imagen-4.0系（1日70枚）
- 「imagen」= 毎日のガチャ用新規生成のこと
