# P_Secretary_App - 申し送り

## 直近の状態（2026-04-12 セッション終了時点）

### ✅ 完了：Android Emulator 導入
- AVD `pixel_test` 作成（API 35 / Google Play / x86_64）
- 日本語パス問題を `subst K: G:\マイドライブ\_Apps2026` で回避
- `android/gradle.properties` に `overridePathCheck=true` 追加
- `hw.keyboard=yes` 設定済み（config.ini）
- `show_ime_with_hard_keyboard=1` 設定済み（ただしリモートデスクトップ経由のキーボード入力は困難）

### ✅ 完了：キャラ動画表示改善
- display:none → canplaythrough で block（小→大フラッシュ防止）
- MutationObserver で src 変更検知 → 自動非表示
- 入力バー高さから動的に bottom 算出（Flutter→JS連携）
- right:-12px で右端寄せ、width:26vh height:30vh 固定
- バックグラウンド復帰: visibilitychange + pageshow + focus + touchstart
- 枠外タップで unfocus（GestureDetector追加）

### ✅ 完了：Noto Sans JP フォント適用
- google_fonts パッケージ追加
- MaterialApp の theme + appBarTheme に GoogleFonts.notoSansJp() 適用

### ✅ 完了：Google Calendar API 連携
- GCPプロジェクト `calendar-auto` を再利用（Calendar API有効化済み）
- OAuth認証フロー実装（google_auth.py）、トークン自動更新対応
- Calendar CRUD サービス（list/create/delete）
- チャットから自然言語で予定操作可能（Gemini → ACTIONS → Calendar API）
- 予定表示の統一フォーマット（📅 日付(曜日) / 時間帯 / タイトル）
- 認証情報: `api/.env.calendar` + `api/.token.json`（どちらも .gitignore 済み）

### ✅ 完了：Imagen バッチ028 生成
- 女性93枚 + 男性35枚 = 128枚生成（`realistic/pending/20260412/`）
- 攻めたビジュアル（OKルール廃止、NGだけ守って自由裁量）
- 文学少女2枚固定（黒髪・眼鏡・パッツン・カーディガン）
- ビューア（Port 8900）から選別可能

---

## 次のアクション

### 最優先：キャラ顔アイコン作成
- AppBar左 + チャット吹き出し横のアイコンを秘書の顔画像にする
- AppBarにイメージ写真（秘書 + 背景）のバナーを入れる
- キャラ切り替え時にアイコンも連動
- 画像生成が必要（gemini-2.5-flash-image で作成予定）

### Imagen バッチ028 の選別
- `realistic/pending/20260412/` の128枚をビューア（Port 8900）で選別
- 起動: `cd Personal_Secretary && PYTHONUTF8=1 py -3.14 realistic_server.py`

### その他のロードマップ
1. 会話履歴のDB永続化（SQLAlchemy + SQLite → 将来PostgreSQL移行）
2. リマインダー機能（チャット経由）
3. メモ機能（チャット経由）
4. Firebase Auth セットアップ
5. キャラ30種計画の進行（現在は BW / F06 の2キャラ）

---

## 新設ルール（メモリに記録済み）
- **クロスプラットフォーム優先**: 実装前にWeb/iOS/Android共通で書けるか必ず検討
- **PLATFORM_TODO.md**: プラットフォーム固有実装したら必ず記録
- **ローカル開発→本番移行3原則**: ORM必須 / 設定は環境変数 / パス直書き禁止

## 技術スタック
- **フロントエンド**: Flutter（Web確認用、iOS/Android本番）
- **バックエンド**: Python FastAPI + Gemini 2.5 Flash（新SDK: google-genai）
- **カレンダー**: Google Calendar API（OAuth認証、calendar-auto プロジェクト）
- **インフラ**: ローカル開発中（将来 GCP Cloud Run + Cloud SQL）
- **キャラ動画**: LivePortrait + birefnet-general透過処理 → Macウォッチャーで mp4 自動生成
- **フォント**: Noto Sans JP（google_fonts パッケージ）

## 環境情報
- Windows Tailscale IP: `100.117.249.65`
- Mac Tailscale IP: `100.82.114.118`
- FastAPI: `0.0.0.0:8888`
- Flutter Web: `0.0.0.0:8080`（`subst K:` 経由で起動）
- 画像ビューア: Port 8900（リアル）/ Port 8899（ガチャ）
- Android EMU: `flutter emulators --launch pixel_test`（subst K: 必須）

## 重要ルール（メモリに記録済み）
- チャットの自然言語処理は全てGeminiに任せる（プログラム側パース禁止）
- キャラ画像は胸上+両腕完全に写る構図
- 画像生成: gemini-2.5-flash-image（上限なし）、imagen-4.0系（1日70枚）
- 「imagen」= 毎日のガチャ用新規生成のこと
- 聖域フォルダ: realistic/favorites, character_workshop, gacha_favorites は絶対削除禁止
