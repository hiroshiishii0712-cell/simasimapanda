#!/bin/bash
# PreCompact hook — context 圧縮前に transcript をバックアップする。
# async モードでバックグラウンド実行し、圧縮処理をブロックしない。

set -euo pipefail

# async モードを宣言(最初に JSON を出力)
echo '{"async": true, "asyncTimeout": 60000}'

# stdin の JSON から transcript_path を取得
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  exit 0
fi

BACKUP_DIR="$HOME/.claude/backups/transcripts"
mkdir -p "$BACKUP_DIR"

TS=$(date +%Y%m%d-%H%M%S)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' | tr -c 'A-Za-z0-9-' '_')
BASENAME="${TS}_${SESSION_ID}.jsonl"

# 安価で堅牢: 単純コピー(ハードリンクは jsonl が後から伸びる時に意図がブレるため避ける)
cp -p "$TRANSCRIPT" "$BACKUP_DIR/$BASENAME" 2>/dev/null || true

# 30 日より古いバックアップは掃除(無制限肥大化を防ぐ)
find "$BACKUP_DIR" -type f -name '*.jsonl' -mtime +30 -delete 2>/dev/null || true

exit 0
