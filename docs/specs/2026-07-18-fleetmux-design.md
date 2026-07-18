# fleetmux — tmux-native AI agent orchestrator (design)

Date: 2026-07-18
Status: approved

## Vision

Elevate tmux-session-kit into **fleetmux**: a tmux-native dashboard for a fleet
of AI coding agents. Inspired by stablyai/orca, but implemented entirely in
bash + tmux + fzf: no Electron, no daemon, no wrapper around the agent CLI.

## Identity

- Repo name: `fleetmux` (renamed from `tmux-session-kit`; GitHub redirects old URLs)
- Tagline: "A tmux-native dashboard for your fleet of AI coding agents"
- Existing commands keep their names: `ts` / `tmux-sessions`, `dev-launcher`
- New command: `fleetmux-hook`
- Config: `~/.config/fleetmux/` (migrated from `~/.config/tmux-session-kit/`)
- State:  `~/.local/state/fleetmux/agents/`

## Core architecture: agent state protocol

One state file per tmux session, written by agents (or anything else):

```
~/.local/state/fleetmux/agents/<session>.state
{"session":"api","agent":"claude","status":"working","detail":"...","ts":1789...}
```

- `status`: `working` | `waiting` | `attention` | `done`
- `fleetmux-hook <status> [detail]` resolves its own tmux session via
  `$TMUX_PANE` and writes the file. Any CLI agent can integrate by calling it.
- Claude Code integration (official, installed on consent by install.sh into
  `~/.claude/settings.json` hooks):
  - `UserPromptSubmit` → working
  - `Notification`     → attention (permission prompts etc.)
  - `Stop`             → waiting (turn ended, waiting for user)
- Hooks must never break the agent: every hook command ends with `|| true`
  and is expected to run in <1s.
- Stale state (file for a session that no longer exists) is cleaned up by the
  dashboard when it lists sessions.

## Dashboard (integrated into ts)

```
● api-server   3w  claude:attention  needs permission   <- yellow, sorted first
● factory      1w  claude:working    editing files      <- green
  frontend     2w  -                 15m ago
```

- Sort: attention → working → rest by recent activity.
- fzf matches on session name only (`--nth`), tab-separated columns.
- Preview: window list + agent detail + active pane capture.
- Zero overhead when no state files exist (plain list, same as today).

## Feature roadmap (phases)

### Phase 0 — identity & repo hygiene
- Rename repo to fleetmux; update all references, migrate config dir and
  tmux.conf marker block names.
- GitHub Actions CI: `bash -n` + shellcheck on push/PR.
- `ts --version` / `--help`.

### Phase 1 — picker UX core
- Kill/rename inside fzf via `--bind execute(...)+reload(...)`:
  no full-screen flicker, list refreshes in place.
- Rich list columns: name, window count, last-activity, attached marker.
- Preview shows window list above the pane capture.
- `ts -`: toggle to the previously used session.

### Phase 2 — orchestrator MVP
- State protocol + `fleetmux-hook`.
- install.sh offers Claude Code hook setup (idempotent JSON merge, consent
  prompt, uses python3 for JSON editing).
- Dashboard badges + status sorting + agent detail in preview.

### Phase 3 — creation power
- Session presets: `~/.config/fleetmux/presets/<name>.conf` declaring root
  dir, windows, and commands; picker offers presets when creating.
- Directory sessionizer: Ctrl-F lists project dirs (zoxide if present,
  else configured search paths); picking one creates/attaches a session.
- dev-launcher custom menu entries from `~/.config/fleetmux/launcher.conf`
  (`icon|label|command` lines appended to the built-in menu).

## Error handling

- All scripts `set -euo pipefail`; fzf abort (130) exits cleanly.
- Hook writer fails silently; dashboard treats unreadable/corrupt state files
  as "no agent".
- Old-name config/markers migrated once by install.sh, then ignored.

## Testing

- CI: shellcheck + bash -n on every push/PR.
- Manual smoke tests on an isolated tmux server (`tmux -L test`).
- i18n: all new user-visible strings exist in en + ko.
