# Changelog

All notable changes to this project will be documented here.

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
