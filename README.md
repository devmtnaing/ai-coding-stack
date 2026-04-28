# ai-coding-stack

My opinionated boilerplate for AI-assisted **web development**. Distributes a Claude Code plugin (skills) and a shared `CLAUDE.base.md` into every project.

Nothing here is original — it curates skills and practices from other people's public repos ([Matt Pocock's skills](https://github.com/mattpocock/skills), [Andrej Karpathy–style guidelines](https://github.com/forrestchang/andrej-karpathy-skills), and others added over time). This repo's job is to vendor, version, and re-distribute them through one consistent install flow. Credit goes to the upstream authors; see `skills-lock.json` and `upstream.json` for sources.

## Use it in a project

One-time setup per machine — add the upstream marketplaces this stack depends on:

```
/plugin marketplace add upstash/context7
/plugin marketplace add devmtnaing/ai-coding-stack
```

Per project:

```
/plugin install ai-coding-stack@ai-coding-stack
```

Installs the curated skills plus any bundled plugins declared as dependencies (currently `context7-plugin`, auto-installed).

```bash
curl -fsSL https://raw.githubusercontent.com/devmtnaing/ai-coding-stack/main/bin/sync-base.sh | bash
```

Then add this line near the top of the project's `CLAUDE.md` (or copy `examples/CLAUDE.md` if there isn't one yet):

```
@CLAUDE.base.md
```

Update later:

- **Skills** — auto-refresh at Claude Code startup, or `/plugin marketplace update` && `/plugin update`.
- **`CLAUDE.base.md`** — re-run the `sync-base.sh` curl above.

## Maintain this repo

Add a skill:

```bash
npx skills add <owner>/<repo> --skill <skill-name>
```

Add a vendored non-skill file: append to `upstream.json` (set `sha256: ""`), then run `bin/upstream-pull.sh` — it backfills the hash.

Sync from upstream sources (skills + vendored files):

```bash
bin/sync-upstream.sh           # pull and update
bin/sync-upstream.sh --check   # dry-run
```

`.github/workflows/sync-upstream.yml` runs the same script every Monday and opens a PR if anything drifted.

Validate before pushing: `claude plugin validate .`
