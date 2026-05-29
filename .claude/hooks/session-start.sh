#!/bin/bash
# SessionStart hook (project-scoped) — このリポを Claude Code on the web で開いた時に走る。
# リポ自体の用途(個人 Claude 環境テンプレ集)を Claude に伝える。

set -euo pipefail

# stdin の JSON を消費(使わなくても流す)
cat > /dev/null

# Claude の context に追加される
cat <<'CONTEXT'
[H.141_personal repo context]
このリポは個人の Claude 運用環境テンプレ集(Center of Excellence パターン)。
- README.md がエントリーポイント
- docs/ROADMAP.md が承認済の戦略プラン(v4)
- home-claude/ をローカルマシンの ~/.claude/ にコピーして展開する想定
- projects/ は Claude.ai Web の Project Custom Instructions の雛形
- .claude/ は本リポ専用(プロジェクトスコープ)設定
編集時の注意:
- 機密情報は絶対にコミットしない
- home-claude/CLAUDE.md と projects/*.md の「メモリに残してはいけない情報」セクションを遵守
- 構造変更が大きい場合は README.md と docs/ROADMAP.md も同期更新
CONTEXT

exit 0
