# Phase 4 — Quality & Self-improvement(継続)

**目標**: 出力品質を担保し、Skill / Subagent 自体を進化させる。

**所要時間**: 月 1 時間 + 四半期 2 時間

**前提**: Phase 1-3 完了。

## 月次メンテ(目安 1 時間)

### 1. 重要 Skill / Subagent の eval 実行
- 各重要 Skill に**評価サンプル**(input → expected output)を `SKILL.md` と並べて保管
- 手動で 3-5 サンプル走らせて、出力が期待通りか確認

### 2. 既導入 skill の active 利用確認
- `/deep-research`、`/investigate`、`/autopilot`、`/bugfix`、`/code-review`、`/security-review`、`/verify` を 1 回ずつでも使ったか確認
- 使われていない skill は CLAUDE.md / Project に「こういう時はこの skill を使う」のリマインダを追記
- 既存 skill で目的を達成できる場面では自作 Skill / Subagent を作らない(2026 公式ベストプラクティス)

### 3. Subagent ペアテスト(Anthropic 公式手法)
同じプロンプトで「skill 有り subagent」「skill 無し subagent」を**同ターン spawn**、transcript を比較:
```
> 同じプロンプトを、(A) finance-analyst skill 有りの evaluator と、
  (B) skill 無しの evaluator に並列で投げて、transcript を比較してほしい
```
→ Skill の ROI が数値で見える

### 4. Skill/Subagent クリーンアップ
```
/code-review --fix         # 定義ファイルの自動クリーンアップ
/simplify                  # 冗長性削減(v2.1.154 改良版)
```

### 5. `/usage` チェック
```
/usage                     # モデル別/skill 別 breakdown
```
- 想定外コスト超過を発見
- Opus 4.8 が必要ない場面で使われていないか
- Sonnet/Haiku に落とせる subagent がないか

### 6. Output Style の見直し
- 学習中の分野は `learning` に切り替え忘れていないか
- 不要になったカスタム style は `/output-style:delete`

## 四半期メンテ(目安 2 時間)

### 1. agent-memory の curate
```bash
ls -lh ~/.claude/agent-memory/*/MEMORY.md
```
- 25KB 超の MEMORY.md は内容を統合・削除して整理
- 機密情報が混入していないか確認
- 一般化できる知見は `~/.claude/CLAUDE.md` に昇格

### 2. 未使用 Skill / Subagent の整理
```bash
/plugin list               # 全 plugin
/agents                    # 全 subagent
```
- 3 ヶ月未使用なら disable → prune
- 役割が被った subagent は統合

### 3. Skill marketplace 巡回
- 新作の人気 skill を試す
- 既存自作 skill のうち、公式版で代替できるものは置き換え

### 4. settings.json レビュー
- permissions.allow / ask / deny の運用実績で見直し
- 「常に ask されるが常に approve しているもの」は allow に昇格
- Auto mode の昇格判断

### 5. Routines レビュー
- 発火頻度と価値が見合っているか
- 通知のみで止まっている Routine は書き込み系へ昇格検討
- 不要になった Routine は削除

## 半年メンテ(目安 1 日)

### 1. `/team-onboarding` の個人版で `ONBOARDING.md` 生成
```
/team-onboarding
```
自分の使い方を半年に 1 回ドキュメント化。将来の自分や家族への引き継ぎ資料になる。

### 2. このリポの構造見直し
- `home-claude/` を最新の `~/.claude/` と同期
- `docs/ROADMAP.md` を最新状況に書き換え
- `projects/*.md` を実際に使っている Project Custom Instructions と同期

### 3. 大きな出力の最終チェックに `/ultrareview`
- 年次資産レビュー
- 重要契約書(住宅、保険、教育)
- 家族で共有する重要文書

## 長期自走タスク(Ralph Loop パターン)

- 既導入 `/loop` skill は **Ralph loop パターン**(コミュニティで著名な autonomous iteration loop)を実装している
- 終わりが明確で時間がかかる作業を**新規セッション毎に同じプロンプト**で繰り返す。ファイルシステムをメモリ代わりに使い、git commit で進捗を残すため context bloat しない
- 個人利用に向く長期自走タスクの例:
  - 家計データを過去 3 年分すべて Notion に正規化
  - 散らばったレシピメモを全部構造化 Markdown 化
  - 写真フォルダの年次自動分類とメタデータ整理
  - 学習プランの各セクション毎の参考資料収集
- 起動例:
  ```
  /loop 30m
  ```
  → 30 分おきに同じプロンプトでセッションを回す。停止条件を満たすか、ユーザーが止めるまで続く
- コスト目安: Sonnet 4.5/4.6 で API 課金なら ~$10/時間。Max 20× プランなら定額内に収まる
- **安全装置**:
  - 終了条件を明確にプロンプトに書く(「全データ移行完了 → 停止」)
  - 各イテレーション後に git commit してロールバック保険
  - 24 時間以内に手動レビュー(暴走確認)
- **使ってはいけない場面**:
  - 結果が可逆でないタスク(誤メール送信、家族予定の自動上書き)
  - 終了条件が曖昧なタスク
  - 機密データを大量に読み書きするタスク(`/usage` 監視必須)

## 年次メンテ

### 1. プラットフォーム全体の見直し
- モデル世代交代(現 Opus 4.8 → 翌春以降の 5.0 系)
- 新機能の取り込み判断:
  - **Managed Agents Dreaming** が GA したら導入(subagent 横断のメモリパターン抽出)
  - MCP tunnels で自前 NAS / 家庭内サーバ接続
  - Agent Teams が必要になったら導入

### 2. プライバシ監査
- agent-memory に機密混入がないか全数チェック
- Claude.ai Memory の内容棚卸し
- Project Knowledge に置いた資料の古い情報削除

### 3. このリポの year-tag
```bash
git tag v2026-personal
git push origin v2026-personal
```
過去状態へのロールバック保険。

## ノーゴール条件(やらないこと)

以下を「やった方が良さそう」と感じても**意図的にやらない**:
- Subagent を**5 体超に増やす**(delegate 判断が曖昧化)
- Skill を 20 個超抱え込む(Lean system prompt の恩恵を失う)
- `bypassPermissions` を常用する
- Claude.ai Memory に金融情報や家族の個人情報を入れる
- 自動化を一気に拡大する(段階的昇格の原則)
- 既存 skill(`/deep-research`、`/investigate`、`/autopilot` 等)で実現できる用途を、わざわざ自作 Subagent / Skill で再実装する(車輪の再発明)
- Ralph Loop(`/loop`)を **可逆でないタスク**で使う(誤動作のコストが取り返せない)
- Adversarial Review Team を毎回呼ぶ(コスト過大、判断遅延)

## 関連ドキュメント
- [ROADMAP.md](./ROADMAP.md) — 全体戦略(承認済プラン v4)
- [MAINTENANCE.md](./MAINTENANCE.md) — メンテチェックリスト(printer 用)
