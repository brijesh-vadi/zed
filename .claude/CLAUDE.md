# Fork context

This repo is a personal fork of Zed (`origin` = the fork, `upstream` = zed-industries/zed). The owner builds and runs their own `Zed.app` from it and periodically merges upstream to stay current.

Before syncing with upstream, building, or touching git panel code, read `AGENT-FORK-NOTES.md` in the repo root. It lists the fork's customizations, the merge-conflict playbook, build prerequisites and `./rebuild-app.sh`. `FORK-SYNC-GUIDE.md` is outdated.

Shell gotchas for agents:
- `cargo` may not be on `PATH` in the agent shell: prefix commands with `export PATH="$HOME/.cargo/bin:$PATH"`.
- `ls` is aliased to `eza` in the owner's shell and can hang in non-interactive commands; use `\ls` or `command ls`.
