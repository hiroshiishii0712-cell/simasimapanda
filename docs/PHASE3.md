# Phase 3 — Agents & Automation: エージェント運用の本格構築

**目標**: subagent 群で「Personal Chief of Staff」を構築。受動的に AI を呼ぶ → 能動的に AI が動く へ移行。

**所要時間**: 2-3 週間(段階的)

**前提**: Phase 1, 2 完了。

**重要な前提**(2026 公式ベストプラクティス):
> "Most tasks don't need five agents; start with one main agent and add specialists only when context separation provides clear value." — Developers Digest 2026 Playbook

→ **コア 3 体から始める**。証拠ベースで後から拡張。

**仕様上の制約**:
- subagent memory は subagent ごと独立(共有されない)
- 横断知見は main の `~/.claude/CLAUDE.md` に置く

## 3-A. コア 3 体の subagent をインストール

```bash
mkdir -p ~/.claude/agents
cp home-claude/agents/*.md ~/.claude/agents/

# memory directory(初回起動時に自動作成されるが事前にも可)
mkdir -p ~/.claude/agent-memory/{evaluator,researcher,archiver}
```

CLI 起動後、確認:
```
/agents
```

Library タブに **evaluator**, **researcher**, **archiver** が表示されることを確認。

### 動作テスト

```
> 来月の予算を 15% 削減する案を 3 つ出して
                       # main agent が answer を出す
                       # → evaluator が自動 delegate される(description で PROACTIVELY)はず

> NISA と iDeCo の最新の制度変更を比較して
                       # → researcher が自動 delegate される(複数ソース比較)

> 今の比較結果を Notion に保存して
                       # → archiver が自動 delegate される
```

うまく delegate されない場合:
- `/agents` で description を確認、トリガーキーワードを追加
- `tools` に `Agent(evaluator, researcher, archiver)` が main から見えているか確認

## 3-B. 既存ビルトイン subagent を活用

- **Explore**(Haiku, read-only): 家計 CSV や写真フォルダの「漁り」
- **General-purpose**: 複雑な多段タスクのデフォルト

明示的に呼ぶ:
```
> Explore agent で 2024 年の家計 CSV から食費の上位カテゴリを抽出して
```

## 3-C. (任意)Subagent 用 Hook

例: `finance-analyst`(後で specialist として追加する場合)に PostToolUse hook で source 記録。

```yaml
# ~/.claude/agents/finance-analyst.md の frontmatter に追加
hooks:
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "~/.claude/agent-hooks/log-data-source.sh"
```

## 3-D. Routines を Web で設定(段階的)

Claude Code on the web で:
1. 左サイドバー → **Routines**(または Settings → Automation)
2. 以下を順次追加:

### 毎週日曜 21:00
```
来週の Calendar 予定と、過去 7 日の未返信 Gmail を要約。
重要そうな返信候補をドラフト 3 件まで作成(送信はしない)。
結果は push 通知で。
```

### 毎月 1 日
```
先月の家計データ(Drive の最新 CSV)を集計し、
Notion の「月次家計」ページに**下書きとして**追加。
```

### 毎月 15 日
```
今月の重要 Calendar 予定(終日イベント、初回ミーティング)を抽出して
push 通知。
```

**運用ルール**:
- 最初は**通知のみ**、書き込み系は手動承認
- 3 サイクル(=ほぼ 1 ヶ月)誤動作なしなら、書き込み系を自動化検討

## 3-E. Dynamic Workflows を試す(Opus 4.8 限定)

**まず `/deep-research` で慣れる**(同じ基盤、安全):
```
/deep-research

> 2026 年最新の家庭用太陽光発電と蓄電池のコスト比較(関東圏、4 人家族想定)
                       # 並列で複数ソースを fan-out → refutation → 集約
```

**個人向けユースケース例**:
- 旅行: 「3 目的地 × 5 テーマ」を並列 15 行程ドラフト → 比較
- 投信/ETF 20 銘柄を並列で 1 ページ要約 → 比較
- 1 年分レシートを月別並列集計 → 横断分析
- 興味分野の論文/書評を並列要約 → メタサマリ

**運用ルール**:
- 並列度は最初 4-8 から開始 → `/usage` で監視 → 16 並列まで段階拡大
- チェックポイント機能の確認(途中中断 → 再開できるか)
- コストが想定外なら subagent モデルを Sonnet/Haiku に落とす

> **既導入 skill で同パターン**: ローカル環境には `/deep-research`(fan-out + verify)、`/investigate`(並列仮説 + 反証)、`/autopilot`(5-angle 批評 + 実装 + バグハント)、`/bugfix`(再現 → 修正 → 回帰)が既に installed されている。**自作 Dynamic Workflow を組む前に、これらでカバーできないか確認**するのが鉄則。

## 3-F. Agent View を日常運用に組み込む

```
claude agents              # 全セッション俯瞰
claude agents --cwd ~/finance   # ドメイン別フィルタ
```

長尺セッションは `Ctrl+T` でピン留めして idle 生存させる。完了/ブロック状態を朝に俯瞰、push 通知と組み合わせる。

## 3-G. Subagent ガバナンス確認

`~/.claude/settings.json` の permissions が以下になっているか確認:

```json
{
  "permissions": {
    "allow": [
      "Agent(evaluator)",
      "Agent(researcher)",
      "Agent(archiver)",
      "Agent(Explore)",
      "Agent(general-purpose)"
    ]
  }
}
```

不要なビルトイン subagent は `permissions.deny` で無効化:
```json
"deny": ["Agent(claude-code-guide)"]
```

## 3-H. (オプション)Specialist Subagent の追加判断

コア 3 体を 1 ヶ月運用してから、以下のいずれかが起きたら **証拠を持って**追加判断:
- 過去 1 ヶ月で X ドメインで main の context が 2 回以上逼迫
- 同じ MCP 呼び出しが週 5 回以上
- 同じ system prompt 的指示を毎回書いている

候補:
- `finance-analyst`(opus, MCP=drive, `monthly-budget-report` skill preload)
- `family-coordinator`(sonnet, MCP=gmail+calendar)
- `travel-planner`(sonnet)

## 3-I. Adversarial Review Team(任意・重要決定時のみ)

- 重要決定(資産配分の大幅変更、住宅・教育・保険等の大きい契約、家族ルールの不可逆変更)では、3 つの独立 reviewer を**同ターンで並列 spawn** する
- 3 体は `home-claude/agents/{skeptic,architect,minimalist}.md` に定義済(本リポに含まれる)。インストールは PHASE 3-A と同じ手順で `~/.claude/agents/` にコピー
- 起動方法:
  ```
  > 次の判断について、skeptic / architect / minimalist の 3 視点で並列にレビューしてほしい:
    [判断内容を貼る]
  ```
- 各 reviewer は**他の reviewer の出力を見ない**(context が分離される)→ 偏った合意ではなく独立した批判が揃う
- 主 agent が 3 つの critique を統合し、利用者に提示
- 月に 1-2 回程度の重要決定でのみ使う(毎回使うとコストが嵩み、判断が遅くなる)
- evaluator との違い: evaluator は単独で「正しさ」を検証、3-lens team は「複数の視点から overall に sound か」を検証

## 3-J. Advanced: background: true + isolation: worktree

- 上級パターン。**コア 3 体運用が定着してから**試す
- `background: true` の subagent は**新規ツール承認を自動 deny** する(意図しない権限拡大を防ぐ)
- `isolation: worktree` で git worktree に隔離 → 同じファイルを並列に**別アプローチで**編集できる
- 既存ビルトイン `/batch` コマンドはこのパターンで並列 codebase 移行を実装
- 個人利用の活用例:
  - 同じ家計プロンプトを 3 並列で楽観 / 中立 / 悲観の前提で評価
  - 旅行行程を 3 並列で「コスト最優先」「時間最優先」「子供最優先」で生成
  - レシピ整理を 3 並列で異なるカテゴリ体系で試行 → 比較
- frontmatter 例:
  ```yaml
  ---
  name: scenario-explorer
  description: Explore one scenario in an isolated background subagent. Spawn 3 in parallel for comparison.
  background: true
  isolation: worktree
  model: sonnet
  effort: medium
  maxTurns: 12
  ---
  ```

## 検証

```
/agents                    # コア 3 体が見える
> 重要な判断を求めるプロンプト
                           # evaluator が auto delegate
> 複数ソース調査を要するプロンプト
                           # researcher が auto delegate
> 「保存して」と頼む
                           # archiver が auto delegate

ls ~/.claude/agent-memory/*/MEMORY.md
                           # 各 subagent が学習を蓄積開始
```

Web で Routine 発火を 1 サイクル待ち、想定通り push が届くか確認。

## 次のステップ

→ [PHASE4.md](./PHASE4.md): Quality & Self-improvement(継続メンテ)
