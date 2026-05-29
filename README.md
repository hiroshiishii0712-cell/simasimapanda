# H.141 Personal — Claude 個人運用環境

個人利用(家計・資産運用、家族の日常、旅行/レシピ、趣味、学習)向けに最適化された Claude 環境のテンプレート集。

**前提**: Claude Pro/Max 契約、Opus 4.8、Claude Code v2.1.156 以降。Claude.ai チャット + Claude Code on the web + Claude Code CLI(ローカル) の 3 面を統合運用する。

## ディレクトリ構成

```
.
├── README.md              ← このファイル
├── docs/                  ← 戦略文書と実装ガイド
│   ├── ROADMAP.md         ← 全体戦略・段階的ロードマップ(承認済プラン v4)
│   ├── PHASE1.md          ← Foundation 実装手順
│   ├── PHASE2.md          ← Knowledge Layer 実装手順
│   ├── PHASE3.md          ← Agents & Automation 実装手順
│   ├── PHASE4.md          ← 継続メンテ手順
│   └── MAINTENANCE.md     ← 月次/四半期メンテのチェックリスト
├── home-claude/           ← ローカル CLI 環境テンプレ(後で ~/.claude/ にコピー)
│   ├── CLAUDE.md          ← ユーザー記憶(個人プロファイル雛形)
│   ├── settings.json      ← グローバル設定雛形(Hooks/Permissions/Auto mode)
│   ├── agents/            ← サブエージェント定義
│   │   ├── evaluator.md   ← コア:重要出力の独立検証
│   │   ├── researcher.md  ← コア:Web/MCP 検索の専担
│   │   ├── archiver.md    ← コア:Notion/Drive への整形保存
│   │   ├── skeptic.md     ← 任意:Adversarial Review Team(懸念探し)
│   │   ├── architect.md   ← 任意:Adversarial Review Team(構造評価)
│   │   └── minimalist.md  ← 任意:Adversarial Review Team(過剰排除)
│   ├── skills/            ← 自作 Skill(個人ドメイン特化)
│   ├── hooks/             ← セッション/ターン lifecycle フック
│   └── agent-hooks/       ← サブエージェント専用フック
├── .claude/               ← 本リポ専用の Claude 設定(プロジェクトスコープ)
│   ├── settings.json
│   ├── hooks/
│   │   └── session-start.sh
│   └── agents/
└── projects/              ← Claude.ai Projects 用カスタムインストラクション雛形
    ├── finance.md         ← 家計・資産 Project
    ├── family.md          ← 家族・日常 Project
    ├── travel.md          ← 旅行 Project
    ├── cooking.md         ← 料理・レシピ Project
    └── learning.md        ← 趣味・学習 Project
```

## ローカル CLI への展開手順(初回)

```bash
# 1. リポをクローン or pull
cd ~/dev
git clone <this-repo-url> H.141_personal
cd H.141_personal

# 2. home-claude/ の中身を ~/.claude/ に展開(既存ファイルは上書き前にバックアップ)
mkdir -p ~/.claude/agents ~/.claude/skills ~/.claude/hooks ~/.claude/agent-hooks
cp -i home-claude/CLAUDE.md     ~/.claude/CLAUDE.md
cp -i home-claude/settings.json ~/.claude/settings.json
cp -ri home-claude/agents/*     ~/.claude/agents/
cp -ri home-claude/skills/*     ~/.claude/skills/ 2>/dev/null || true
cp -ri home-claude/hooks/*      ~/.claude/hooks/  2>/dev/null || true
cp -ri home-claude/agent-hooks/* ~/.claude/agent-hooks/ 2>/dev/null || true

# 3. CLAUDE.md を実際のプロファイルに編集
$EDITOR ~/.claude/CLAUDE.md

# 4. CLI で確認
claude --version          # v2.1.156 以上であること
claude                    # 起動後、/agents で 3 体が見えるか
```

## Claude.ai Web への展開手順

1. https://claude.ai → Settings → **Profile / Custom Instructions** を開く
2. `home-claude/CLAUDE.md` の核となる ~300 字版を貼り付け(機密は書かない)
3. **Memory** を `ON` にする
4. **Projects** を作成し、`projects/*.md` を各 Project の Custom Instructions に貼り付け

詳細手順は `docs/PHASE1.md` 以降を参照。

## アップデート方針

このリポは「自分の Claude Center of Excellence」として育てる。設定変更は必ず:
1. このリポで変更
2. ローカル `~/.claude/` に再展開
3. commit + push して資産化

設定の劣化や肥大化は四半期に 1 回 `docs/MAINTENANCE.md` のチェックリストで棚卸し。
