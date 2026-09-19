# agentic-onboarding

Central repository of AI agent onboarding guides and templates for Yng's projects. Any agent (Claude Code, or otherwise) starting work on a project should read the relevant guide here first.

## Structure

```
agentic-onboarding/
├── agents.md                 ← default global onboarding guide (agent-agnostic)
├── claude.md                 ← entry point for Claude, links to agents.md
├── context.md                ← per-project context template
├── bare-repository-git-worktrees-agentic-development.md
│                              ← multi-agent Git worktree pattern, referenced by agents.md
├── CHANGELOG.md               ← history of changes to the default guide
├── VERSION                    ← current version number, kept in sync with CHANGELOG.md
├── yngview.ps1                ← CLI file viewer (markdown in browser, plain text otherwise)
├── yngshared.ps1              ← links/copies shared private files (.shared\) into git worktrees
└── DJANGO Project template/   ← stack-specific extension, used for Django projects
    ├── agents.md               ← Django-specific guide, extends the default agents.md
    ├── CHANGELOG.md            ← history of changes to the Django-specific guide
    └── projects/
        └── template/
            └── agents.md       ← per-project template, links back to the default guide
```

## Usage

The root of this repo is the **default guide** — general-purpose, agent-agnostic, and stack-agnostic. Stack-specific folders (e.g. `DJANGO Project template/`) extend it with rules for that stack; use one when it matches the project, otherwise use the default guide directly.

### Default

1. Read `agents.md` before starting any work; it links to `context.md`.
2. For a new project, copy `context.md` into the project root and fill in the project-specific sections.
3. When the default guide changes, record the change in `CHANGELOG.md` and bump `VERSION`.

### DJANGO Project template

1. Read `DJANGO Project template/agents.md` before starting any work on a Django project; it extends the default `agents.md` with Django-specific rules.
2. For a new project, copy `DJANGO Project template/projects/template/agents.md` into the project root and fill in the project-specific sections. It links back to the default guide so project rules layer on top of, rather than replace, the global ones.
3. When the Django-specific guide changes, record the change in `DJANGO Project template/CHANGELOG.md`.

## Core rules (see each guide for full detail)

- "Plan mode" means plan only — do not execute until told to execute the plan.
- Never add an agent as a co-author on commits.
- Code comments and documentation are mandatory.
- Development is specs-driven — specs are updated before/alongside code changes.
