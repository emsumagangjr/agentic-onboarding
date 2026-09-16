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

---

## Recommended Repository Framework

For projects involving multiple concurrent AI agents (e.g., an Epic with several independently implementable tasks), use the **Bare Repository + Git Worktrees Pattern**:

> **One Epic → one Epic branch → multiple task branches → multiple worktrees → multiple agents**

This gives each agent an isolated worktree and branch, keeps `main` protected from direct feature changes, and enforces a controlled promotion path: **Agent → Task Branch → Epic Branch → Main**.

See [bare-repository-git-worktrees-agentic-development.md](bare-repository-git-worktrees-agentic-development.md) for full setup steps, branching rules, and agent safety guidelines.

---

## Next

Read [context.md](context.md) for the project-specific context this guide applies to.
