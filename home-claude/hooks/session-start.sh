#!/bin/bash
# SessionStart hook — 個人ナレッジを context に注入し環境変数を設定する。
# 標準出力に出した内容は Claude の context に追加される(Claude Code 公式仕様)。

set -euo pipefail

# stdin の JSON は使わないが、消費しないと Claude 側でエラーになる場合がある
cat > /dev/null

# 環境変数として渡したい設定があれば $CLAUDE_ENV_FILE に追記
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  {
    echo "export PERSONAL_TZ='Asia/Tokyo'"
    echo "export PERSONAL_LANG='ja'"
  } >> "$CLAUDE_ENV_FILE"
fi

# Claude にロードしたい補助 context(短く保つ — トークンを消費する)
cat <<'CONTEXT'
[Personal session context]
- TZ: Asia/Tokyo / Language: Japanese (技術用語は英語のまま可)
- 業務メール (@eneco.co.jp) と個人用は分離。混入したら指摘してほしい
- 重要決定は evaluator subagent で独立検証してから提示すること
- Calendar/Gmail への書込は必ずドラフトのみ。送信/作成は手動承認
CONTEXT

exit 0
