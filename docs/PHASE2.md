# Phase 2 — Knowledge Layer: ドメイン別 Projects と Skills

**目標**: 「相談する場所」と「繰り返し業務の手順」を再利用可能化。

**所要時間**: 1 週間(平日 30 分 × 数日 + 週末)

**前提**: Phase 1 完了。

## 2-A. Claude.ai Projects(MECE で 5 + 1 構成)

| Project 名 | Custom Instructions ファイル | 説明 |
|---|---|---|
| 家計・資産 | `projects/finance.md` | 月次棚卸し、配分レビュー |
| 家族・日常 | `projects/family.md` | 行事、To-Do、買い物 |
| 旅行 | `projects/travel.md` | プランニング |
| 料理・レシピ | `projects/cooking.md` | 献立、レシピ整理 |
| 趣味・学習 | `projects/learning.md` | 興味分野の深堀り |
| (汎用 Inbox) | (なし) | 未分類の雑談 |

**作成手順**(Claude.ai Web で):
1. 左サイドバー → **Projects** → **+ Create Project**
2. Project 名を入力(上記表の通り、または自分流に)
3. **Custom Instructions** に対応する `projects/<name>.md` の内容を貼る
4. **Project Knowledge** に必要なら参考資料(機密でないもの)をアップロード

**MECE 原則**:
- 同じ内容を 2 つの Project に置かない
- 「ここに該当しない」場合は汎用 Inbox に投げ、後で適切な Project に移動

## 2-B. Skill marketplace から導入(まず漁る)

CLI で:
```bash
/plugin marketplace add anthropics/skills
```

**候補 Skill**(個人利用で評価高い):
- `temporal-reasoning-sleuth` — 時系列推論強化
- `humanize-writing` — Claude らしさを抑えた自然文章
- `code-reviewer` — 自作 Skill のレビュー
- `changelog-generator` — 自分の使い方変化のログ化

インストール:
```bash
/plugin install <plugin-name>
```

**評価フロー**:
1. 1 週間使ってみる
2. ROI が見えなかったら `claude plugin disable <name>`
3. 月末に `claude plugin prune` で孤立依存を掃除

**参考**:
- 公式リポ: https://github.com/anthropics/skills
- 大型コレクション例: `Anthropic-Cybersecurity-Skills`(構造化 Skill の参考)

## 2-C. 自作 Skill(本当に固有なもののみ)

`~/.claude/skills/<name>/SKILL.md` 形式。各 30-50 行。

**作るべき Skill 候補**(必要に応じて):

### `monthly-budget-report`
- 用途: Drive/CSV から家計データを読み Markdown レポート出力
- 必要 MCP: `googledrive`
- `disallowed-tools`: WebSearch, WebFetch(集中させる)

### `recipe-organizer`
- 用途: 雑多なレシピメモを構造化 Markdown に整形
- 必要 MCP: なし(ローカルファイル中心)

### `travel-itinerary`
- 用途: Calendar と組み合わせて行程草案
- 必要 MCP: `googlecalendar`

### `weekly-digest`
- 用途: Calendar/Gmail/Notion を横断する週次サマリ
- 必要 MCP: `googlecalendar`, `gmail`, `notion`

**Skill 作成補助**:
```
/agents
> Library タブ → Create new skill → Generate with Claude
```

`skill-creator` plugin があれば対話的に作成できる。

**作成時の鉄則**(2026 ベストプラクティス):
- **「するべきこと」を書き、「なぜ」「どう」を語らない**
- 例示を入れる(input → expected output)
- `disallowed-tools` で副作用ツールを明示遮断
- description で**いつ使うか**を明確に(Claude が自動 trigger するかが決まる)

## 2-D. (オプション)Obsidian vault 連携

Notion をマスターにする場合は **不要**。両方持つと MECE 違反。

採用する場合:
- 新規 vault を作成(既存に書き込み権限を与えない)
- PARA 構造: `00-Inbox/`, `01-Projects/`, `02-Areas/`, `03-Resources/`, `04-Archive/`, `Decisions/`, `Templates/`
- obsidian-MCP-server をインストール
- Claude Code の `mcpServers` に追加

## 検証

CLI で:
```
/plugin list           # marketplace 経由の skill が見える
> /<skill-name>        # 直接呼び出して動作確認
```

Claude.ai Web で:
- 「家計について」と各 Project で聞き、Project 固有の Custom Instructions に沿った応答が返るか
- 汎用 Inbox で聞いた時は中立的応答が返るか

## 次のステップ

→ [PHASE3.md](./PHASE3.md): Agents & Automation(エージェント運用の本格構築)
