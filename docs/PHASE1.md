# Phase 1 — Foundation: アイデンティティと記憶

**目標**: どの利用面でも一貫した"自分像"を Claude に持たせる。

**所要時間**: 1-2 時間(分散して 1 週間)

**前提**:
- Claude Code CLI v2.1.156 以上
- Claude Pro/Max 契約

## 1-A. ユーザー記憶ファイル(CLI 共通)

ローカルマシンで:

```bash
# バックアップ
[[ -f ~/.claude/CLAUDE.md ]] && cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak.$(date +%Y%m%d)

# 雛形をコピー
cp home-claude/CLAUDE.md ~/.claude/CLAUDE.md

# 編集 — 自分用に書き換える
$EDITOR ~/.claude/CLAUDE.md
```

**書く時の注意**:
- 500 トークン以内(全セッションで消費される)
- 「最終更新: YYYY-MM」を必ず入れる(temporal context)
- 機密情報は絶対書かない(口座番号、特定金額、家族の氏名・生年月日)

## 1-B. Claude.ai Web の Custom Instructions

1. https://claude.ai → 右上アバター → **Settings → Profile**
2. **Custom Instructions** に `~/.claude/CLAUDE.md` の核を 300 字程度に圧縮して貼る
   - 言語(日本語優先)
   - 出力スタイル(簡潔・直接)
   - 価値観(中長期視点・データ重視)
   - 業務と個人の分離方針
3. **Memory** を `ON`
4. **Settings → Personalization** で名前・呼び方を設定(任意)

## 1-C. settings.json の更新(CLI)

```bash
# バックアップ
cp ~/.claude/settings.json ~/.claude/settings.json.bak.$(date +%Y%m%d)

# 雛形をコピー
cp home-claude/settings.json ~/.claude/settings.json
```

**変更ポイント(雛形に対して)**:
- `permissions.allow` に Read 系を素通し
- `permissions.ask` に Gmail/Calendar 書き込みと file delete
- `permissions.deny` に危険な rm を明示遮断
- `hooks.SessionStart` を有効化(個人 context 注入)
- `hooks.PreCompact` でバックアップ(async)
- `hooks.Stop` で既存の未push検知を継続

**注意**: 既存の `~/.claude/stop-hook-git-check.sh` を上書きしないこと(雛形は参照のみ)。

## 1-D. Hook スクリプトの配置

```bash
mkdir -p ~/.claude/hooks
cp home-claude/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

## 1-E. Auto Mode の有効化

CLI 起動後:
```
/auto-mode enable
```

または settings.json に直接設定する場合は Claude Code のバージョンに応じた `autoMode` キーを参照(現在は分類器が暗黙に動作)。

**注意**: 初月は危険操作のみブロック設定にし、誤動作ゼロを確認してから permissions.allow を拡大する。

## 1-F. Output Style の確認

```
/output-style
```

- 通常運用: **Default**
- 未知ドメイン学習: **Explanatory** に一時切替
- プログラミング学習: **Learning**
- 必要なら `/output-style:new` で `family-explain` カスタム作成

## 1-G. Mobile Push 通知

Claude モバイルアプリ(iOS / Android)をインストールし、同じアカウントでログイン。長尺タスクや Routine 完了時にプッシュ通知が届く。

## 検証

```bash
claude --version            # v2.1.156 以上
claude                      # 起動
> /memory                   # CLAUDE.md が読まれているか
> /effort                   # 既定が high か(Opus 4.8 で)
> /model                    # Opus 4.8 が選ばれているか
> 今の私のプロファイルを 3 行で要約して
                            # 日本語、簡潔、個人プロファイルに沿った応答が返るか
```

Claude.ai Web で:
- 新規チャットを始め、名前や言語を尋ねずに反映されているか確認
- 任意の Project を作成し、`projects/<name>.md` のいずれかを Custom Instructions に貼って動作確認

## 次のステップ

→ [PHASE2.md](./PHASE2.md): Knowledge Layer(Projects と Skills)
