# Changelog

All notable changes to this project will be documented here.

---

## [0.6.0] — 2026-09-19

### Changed
- Renamed `yngview.ps1` / `yngview.sh` to `yngv.ps1` / `yngv.sh`; the command is now `yngv`. Script version bumped to 1.1.0. Updated `agents.md` and `README.md`.

---

## [0.5.0] — 2026-09-19

### Added
- `yngview.sh` — macOS/Linux version of `yngview.ps1` (markdown in the browser via pwsh or pandoc, ANSI console fallback, plain text for unknown types).
- `yngshared.sh` — macOS/Linux version of `yngshared.ps1` (`--link`, `--copy`, `--unlink`, `--all`, `--name`, `--force`, `--what-if`), same behavior table and backup rules.
- `.gitattributes` — keeps `*.sh` files LF so shebangs work on macOS/Linux.
- `agents.md`, `bare-repository-git-worktrees-agentic-development.md`, `README.md` — reference the `.sh` scripts alongside the `.ps1` ones.

---

## [0.4.1] — 2026-09-19

### Changed
- `yngview.ps1`, `yngshared.ps1` — header credit is now "Author: Emeterio M. Sumagang Jr." and "Company: yngsoftware (www.yngsoftware.com)", and each script records its own version (1.0.0) and creation date.

---

## [0.4.0] — 2026-09-19

### Added
- `yngshared.ps1` — manages the root `.shared/` folder for worktrees (`-link`, `-copy`, `-unlink`); help made project-neutral with requirements, install and run instructions.
- `agents.md` — new "Shared Private Files (Worktrees)" section.
- `bare-repository-git-worktrees-agentic-development.md` — documents `yngshared.ps1` in the shared-files section, keeping the manual loop for non-Windows.
- `README.md` — structure tree lists `yngshared.ps1`.

---

## [0.3.2] — 2026-09-19

### Changed
- `agents.md` — General Guidelines: when grilling the orchestrator, ask one question at a time.

---

## [0.3.1] — 2026-09-19

### Changed
- Documented creation and population of a root `.shared/` folder for Git worktrees, with shared private files by default and a per-worktree opt out.

---

## [0.3.0] — 2026-09-19

### Changed
- Renamed `Django Project/` to `DJANGO Project template/` for a more descriptive name; updated references in `README.md`.
- `README.md` — structure tree now lists `yngview.ps1`.

---

## [0.2.0] — 2026-09-19

### Added
- `yngview.ps1` — CLI script for viewing files (markdown renders in the browser by default, with a console fallback; unrecognized types show as plain text).
- `agents.md` — new "Viewing Files" section pointing agents at `yngview.ps1`.

---

## [0.1.0] — 2026-09-19

### Changed
- Moved all files out of `Generic/` into the repository root; the root is now the default/general-purpose guide directly, with no wrapper folder.
- `README.md` — restructured to describe the root as the default guide and `Django Project/` as a stack-specific extension of it.

### Removed
- `Generic/` folder (contents moved to root, see above).
