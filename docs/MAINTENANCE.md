# メンテナンスチェックリスト

印刷 / Notion 貼り付け用の簡潔版。詳細は [PHASE4.md](./PHASE4.md) を参照。

---

## 月次(目安 1 時間 / 月初)

- [ ] 重要 Skill / Subagent の eval を 3-5 サンプル実行
- [ ] `/code-review --fix` で Skill / Subagent 定義をクリーンアップ
- [ ] `/simplify` で冗長性削減
- [ ] `/usage` でモデル別 / skill 別コストを確認、想定外コストを修正
- [ ] Output Style が用途に合っているか確認

## 四半期(目安 2 時間 / 期初)

- [ ] `~/.claude/agent-memory/*/MEMORY.md` をレビュー、25KB 超は curate
- [ ] agent-memory に機密混入がないか確認
- [ ] 一般化できる知見を `~/.claude/CLAUDE.md` に昇格
- [ ] 3 ヶ月未使用 Skill / Subagent は disable → prune
- [ ] Skill marketplace を巡回、新作を 2-3 個試す
- [ ] permissions.allow / ask / deny を実績で見直し
- [ ] Routine の発火頻度と価値を見直し

## 半年(目安 1 日 / 5 月, 11 月)

- [ ] `/team-onboarding` で `ONBOARDING.md` を再生成
- [ ] このリポの `home-claude/` と実環境 `~/.claude/` を同期
- [ ] `docs/ROADMAP.md` を最新状況に書き換え
- [ ] `projects/*.md` を実際の Claude.ai Project Custom Instructions と同期
- [ ] 年次資産レビュー / 重要契約書を `/ultrareview` で最終チェック

## 年次(目安 1-2 日 / 12 月 or 1 月)

- [ ] モデル世代交代の確認、`~/.claude/CLAUDE.md` の更新
- [ ] 新機能(Dreaming, MCP tunnels, Agent Teams など)の導入判断
- [ ] Claude.ai Memory の内容を全数確認、機密削除
- [ ] Project Knowledge の古い資料を削除
- [ ] `git tag v<year>-personal` でロールバック保険

---

## 異常時の対応

### Auto mode が暴走した
1. `/auto-mode disable` で即停止
2. `~/.claude/sessions/` の最新 session log を確認
3. permissions.deny に該当パターンを追加
4. 段階的に再開

### Subagent が delegate されない
- `/agents` で description を確認
- `PROACTIVELY` / `MUST BE USED` キーワードが入っているか
- main の permissions.allow に `Agent(name)` が入っているか
- description に**具体的トリガーフレーズ**(「家計について」等)が入っているか

### MEMORY.md が肥大化(>25KB)
- 重複行を統合
- 古い学習で陳腐化したものを削除
- ドメイン別にセクション分割

### `/usage` でコスト超過
- 並列度の高い Dynamic Workflows / `/deep-research` を点検
- 主要 subagent の model を Opus → Sonnet に落とせないか検討
- effort を `xhigh` → `high` または `medium` に下げる

### Claude.ai Memory に機密が紛れた
1. Settings → Personalization → Memory → 該当エントリを削除
2. 同じ会話を新規 Project に分離し、Project の Custom Instructions に「機密は記録しない」を追加
3. 再発防止: 入力前に CLAUDE.md の「禁止事項」セクションを更新
