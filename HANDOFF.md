# P_Secretary_App - 申し送り

## 現在の状況
- Flutter チャットUI完成（LINEライク吹き出し、ライトテーマ、紫ベース）
- FastAPI バックエンド稼働中（Gemini 2.5 Flash、フォールバック付き統一パイプライン）
- Flutter → FastAPI → Gemini の全経路が動作確認済み
- キャラ透過動画表示（Web版: HTMLオーバーレイ、PCのChromeで透過確認済み）
- キャラパネル右下表示（動的幅制御で吹き出し被り防止）
- blink_loop.py のループバグ修正済み（sin波のt_phase計算）

## キャラ画像
- bookworm: ファイル抱えポーズ再生成済み（BW_regen_4_cropped.png）
- F06銀髪ボブ: ベージュニットVネック微笑み（F06_beige_knit_3_cropped.png）
- 衣装バリエーション多数生成済み（web/assets/配下）
- LivePortraitパターンO確定（blink 1.5s/σ1.2, pitch 0.9, roll 0.15, brow 0.5）

## バックグラウンド処理（完了待ち）
- `D:/LivePortrait/BW_pattern_O_trans.webm` — bookworm透過処理中
- `D:/LivePortrait/F06_pattern_O_trans.webm` — F06透過処理中

## 技術スタック
- **フロントエンド**: Flutter（Web確認用、iOS/Android本番）
- **バックエンド**: Python FastAPI + Gemini 2.5 Flash（新SDK: google-genai）
- **インフラ**: 未セットアップ（GCP予定）
- **キャラ動画**: LivePortrait + birefnet-general透過処理

## 次のアクション
1. **Android Emulator セットアップ** — Android Studioで仮想デバイス作成、スマホ表示確認
2. 透過処理結果の確認・アプリ組み込み
3. 性格プロンプト移植（Bot版から全キャラ分）
4. キャラ切り替えUI
5. Firebase Auth セットアップ
6. 会話履歴のDB永続化（現在インメモリ）

## 重要ルール（メモリに記録済み）
- チャットの自然言語処理は全てGeminiに任せる（プログラム側パース禁止）
- キャラ画像は胸上+両腕完全に写る構図
- 画像生成: gemini-2.5-flash-image（上限なし）、imagen-4.0系（1日70枚）

## ファイアウォール開放済み
- ポート8080（Flutter Web Dev）
- ポート8888（FastAPI Dev）
