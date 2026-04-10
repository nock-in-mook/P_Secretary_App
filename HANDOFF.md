# P_Secretary_App - 申し送り

## これは何？
Telegram Bot版AI秘書（`Personal_Secretary/`）をネイティブアプリ化するプロジェクト。
Bot版で実証済みの全機能をFlutterアプリとして再構築する。

## 技術スタック（確定済み）
- **フロントエンド**: Flutter（iOS/Android同時リリース）
- **バックエンド**: Python FastAPI（bot.pyのロジックをAPI化）
- **インフラ**: GCP（Cloud Run + Cloud SQL + Firebase Auth + FCM）
- **AI**: Gemini 2.5 Flash（将来的にVertex AIへ移行）
- **多言語対応**: 最初から入れる（世界展開前提）

## Bot版（Personal_Secretary/）から移植すべき機能

### Tier 1: コア（最初のリリースに必須）
- **チャットUI**: LINEライクな吹き出し式。キャラアイコン付き
- **リマインダー**: 自然言語登録、しつこいリマインド、通知パターン
- **カレンダー連携**: Google Calendar読み書き、確認フロー付き登録、訂正対応
- **性格（キャラ）切り替え**: 8パターン（フレンドリー/できる秘書/ツンデレ/執事/ギャル/軍曹/関西のおばちゃん/猫）
- **プッシュ通知**: FCM + ローカル通知の二重化
- **ユーザー認証**: Firebase Auth

### Tier 2: 差別化機能（初期リリースに含めたい）
- **メール連携**: Gmail新着チェック＋AI要約＋タスク/カレンダー自動登録
- **週次ブリーフィング**: 今後2週間の予定まとめ
- **日次通知**: 毎日20:00に明日の予定
- **キャラの記憶**: 雑談からユーザー情報を抽出してDB保存、会話に活用
- **キャラの自己記憶**: キャラが自分で語った設定を蓄積して一貫性維持

### Tier 3: エモーショナル体験（リリース後に順次追加）
- **キャラアバター**: 実写風キャラ画像（Imagen 4で生成済み多数）
- **LivePortrait動画**: まばたき＋表情動画（パイプライン構築済み）
- **リップシンク**: 音声に合わせた口パク動画
- **雇用/解雇/再雇用システム**: キャラ交代を演出
- **解雇後の未練メッセージ**: 元秘書からたまにメッセージが届く
- **グループチャット**: 複数キャラが1つのチャットルームで会話

## Bot版の現在のアーキテクチャ（移植の参考）

### ファイル構成（Personal_Secretary/）
| ファイル | 役割 |
|---------|------|
| `bot.py` (5600行) | メイン。Telegram handler + Geminiプロンプト + 全ビジネスロジック |
| `db.py` | PostgreSQL操作（リマインダー、通知、記憶、メッセージ履歴） |
| `google_services.py` | Google Calendar/Gmail API操作 |
| `personalities.py` | 8性格のプロンプト定義 |
| `message_templates.py` | 47intent × 8性格 × 20パターン = 7,520定型文 |
| `styled_messages.json` | 定型文キャッシュ（message_templates.pyから生成） |

### Geminiの使い方（bot.pyから抽出すべきロジック）
1. **統一パイプライン** (`_handle_message_unified`): Geminiに性格プロンプト＋会話履歴を渡し、返答テキスト＋アクションタグ(`<!--ACTIONS:JSON-->`)を1回で取得
2. **分類器** (`classify_message`): 旧パイプライン用。ユーザー発言をJSON分類（カレンダー/リマインダー/雑談等）
3. **訂正分類** (`_classify_correction`): 確認フロー中の応答を4分岐判定（肯定/否定/訂正/新話題）
4. **日時パース** (`_parse_datetime_input`): 自然言語→YYYY-MM-DD HH:MM変換
5. **返答生成** (`generate_reply`): 性格プロンプト＋履歴→自然言語返答

### DB構造（db.py）
- `items`: リマインダー/タスク（id, user_id, title, due_date, item_type, status）
- `item_notifications`: 通知設定（item_id, notify_at, repeat_type, is_active）
- `messages`: 会話履歴（user_id, role, content）
- `memories`: キャラ記憶（user_id, personality, memory_type, content）
- `notification_patterns`: 通知パターンテンプレート

### 重要な設計判断（Bot版で学んだこと）
- **Gemini全任せ**: プログラム側でパース/判定しない。全てプロンプトで解決、コードは実行するだけ
- **thinking不要**: 秘書botの全タスクにGeminiの推論(thinking)は不要。thinking_budget=0で速度＋コスト＋可用性が改善（※旧SDK非対応のため未適用。新SDK移行時に適用）
- **カレンダー vs リマインダー**: 「登録して」→カレンダー、「通知して/教えて」→リマインダー
- **確認フロー**: カレンダー登録は必ず確認→訂正→承認の3ステップ
- **pending状態管理**: 複数のpendingフロー（calendar/list_actions/email/nag等）が競合しないよう排他制御

## FastAPI移行の方針
bot.pyの5600行を以下のように分割：
```
api/
  main.py          # FastAPIエントリポイント
  routers/
    chat.py         # チャットエンドポイント（統一パイプライン）
    calendar.py     # カレンダー操作
    reminders.py    # リマインダー操作
    notifications.py # 通知管理
    auth.py         # Firebase Auth連携
  services/
    gemini.py       # Gemini呼び出し（プロンプト管理）
    google.py       # Google Calendar/Gmail（google_services.py移植）
    memory.py       # キャラ記憶
  models/
    schemas.py      # Pydanticモデル
  db/
    database.py     # SQLAlchemy/Cloud SQL接続
    models.py       # DBモデル
```

## Flutter側の構成（案）
```
lib/
  main.dart
  screens/
    chat_screen.dart      # メインチャット画面
    character_list.dart   # キャラ一覧（LINEの友達一覧風）
    settings.dart         # 設定画面
  widgets/
    chat_bubble.dart      # 吹き出しウィジェット
    character_avatar.dart # キャラアイコン
  services/
    api_service.dart      # FastAPI通信
    auth_service.dart     # Firebase Auth
    notification_service.dart # FCM + ローカル通知
  models/
    message.dart
    character.dart
    reminder.dart
  l10n/                   # 多言語対応
```

## 既存アセット（使い回せるもの）
- **キャラ画像**: `Personal_Secretary/realistic/favorites/` に選別済み多数
- **キャラ動画**: `Personal_Secretary/character_workshop/` にLivePortrait成果物
- **性格プロンプト**: `personalities.py` の8パターン
- **定型文**: `styled_messages.json` の7,520バリエーション
- **実験済みFlutter**: `Personal_Secretary/flutter_app/` に初期セットアップ済み（SDK 3.8.1）

## SDK移行TODO（バックエンド側）
- `google-generativeai` → `google-genai` に移行
- 移行後に `thinking_budget=0` を全場面適用
- Imagen 4のバッチ生成スクリプトは既に新SDK（`google.genai`）を使用中

## 次のアクション
1. Flutter プロジェクト作成（`flutter create`）
2. FastAPI プロジェクト作成（bot.pyからロジック分離）
3. チャットUI実装（LINEライク吹き出し）
4. Firebase Auth セットアップ
5. チャットAPI接続（Gemini統一パイプライン）
