# プラットフォーム個別対応トラッカー

Flutter共通コードでは対応できず、プラットフォーム固有の実装が必要な機能を追跡する。
機能を実装するたびに更新し、未対応プラットフォームの抜け漏れを防ぐ。

---

## バックグラウンド復帰時の動画再生再開
- [x] Web — visibilitychange + pageshow + focus で再生再開
- [ ] iOS — AppLifecycleState で要対応
- [ ] Android — 同上

## 動画透過（VP9 alpha vs HEVC alpha）
- [x] Web — UA判定で webm/mp4 自動切替
- [x] iOS (Safari Web) — Mac ウォッチャーで HEVC alpha mp4 自動生成、UA判定で選択
- [ ] iOS (ネイティブ) — 未検討
- [ ] Android — VP9 alpha 対応端末が多いが要確認

## 動画ロード時の表示フラッシュ防止
- [x] Web — display:none → canplaythrough で block
- [ ] iOS (ネイティブ) — 未検討
- [ ] Android — 未検討

## キャラ動画の位置（入力バー上端に揃え）
- [x] Web — Flutter側で入力バー高さを取得しJS経由でvideo.style.bottom更新
- [ ] iOS (ネイティブ) — Flutter Widget で実装すれば共通化可能
- [ ] Android — 同上

## 日本語パス対策（ビルド）
- [x] Web — 問題なし
- [ ] iOS — 未確認（Macビルド時のパスは英数字が多い）
- [x] Android — gradle.properties に overridePathCheck=true、subst K: で回避
