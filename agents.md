# Yng's Agent Onboarding Guide

> **Agent-agnostic.** Applies to any AI agent, platform, or framework — software development, research, writing, analysis, or any other agentic task. Read in full before starting any work.

---

## The Orchestrator

You are working with a **Solutions Architect** who:

- Builds meaningful solutions that improve lives
- Challenges the status quo — better always beats conventional
- Demands **simple and practical** over clever and complex
- Treats **UX as paramount and non-negotiable** — every user-facing output must be intuitive
- Maintains a high standard of engineering excellence

---

## General Guidelines
- When the orchestrator says **"plan mode"**, plan only — do not execute until **"execute plan"** is explicitly instructed
- Never auto-add your agent name as a co-author
- Code comments and documentation are mandatory
- Before committing, always update the changelog, version, and specs where applicable
- **Always ask permission before reading or writing to the repository by default** — this applies to every repository action (file reads, edits, commits, pushes, etc.) unless the orchestrator has explicitly specified to allow it all the time
- When **grilling** the orchestrator (asking probing questions about a plan, decision, or idea), ask **one question at a time** — wait for the answer before asking the next

---

## Recommended Repository Framework

For projects involving multiple concurrent AI agents (e.g., an Epic with several independently implementable tasks), use the **Bare Repository + Git Worktrees Pattern**:

> **One Epic → one Epic branch → multiple task branches → multiple worktrees → multiple agents**

This gives each agent an isolated worktree and branch, keeps `main` protected from direct feature changes, and enforces a controlled promotion path: **Agent → Task Branch → Epic Branch → Main**.

See [bare-repository-git-worktrees-agentic-development.md](bare-repository-git-worktrees-agentic-development.md) for full setup steps, branching rules, and agent safety guidelines.

---

## Viewing Files

Use [yngview.ps1](yngview.ps1) to view files from the CLI instead of dumping raw text. It detects the file extension and renders accordingly — markdown opens rendered in the browser by default (falling back to a styled console view), and any unrecognized file type is shown as plain text. See the script's own comment-based help (`Get-Help ./yngview.ps1 -Full`) for requirements, install steps, and usage.

---

## Shared Private Files (Worktrees)

In a bare-repository + worktrees project, private untracked files (`.env`, `secrets/`, `config/`, …) live once in a root `.shared/` folder and are linked into each worktree — never committed, never copied by hand. On Windows, use [yngshared.ps1](yngshared.ps1), placed in the project root beside `.bare/` and `.shared/`:

- `-link <worktree>…` or `-link -All` — symlink shared items into worktrees
- `-copy <worktree> -Name <item>` — give a worktree its own independent copy (opt out of sharing)
- `-unlink <worktree>` — turn links back into real copies
- Always preview with `-WhatIf` first; without `-Force` it never overwrites a real file, and `-Force` backs up whatever it replaces

Never edit or delete `.shared/` items casually — a change there affects every worktree that follows the link. See the script's help (`Get-Help .\yngshared.ps1 -Full`) and [bare-repository-git-worktrees-agentic-development.md](bare-repository-git-worktrees-agentic-development.md) for details.

---

## Next

Read [context.md](context.md) for the project-specific context this guide applies to.
