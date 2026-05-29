# Claude 利用環境の最適化 — 戦略方針と段階的ロードマップ(v4 / エージェント運用強化版)

## Context(背景・目的)

ユーザーは Claude Pro/Max を契約し、3 つの利用面 — **Claude Code on the web**、**Claude.ai チャット**、**Claude Code CLI(ローカル)** — を並行運用。用途は**個人利用**(家計・資産運用、家族の日常、旅行/レシピ、趣味、学習)。

本プランは「**自分専用の Chief of Staff**」を構築するための戦略と段階的ロードマップ。**2026-05-28〜29 にリリースされた Opus 4.8 + Claude Code v2.1.156 + Dynamic Workflows + 大幅強化されたサブエージェント仕様**を前提に設計する。

**前提バージョン(2026-05-29 時点)**:
- Claude Code CLI: **v2.1.156**(5/29 01:42)
- Claude Opus 4.8 GA(effort 既定 `high`、Adaptive thinking、1M context 標準)
- Sonnet 4.6 / Haiku 4.5
- Managed Agents: multiagent orchestration / webhooks / self-hosted sandboxes / Memory tool 全 GA or public beta

---

## エージェント運用周りの 2026-05 までの強化サマリ(本改訂の中核)

### 1. サブエージェント仕様の大幅拡張(Claude Code)

`~/.claude/agents/<name>.md` の YAML frontmatter で**14 フィールド**が指定可能になった:

| フィールド | 役割 | 個人利用での活用 |
|---|---|---|
| `name` / `description` | 必須。description は**いつ delegate するか**を Claude が判断する手がかり | ドメイン名を明示 |
| `tools` (allowlist) / `disallowedTools` (denylist) | 使用ツール制御 | researcher は Read/Grep/Web のみ等 |
| `model` | `sonnet`/`opus`/`haiku`/full ID/`inherit` | コスト最適化(下記参照) |
| `permissionMode` | `default`/`acceptEdits`/`auto`/`dontAsk`/`bypassPermissions`/`plan` | 用途別に分離 |
| `maxTurns` | 暴走防止 | researcher は 10 ターン上限 |
| `skills` | **起動時に Skill を context にプリロード**(content 注入、description だけでない) | 家計 subagent に finance Skill 自動注入 |
| `mcpServers` | サブエージェント専用 MCP 接続 | playwright を browser-tester だけに |
| `hooks` | サブエージェント固有の lifecycle hook | DB 読取 subagent の write 遮断 |
| **`memory`** | **persistent memory ディレクトリ**(`user`/`project`/`local`) | **`user` で `~/.claude/agent-memory/<name>/` に学習を蓄積** |
| `background` | 常に背景実行 | 監視系 subagent |
| `effort` | session の effort 上書き | researcher は `medium`、evaluator は `xhigh` |
| `isolation: worktree` | 一時 git worktree で隔離 | 試行錯誤系 |
| `color` | UI 識別 | ドメイン別配色 |
| `initialPrompt` | `--agent` 起動時の自動 first turn | 常駐 agent の初動 |

特に**`memory: user`** は個人利用のゲームチェンジャー: 各 subagent が `~/.claude/agent-memory/<name>/MEMORY.md` に学習を蓄積、毎回のセッションで先頭 200 行/25KB が自動 inject される。

### 2. Agent View(`claude agents` / `/agents` コマンド)

- 全セッションを 1 画面で俯瞰、`Ctrl+T` でピン留めして idle でも生存
- **Library タブで Claude に subagent を生成させられる**("Generate with Claude")
- Running タブで稼働中の subagent を確認・停止
- v2.1.144 で `--json` 出力、v2.1.145 で OTEL agent spans

### 3. Agent Teams(セッション間通信)

複数セッションが**メッセージを送り合う**。例: フロントエンド変更 → API 変更 → テスト更新 を順次連携する coordinator パターン。サブエージェント定義を teammate のテンプレとして再利用可。

### 4. Dynamic Workflows(Opus 4.8 同時投入、5/28)

- Claude が JavaScript の編成スクリプトを**自分で書き**、**最大 16 並列 / 計 1,000 サブエージェント**
- **チェックポイント機能**で長尺タスクも安全に再開
- **Refutation pass**: 主張する subagent と**反証を試みる subagent** を立て、生き残った主張だけを返す → **自己過大評価が構造的に防がれる**
- **`/deep-research`** が同梱されており、個人ユーザーでも即試せる(本環境にも skill として導入済み)
- Max / Team / Enterprise で利用可

### 5. Managed Agents 強化(5/6 公開)

- **Multiagent orchestration** public beta: **20 specialist × 25 並列スレッド**、リード agent が分解・delegate
- **Webhooks**: agent 完了で HTTP コールバック → event-driven 連携が容易
- **Memory tool** public beta(4/23): `/mnt/memory/` ディレクトリ、100 kB/memory、変更履歴+rollback+redaction
- **MCP tunnels**(5/19): プライベートネットワーク内の MCP に接続
- **Self-hosted sandboxes**: 機密データは自分のインフラ、orchestration は Anthropic 側

### 6. Hooks for Subagents

- `PreToolUse` / `PostToolUse` / `Stop`(`SubagentStop` に runtime 変換)
- 用途: 読取専用 DB クエリの validate、編集後 lint、危険操作の遮断
- **subagent frontmatter 内**に書くと**その subagent 稼働中のみ有効**

### 7. Hooks の 12 lifecycle events を構造的に活用

| Event | 発火タイミング | 個人利用での使い道 |
|---|---|---|
| `SessionStart` | セッション開始時 | 個人ナレッジ MD を `$CLAUDE_ENV_FILE` 経由で注入、Project Dir 確認 |
| `SessionEnd` | セッション終了時 | 学習内容の自動 commit、archive |
| `UserPromptSubmit` | 入力送信直後 | プライバシ語(口座番号パターン等)の警告 |
| `PreToolUse` | ツール呼出前 | Gmail send / Calendar create_event の確認強制 |
| `PostToolUse` | ツール呼出後 | 編集後 lint、家計データ参照時の source パス記録 |
| `PreCompact` | 圧縮前 | transcript バックアップ(`async: true` 推奨) |
| `Notification` | Claude 通知時 | Slack/TTS にルート、家族向け状況報告 |
| `Stop` / `StopFailure` | turn 完了/失敗時 | 既存の未push検知、コミット強制 |
| **`SubagentStart`** | subagent 起動時 | 起動ログ、コスト予測表示 |
| **`SubagentStop`** | subagent 完了時 | `agent_id`/`agent_type`/`transcript_path`/`last_assistant_message` を受け取り、Evaluator subagent 自動起動などに連鎖 |

特に **`SubagentStart`/`SubagentStop` で agent orchestration を観察可能**。Conditional `if` hook と組み合わせて「`effort.level == xhigh` の重要 subagent が止まったら自動で evaluator を回す」が可能。

### 8. Output Styles(個人利用に有効、未活用)

CLI 環境に既に `explanatory-output-style` と `learning-output-style` プラグインが登録済(`tengu_amber_lattice`)。

| Style | 挙動 | 個人利用での使い分け |
|---|---|---|
| **Default** | 簡潔・直接 | 通常運用 |
| **Explanatory** | "Insights" 付きで設計判断や trade-off を都度説明 | **未知のドメイン学習時**(投資、税制、新しい趣味分野等) |
| **Learning** | TODO(human) マーカーを残し、ユーザーに小さい実装を依頼 | **能動的に身に付けたい時**(プログラミング学習、新しいツール習得) |
| **Custom** | `/output-style:new` で雛形作成 | 「家族向けに小学生でも分かる説明」専用 style 等 |

→ Phase 2 で `family-explain` カスタム output style を作るのが効く。

### 9. 既存ビルトイン subagent(忘れず活用)

| Agent | Model | 用途 |
|---|---|---|
| Explore | Haiku | コードベース/ファイル探索(read-only) |
| Plan | inherit | plan mode 中の context 収集 |
| General-purpose | inherit | 複雑な複数ステップタスク |
| statusline-setup | Sonnet | `/statusline` 設定 |
| claude-code-guide | Haiku | Claude Code 機能の質問対応 |

個人利用でも**Explore を「家計 CSV を漁る」「写真フォルダの整理対象を見つける」**等に転用可。

---

## 直近 1 ヶ月のモデル/プラットフォームアップデート(再掲・差分のみ)

### Opus 4.8(5/28 GA)— 個人利用に直接効く

| 指標 | 4.7 | **4.8** | 個人利用での意味 |
|---|---|---|---|
| SWE-bench Pro | 64.3% | **69.2%** | 自作スクリプト品質向上 |
| GraphWalks 1M 長文 F1 | 40.3% | **68.1%** | 長尺 PDF/メール束/家計データ読解が激変 |
| USAMO 2026 数学 | 69.3% | **96.7%** | 家計最適化の数値計算が信頼可 |
| コード欠陥見逃し | 基準 | **1/4** | 自作物の誤り検出率向上 |
| 過信(overconfidence) | 基準 | **1/10 以下** | 「自信満々に間違える」激減 |
| 重要事象の見落とし | 基準 | **3.7%** | 旅行プラン等の抜けが減る |

- $5/$25 据え置き、Fast mode は **2× 価格で 2.5× 速度**(Max は既定)
- **`effort` 既定 `high`、Adaptive thinking で無駄なし**
- 1M context 標準、128k max output、cache 最小 1,024 トークン

### Claude Code v2.1.139 → v2.1.156 の決定的変化

- **v2.1.154**: Opus 4.8 + Dynamic Workflows + Lean system prompt 既定 + MCP stdio に `CLAUDE_CODE_SESSION_ID`/`CLAUDECODE=1`
- **v2.1.152**: `/code-review --fix`、`/reload-skills`、hook の `disallowed-tools`/`sessionTitle`/exec form
- **v2.1.147**: 背景セッションのピン留め(idle 生存)、`/code-review`(旧 `/simplify`)改名
- **v2.1.143**: Plugin 依存強制、worktree 制御(`baseRef`/`bgIsolation`)
- **v2.1.140〜139**: Agent View、`/goal`、`/scroll-speed`
- **v2.1.156**: Opus 4.8 thinking block バグ修正(本日 5/29 01:42)

### 2026 ベストプラクティスの中心

Anthropic 公式が「**Context Engineering は 2026 の load-bearing skill**」と明言。要点:
- System prompt: 簡潔・直接的・"右の altitude"
- Tool: トークン効率の良い返却、効率的な agent 行動を促す
- Long-running agent: セッション間の記憶ブリッジ(Memory tool / agent-memory)
- **Orchestrator–Subagent + Generator–Verifier** が標準パターン

### エンタープライズ事例(個人利用への示唆)

- **PwC × Anthropic**: 30,000 人、**70% 改善**、保険引受 10wk→10d
- **Deloitte**: 470,000 人展開
- **Claude Cowork** GA(2/2026): ノンテク 60%+、20–30% 時短
- → 個人版は「**Project + Skill + Subagent + Routine + コネクタ**」で同思想を再現

---

## 現状アセスメント(2026-05-29 時点)

| 項目 | 状態 | 評価 |
|---|---|---|
| `~/.claude/settings.json` | Stop hook + Skill 許可のみ | ⚠️ Hook 拡張余地大、Conditional `if` 未活用、permissions 最小 |
| `~/.claude/CLAUDE.md` | **未作成** | ❌ **最優先で作成** |
| `~/.claude/agents/` | **なし** | ❌ **Phase 3 の中核として新設** |
| `~/.claude/agent-memory/` | **なし** | ❌ persistent memory 未活用 |
| `~/.claude/skills/` | プリセット `session-start-hook` のみ | ❌ 個人用 Skill 空 |
| プロジェクト `.claude/agents/` | なし | ❌ |
| MCP 接続 | Gmail / Calendar / Drive / Notion / Outlook / GitHub | ✅ 接続済(scope 化が次の課題) |
| プラグイン導入 | 0 | ⚠️ marketplace から厳選導入 |
| Claude.ai Projects | 未確認 | ⚠️ Phase 0 で棚卸し |
| 利用モデル | **Opus 4.8** GA、effort 既定 `high` | ✅ 最新 |
| Claude Code バージョン | (要確認、推奨 **v2.1.156**) | ⚠️ 起動時に確認 |
| 既導入の `/deep-research` skill | ✅ 利用可能 | Phase 3 で活用 |

---

## 戦略方針(Strategy)

### 設計原則(8 条)— エージェント中心に再構成

1. **3 面で役割を分離**: 「考える/書く」は Claude.ai、「作る/動かす」は CLI、「常駐させる」は Web(Routines + push)
2. **記憶は 3 層 + agent-memory**: ① `~/.claude/CLAUDE.md`(全 CLI 共通) ② Claude.ai Custom Instructions(Web/Chat) ③ Project / Skill 個別 ④ **`~/.claude/agent-memory/<name>/MEMORY.md` で subagent 別に学習蓄積**
3. **ドメイン = Project、反復 = Skill、専門 = Subagent**: ドメインで Project に切り、反復作業を Skill 化、専門役割を Subagent 化。**役割が違うものを混ぜない**
4. **Orchestrator–Subagent + Refutation pass**: main session(Opus 4.8)が orchestrator、安価 model の specialist subagent に分配、重要主張は **Dynamic Workflows の refutation pass** で構造的に検証
5. **Subagent ごとに `tools` / `mcpServers` / `permissionMode` を最小権限化**: 用途別に厳密に分離。researcher は読取専用、archiver は特定 MCP のみ、evaluator は no-MCP
6. **`memory: user` で subagent を育てる**: 各 subagent が自分の MEMORY.md を持ち、毎回学んだことを書き、次回読む(Anthropic 公式推奨パターン)
7. **Skill marketplace ファースト**: `claudemarketplace.com` 等で**ratings/installs 上位**から漁って導入、自作は本当に固有の物のみ
8. **半自動 → 全自動 への段階移行**: Routines/Hooks は最初「ドラフト→人間レビュー→確定」、Auto mode の信頼が積まれたら昇格

### Subagent モデル選択ガイド

| 役割 | 推奨 model | effort | 理由 |
|---|---|---|---|
| Orchestrator(main) | **Opus 4.8** | `high` | 計画立案・統合 |
| evaluator(重要出力検証) | **Opus 4.8** | `xhigh` | honesty 改善が活きる |
| researcher(Web/MCP 検索) | **Sonnet 4.6** | `medium` | コスパ |
| domain-specialist(家計/旅行 等) | **Sonnet 4.6** | `medium` | 軽量 |
| archiver(整形保存) | **Haiku 4.5** | `low` | 安価で十分 |
| explorer(ファイル/CSV 漁り) | **Haiku 4.5**(built-in Explore) | `low` | 既定 |

### 利用面の役割分担

| 利用面 | 主役割 | 具体例 |
|---|---|---|
| **Claude.ai (Chat + Projects)** | 思考の壁打ち、長期記憶、画像/PDF 読解 | 家計 Project に明細 PDF 投入、Memory にプロファイル蓄積 |
| **Claude Code on the web** | 常駐・スケジュール、push、長尺 Dynamic Workflows | 毎週日曜 Routine で家計集計、年次レビューで `/ultrareview` |
| **Claude Code CLI(ローカル)** | ファイル操作、subagent 群の本拠地、機密寄り | レシピ整理、家計 CSV、**agent-memory で育てた個人 subagent 群** |

---

## 段階的ロードマップ(4 Phases、6 週間 + 継続)

### Phase 0 — 棚卸し(Day 1, 30 分)

- Claude.ai Web の **Profile / Custom Instructions** 現状を控える
- Claude.ai **Memory** ON/OFF 確認
- 既存 **Project 一覧**(あれば)
- MCP 接続の Gmail/Calendar が個人 / 業務(`@eneco.co.jp`)どちらか
- CLI で `/usage` と `claude --version` 確認(**v2.1.156 未満なら更新**)

### Phase 1 — Foundation: アイデンティティと記憶(Week 1)

**1-A. `~/.claude/CLAUDE.md` を 500 トークン以内で作成**
- 名前、家族構成の概要、言語、価値観、出力スタイル、主要ドメイン、最終更新日
- 機密情報(口座番号・パスワード)は書かない

**1-B. Claude.ai Custom Instructions** — 上記の核 ~300 字版を Profile に転写、Memory `ON`

**1-C. Claude Code on the web SessionStart hook**
- リポに `.claude/settings.json` 配置、`$CLAUDE_ENV_FILE` 経由でナレッジ参照

**1-D. settings.json 強化**
- `permissions.allow`: `Read`, `Grep`, `Glob`, `WebSearch`, `WebFetch`(read-only は素通り)
- `permissions.ask`: Gmail send / Calendar create_event / file delete / Bash `rm`
- **Auto mode `enabled`**(分類器による安全自動承認)
- Mobile push 通知有効化

**1-E. Hooks の基礎セット**(個人利用最小構成)
- `SessionStart`: 個人ナレッジ MD を `$CLAUDE_ENV_FILE` に注入(既存 `session-start-hook` skill 参照)
- `PreCompact`: transcript を `~/.claude/backups/` に async バックアップ
- `Stop`: 既存の未push検知を継続
- `Notification`: 任意で macOS/Linux の通知センターに転送

**1-F. Output Style の選択**
- 通常運用は **Default**
- 投資・税制等 **未知ドメインの学習中は Explanatory** に一時切替(`/output-style explanatory`)
- プログラミング学習や能動的習得時は **Learning**
- Phase 2 以降で **`family-explain` custom output style**(家族向け説明用)を `/output-style:new` で作成

### Phase 2 — Knowledge Layer: ドメイン別 Projects と Skills(Week 2–3)

**2-A. Claude.ai Projects(MECE で 5 + 1 構成)**

家計・資産 / 家族・日常 / 旅行 / 料理・レシピ / 趣味・学習 / (汎用 Inbox)

各 Project に**目的固有 Custom Instructions**、Project 間で内容重複ゼロ。

**2-B. Skill marketplace から導入(まず漁る)**
- `/plugin marketplace add anthropics/skills` で**公式リポ追加**(https://github.com/anthropics/skills)。document系(.pptx/.xlsx/.docx/.pdf 実操作)、`skill-creator`、`frontend-design` 等の reference 実装が手に入る
- コミュニティ候補: `temporal-reasoning-sleuth`(時系列推論)/ `humanize-writing`(自然文章)/ `code-reviewer` / `changelog-generator`
- 大型コレクション例: `Anthropic-Cybersecurity-Skills`(754 skills, MITRE ATT&CK 等にマップ済)— 構造化された Skill 群の参考に
- インストール後 1 週間使って ROI 評価、不要なら `claude plugin disable` → `prune`

**2-C. 自作 Skill(本当に固有な物のみ)** — 各 30–50 行、`disallowed-tools` で副作用ツール遮断
- `monthly-budget-report`、`recipe-organizer`、`travel-itinerary`、`weekly-digest`

**2-D. (オプション)Obsidian vault 連携**
- 採用する場合は PARA 構造(Projects/Areas/Resources/Archive)
- Notion をマスターにするなら不要

### Phase 3 — Agents & Automation: **エージェント運用の本格構築**(Week 4–6)

ゴール: subagent 群で「Personal Chief of Staff」を構築。**Anthropic 公式 + 2026 ヘビーユーザー知見の合意は「lean に始めろ」**:
> "Most tasks don't need five agents; start with one main agent and add specialists only when **context separation provides clear value**." — Developers Digest 2026 Playbook

これを踏まえ、本プランは **3 体から始めて、必要が証明されたら specialist を増やす** 段階アプローチを取る。

**重要な仕様上の制約(2026/5 確認)**:
- **subagent memory は subagent ごと独立**で共有されない。`evaluator` の MEMORY.md は `researcher` には見えない。
- → 横断知見が欲しい場合は **main の `~/.claude/CLAUDE.md`** に共通知識を置く。または将来 Managed Agents の **「Dreaming」**(複数 agent の memory を横断レビューする機能、現 research preview)が GA したら導入。

#### 3-A. **コア 3 体**を `/agents` で作る(`~/.claude/agents/`)

`/agents` コマンドの "Generate with Claude" で雛形 → 手直し。各 ~40 行。**この 3 体だけで個人運用の大半をカバー**できる(役割が context separation の観点で本質的に異なる)。

**description は Claude の delegation router**(2026 公式ガイド)。次の鉄則を守る:
- **トリガー条件**を書く(能力一覧ではなく)。"Reviews code for security issues before commits" > "security expert"
- **"Use PROACTIVELY"** / **"MUST BE USED"** で auto-delegation を強制
- **具体例フレーズ**を含める("when investigating multi-source questions")

**1. `evaluator` — 重要出力の独立検証**
```yaml
---
name: evaluator
description: Independently evaluate important outputs. MUST BE USED PROACTIVELY immediately after the main agent produces financial advice, travel plans, family-facing explanations, or any decision-affecting summary. Also triggers on phrases like "check this", "is this right", "verify this".
tools: Read, Grep, WebSearch
disallowedTools: Write, Edit, Bash
model: opus
effort: xhigh
memory: user
color: red
maxTurns: 8
---
You are an independent evaluator. Before starting, read your MEMORY.md for known failure patterns. Apply explicit criteria (accuracy, completeness, hidden risks, alternative interpretations). Be skeptical. Cite specific issues with quote or file:line. If the output is sound, say so concisely. After finishing, append recurring failure patterns to your MEMORY.md.
```

**2. `researcher` — Web/MCP 検索の専担(コンテキスト隔離)**
```yaml
---
name: researcher
description: Use PROACTIVELY when a question requires gathering information from multiple web sources, MCP-connected services (Gmail/Calendar/Drive/Notion/Outlook), or comparing 3+ alternatives. Keeps search results out of the main context window.
tools: Read, Grep, WebSearch, WebFetch
disallowedTools: Write, Edit
model: sonnet
effort: medium
memory: user
color: blue
maxTurns: 15
---
You are a research specialist. Before starting, read your MEMORY.md for known reliable sources. Triangulate sources, prefer primary sources, note publication dates, distinguish facts from opinions. Return a concise summary with citations. After finishing, append newly-discovered reliable sources to your MEMORY.md.
```

**3. `archiver` — Notion/Drive への整形保存**
```yaml
---
name: archiver
description: Use PROACTIVELY after a decision, summary, plan, or research result is finalized and needs to be persisted. Formats content as markdown and saves to the correct Notion page or Drive folder.
mcpServers:
  - notion
  - googledrive
disallowedTools: WebSearch, WebFetch
model: haiku
effort: low
memory: user
color: green
maxTurns: 5
---
You format finalized content (markdown headings, tables, bullet lists) and save it to the correct Notion page or Drive folder. Before starting, read your MEMORY.md for known destination conventions. Ask once if destination is ambiguous. After finishing, append destination/format rules to your MEMORY.md.
```

**Subagent ペアテスト手法**(Anthropic 公式推奨): 同じターンで「skill 有り subagent」と「skill 無し subagent」を spawn して transcripts を比較し、skill の効果を測定。Phase 4 のメンテで使う。

**(オプション: 後から追加判断する specialist)**

下記は **Phase 3 着手時には作らない**。コア 3 体を 1 ヶ月運用し、特定ドメインで「main の context が常に汚染される」「同じプロンプトを毎回書いている」と感じたら**証拠を持って**追加判断する:

- `finance-analyst`(opus, effort=high, MCP=drive, `monthly-budget-report` skill preload) — 家計が main の context を圧迫し始めたら
- `family-coordinator`(sonnet, MCP=gmail+calendar) — 家族系の MCP 呼び出しが頻繁になってきたら
- `travel-planner`(sonnet) — 旅行プランニングが定常タスクになったら

**この lean な始め方は Anthropic 公式 + ヘビーユーザー(Developers Digest 2026 Playbook、Tembo 2026 Practical Guide)の合意**。Subagent を作りすぎると delegate 判断が曖昧化し、逆に効率が落ちる。

#### 3-B. 既存ビルトイン subagent を活用

- **Explore**: 家計 CSV や写真フォルダの「漁り」専担(read-only、Haiku で軽量)
- **General-purpose**: 複雑な多段タスクのデフォルト
- 不要なものは `permissions.deny: ["Agent(Explore)"]` で無効化可

#### 3-C. Subagent 用 Hook を frontmatter に組み込む

例: `finance-analyst` に PostToolUse hook で「家計データを参照したら必ず source path を MEMORY.md に追記」:
```yaml
hooks:
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "~/.claude/agent-hooks/log-data-source.sh"
```

#### 3-D. Routines を Web で設定(段階的)

- 毎週日曜 21:00: 来週予定 + 未返信 Gmail サマリ → push
- 毎月 1 日: 先月の家計集計ドラフト → Notion 下書き
- 毎月 15 日: 今月の重要 Calendar 予定抽出
- 最初は通知のみ、承認確認後に書き込み系へ昇格

#### 3-E. Dynamic Workflows を試す(Opus 4.8 限定)

**個人利用に向くユースケース**:
- 旅行: 「3 目的地 × 5 テーマ」を並列 15 行程ドラフト → refutation pass で齟齬を炙る → 比較
- 投信/ETF 20 銘柄を並列で 1 ページ要約 → refutation で「リスク見落とし」検出 → 比較
- 1 年分レシートを月別並列集計 → 横断分析
- 興味分野の論文を並列要約 → メタサマリ

**運用**:
- まず**既導入の `/deep-research` skill**(同じ Dynamic Workflow ベース)で慣れる
- 並列度 4–8 から開始 → `/usage` 監視 → 16 並列まで段階拡大
- **チェックポイント機能**で長尺タスクの中断耐性を確認

#### 3-F. Agent View (`claude agents`) を日常運用に組み込む

- ピン留めで常駐: 「家計監視」「家族カレンダー」など
- `Ctrl+T` ピン留め、`claude agents --cwd <path>` で domain 別フィルタ
- 完了/ブロック状態を朝に俯瞰、push 通知と組み合わせる

#### 3-G. Settings.json で Subagent ガバナンス

```json
{
  "permissions": {
    "allow": ["Read", "Grep", "Glob", "WebSearch", "WebFetch", "Agent(evaluator, researcher, archiver, Explore)"],
    "ask": ["Bash(rm:*)", "Bash(git push:*)", "mcp__gmail__create_draft", "mcp__googlecalendar__create_event"],
    "deny": ["Bash(rm -rf /:*)"]
  }
}
```

→ subagent も `tools` で `Agent(researcher, archiver)` のように**他の subagent 呼び出しを制限**でき、暴走連鎖を防げる。

#### 3-H. **エンタープライズ知見の個人版**(PwC/Deloitte パターンの翻訳)

- **Center of Excellence パターン** → 個人版は **`~/.claude/CLAUDE.md` + `~/.claude/agents/` + `~/.claude/agent-memory/` を Git 管理**(プライバシ配慮の上)。設定が「自分の知的資産」として育つ
- **「ドラフトのみ、人間が最終判断」原則** → PwC が規制業界で採用する原則。家計/家族決定でも同じ
- **20–30% 時短(Cowork ノンテク利用)** → 個人でも Routines + push で実現可能な目標値
- **70% delivery velocity 改善(PwC エンジニアリング)** → 個人ナレッジワークでも Dynamic Workflows + Skill 蓄積で同程度の体感速度向上が期待

### Phase 4 — Quality & Self-improvement(継続)

**自動化されたメンテナンス**:
- 重要 Skill / Subagent に **eval(評価)サンプル** を並べ、月 1 で実行
- **Subagent ペアテスト**(Anthropic 公式手法): 同じプロンプトで「skill 有り subagent」「skill 無し subagent」を同ターン spawn、transcript 比較で skill ROI を測定
- 月 1 で `/code-review --fix` で Skill/Subagent 定義をクリーンアップ
- 月 1 で `/simplify`(v2.1.154 改良版)で Skill 冗長性削減
- `/usage` 月初確認、想定外コスト修正(モデル別/skill 別の breakdown を確認)
- 半年に 1 回 **`/team-onboarding` の個人版**で `ONBOARDING.md` 生成
- **`/ultrareview`** を年次資産レビュー、住宅契約書最終チェックに
- **agent-memory の MEMORY.md** を四半期に 1 回レビュー、25KB 超なら curate
- Skill marketplace を四半期に 1 回巡回して新ヒットを試す
- **Output style を用途に応じ切替**(学習モードは learning、家族向け説明は family-explain custom)

**Subagent 拡張の判断ロジック**(コア 3 体 → 拡張):
- 「過去 1 ヶ月で X ドメインのタスクで main の context が常に逼迫した」が **2 回以上** → 専門 subagent を追加
- 「同じ MCP 呼び出しが週 5 回以上」 → 専門 subagent に MCP を移譲
- 「同じ system prompt 的指示を毎回書いている」 → `initialPrompt` か skill 化
- → **証拠ベースで追加**(無計画な subagent 増加は避ける)

**将来の新機能を取り込むタイミング**:
- **Managed Agents Dreaming**(現 research preview): GA したら subagent 横断のメモリパターン抽出に使う。コア 3 体間で学習が分断されている問題を構造的に解決
- **MCP tunnels**: ホームネットワーク内に NAS や自前 MCP を立てるなら導入
- **Agent Teams**: subagent では足りない「セッション間通信」が必要になったら(現状は不要)

---

## 重要ファイルと参考実装

**新規/編集対象**:
- `/root/.claude/CLAUDE.md` — 新規(500 トークン以内)
- `/root/.claude/settings.json` — 拡張(permissions / Auto mode / Conditional `if` / Subagent ガバナンス)
- `/root/.claude/agents/{evaluator,researcher,archiver,finance-analyst,family-coordinator}.md` — **5 体の subagent 定義**
- `/root/.claude/agent-memory/<name>/MEMORY.md` — subagent 別 persistent memory(自動生成、手動 curate)
- `/root/.claude/agent-hooks/*.sh` — subagent 用 hook スクリプト
- `/root/.claude/skills/<name>/SKILL.md` — 自作 Skill
- `/home/user/H.141_personal/.claude/settings.json` / `hooks/session-start.sh` — プロジェクト固有

**参考にする既存テンプレ**:
- `~/.claude/skills/session-start-hook/SKILL.md` — Skill の YAML frontmatter
- `~/.claude/stop-hook-git-check.sh` — Hook 実装パターン
- 既導入 skill: `deep-research`, `code-review`, `verify`, `init`, `simplify`, `loop`, `claude-api`, `run`

---

## 検証方法(How to Verify)

1. **Phase 1**: 新規 Claude.ai チャットで個人プロファイルが反映されているか。CLI で `/memory` 確認、`/effort` で `high` 既定確認
2. **Phase 2**: 各 Project の固有指示が効くか。CLI で Marketplace skill が `/plugin` から見えるか
3. **Phase 3**:
   - `/agents` で 5 体の subagent が Library に表示
   - 「家計について相談したい」と main に投げたら **`finance-analyst` が自動 delegate** される
   - 重要結論が出たら **`evaluator` が自動 review** される(description で proactively と書いたため)
   - `~/.claude/agent-memory/<name>/MEMORY.md` に学習が蓄積されているか確認
   - `claude agents` で Agent View が動作、`/deep-research` で Dynamic Workflow が走るか
   - Routine 発火を 1 サイクル確認
4. **Phase 4**: `/usage` でモデル使い分けが想定通りか、`/code-review --fix` で定義クリーンアップ実行

---

## 留意事項(Risks & Caveats)

- **プライバシ**: 個人情報・金融情報は CLAUDE.md / Skill / Memory / agent-memory に書かない。一般方針のみ。具体データは都度添付。
- **Subagent description が delegate を決める**: 各 description を**いつ呼ぶか**で明確に書く(`Use proactively after...` 等)。曖昧だと delegate されない
- **agent-memory の肥大化**: 25KB 超で curate が促されるが、自分でも四半期見直し。機密も書かれていないか定期確認
- **`bypassPermissions` は使わない**: 個人利用では危険すぎる。常に `auto` か `default`
- **Auto mode 昇格**: 最初は危険行動のみブロック、3 ヶ月誤動作ゼロが続いたら read-only 完全自動化、send 系は最後まで手動承認
- **Dynamic Workflows のコスト**: 16 並列はトークン消費が大きい。最初は 4–8 並列、`/usage` 監視必須。subagent モデルを Sonnet/Haiku に落として節約可
- **Refutation pass の解釈**: 反証で消えた主張も**完全に間違いとは限らない**。重要決定では Dynamic Workflows の出力を最終 Evaluator subagent で再評価
- **業務と個人の分離**: `h.ishii@eneco.co.jp` が業務なら、個人と業務は別 Project / 別 MCP 接続(または別 Claude.ai アカウント)
- **Skill 肥大化**: 3 ヶ月未使用 Skill は disable → prune。Lean system prompt の恩恵を維持
- **Subagent 数の膨張**: 役割が被ったら統合。5 体上限を目安に(増やすほど delegate 判断が曖昧化)

---

## オープン課題(ユーザー確認推奨)

1. Claude.ai Web の Profile / Memory に既に書いた内容を共有してほしい(重複防止)
2. MCP 接続の Gmail/Calendar が個人 / 業務(`@eneco.co.jp`)のどちらか
3. **Notion / Drive のマスター保管庫**をどちらにするか(両方接続済み、二重管理回避)
4. Obsidian vault を導入するか(Notion で完結なら不要)
5. Phase 1 から進めるか、優先ドメインから先行構築するか
6. **コア 3 体(evaluator / researcher / archiver)で開始**する案で OK か、それとも家計/家族 specialist を最初から組み込みたいか(後者は公式推奨外だが個人の優先度次第)
7. Dynamic Workflows を Phase 3 で試すか(まず `/deep-research` で慣れる案)、Phase 4 まで保留にして基本運用を固めるか
8. **Auto mode** を Phase 1 で `enabled` にしてよいか
9. agent-memory の **`user` スコープ**(全プロジェクト共通)で進めて良いか、`local` 派か
10. **`~/.claude/` をプライベート Git リポで管理**するか(Center of Excellence パターン、自分の知的資産化)

