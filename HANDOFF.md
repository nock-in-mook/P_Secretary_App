# P_Secretary_App - 申し送り

## 直近の状態（2026-04-19 セッション終了時点）

### ✅ 完了：キャラ顔アイコン実装
- AppBar左 + チャット吹き出し横を角丸四角アイコン化（36x36, 40x40）
- BW採用: `selfie_red_hood.png` （赤パーカー+公園+自撮りピース）
- キャラ切り替え時にアイコン自動連動

### ✅ 完了：F06プロフィール確立＋画像大量生成
- キャラ設定: 元飲食・自炊派・漫画好き・犬飼いたい（メモリ記録済み）
- sources/: 日常シチュ40枚超（カフェ・居酒屋・ハロウィン・牧場・ビーチ・花火等）
- reactions/: 表情20パターン（smile/surprise/think/listen/wink/wave等）
- outfits/: 服装バリエ32枚
- candidates/: アイコン候補24枚
- workshop/: 表情マトリクスコピー

### ✅ 完了：動画生成実験
- Veo 2.0で静止画→リアクション動画テスト
- LivePortrait不要で直接動画化できる可能性確認
- ただしグラビア感・口パク問題あり、要プロンプト調整
- Kling AIも候補として浮上

### ✅ 完了：フォルダ構成一本化
- `character_profiles/{bw,f06}/` に統一
- web/assets/ から服装バリエ画像を全移動（動画とアイコンは残す）
- Personal_Secretary/character_workshop/ からコピー（聖域維持）

### ✅ 完了：Imagenガチャ大量生成
- 20260414: 111枚（女95+男24）初回
- 20260415: 96枚（女87+男9）
- 20260416: 124枚（女95+男29）
- 20260417: 128枚（女100+男28）**NORMAL上限70達成**
- 20260419: 135枚（女97+男38）**FAST上限38達成**
- 累計600枚超を生成
- 運用ルール確立: NORMAL70/ULTRA30/FAST40、日毎削除→選別→生成サイクル

### ✅ 完了：Windows Update自動再起動対策
- `G:/マイドライブ/_Apps2026/一発更新_WindowsUpdate自動再起動対策.bat`
- PowerShellスクリプト経由で文字化け回避
- アクティブ時間6:00〜23:00設定、ログイン中は自動再起動しない

### ✅ 完了：Google Cloud課金確認
- 有料アカウント確認済（5/29以降も継続可能）
- $300無料トライアル残高あり（4/15時点で使い切りつつある）
- 予算アラート月2万円設定済

---

## 次のアクション

### Phase 1/2 コア機能実装（仕様確定済）
1. **メモ機能**: `save_memo` / `search_memo` ツール追加
2. **リマインダー**: `set_reminder` 時刻ベース通知
3. **ToDo機能**: `add_todo` / `complete_todo` カテゴリ・グループ管理
4. **Web検索**: `search_web` Google Search Grounding連携
5. **UI**: メモ帳タブ + リマインダータブ + ToDoタブ

### Phase 3（画像認識・プロフィール育成）
- `analyze_image` → ToDo/メモ/カレンダー自動振り分け
- 秘書プロフィール自動積み上げ（ユーザー操作ゼロ設計）
- バックグラウンド処理＋プッシュ通知

### 継続作業
- Imagenガチャ（毎日クォータ上限まで）
- F06のLivePortrait/Veo動画リアクション制作
- BWのシチュ画像もF06同様に展開
- 採用キャラを絞り込む（男女5キャラずつ＋動物でMVPリリース想定）

---

## 仕様決定事項（今回議論）

### 秘書プロフィール自動積み上げ（コア機能）
- 秘書の発言から事実を自動抽出→永続化→次回会話プロンプトに合流
- **ユーザー操作ゼロ設計**（手動編集/削除なし、泳がせる）
- 同じベースキャラ（F06）でもユーザーごとに異なる子に育つ
- 矛盾検知はGeminiに全量投げて自然に繋げさせる
- Wikipedia風プロフィールページで日付付きで履歴表示
- 例外: 「このキャラを最初からやり直す」リセットボタンのみ

### 代理系機能のスコープ確定
- お店/場所ピックアップ・リサーチ・企画段取り・文面代行・比較検討・秘書気遣い・実行一歩手前
- Web検索グラウンディング + ツールコールで大半カバー
- 長時間処理は非同期化してプッシュ通知で結果返却

### 画像入力パイプライン
- 撮影した画像をGemini Flashで解析
- 内容に応じてToDo/メモ/カレンダー/買い物リストに自動振り分け

---

## 技術スタック
- **フロントエンド**: Flutter（Web確認用、iOS/Android本番）
- **バックエンド**: Python FastAPI + Gemini 2.5 Flash（新SDK: google-genai）
- **カレンダー**: Google Calendar API（OAuth認証、calendar-auto プロジェクト）
- **画像生成**: Imagen 4.0（NORMAL/ULTRA/FAST）＋Gemini 2.5 Flash Image（編集用）
- **動画生成**: Veo 2.0（LivePortrait不要で直接生成可能）、Kling AI候補
- **インフラ**: ローカル開発中（将来 GCP Cloud Run + Cloud SQL）
- **フォント**: Noto Sans JP（google_fonts）

## 環境情報
- Windows Tailscale IP: `100.117.249.65`
- FastAPI: `0.0.0.0:8888`
- Flutter Web: `0.0.0.0:8080`（`subst K:` 経由）
- 画像ビューア: Port 8900（realistic）

## 重要ルール（メモリ記録済み）
- Gemini全任せ（プログラム側パース禁止）
- キャラ画像は胸上+両腕完全に写る構図
- 「imagen」= 毎日のガチャ用新規生成
- Flash Imageはゼロ生成NG、編集専用
- 聖域フォルダ: realistic/favorites, character_workshop, gacha_favorites
- Imagenルール: NORMAL女70枚 / ULTRA女30枚 / FAST男40枚目安
