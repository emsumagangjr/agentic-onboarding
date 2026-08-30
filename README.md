# agentic-onboarding

Central repository of AI agent onboarding guides and templates for Yng's projects. Any agent (Claude Code, or otherwise) starting work on a project should read the relevant guide here first.

## Structure

```
agentic-onboarding/
├── Django Project/          ← agentic guide and files for Django-related projects
│   ├── agents.md             ← global onboarding guide (agent-agnostic)
│   ├── CHANGELOG.md          ← history of changes to the guide
│   └── projects/
│       └── template/
│           └── agents.md     ← per-project template, references the global guide
└── Generic/                  ← default/standard agent guide, used when no stack-specific guide applies
    ├── claude.md              ← entry point for Claude, links to agents.md
    ├── agents.md              ← global onboarding guide (agent-agnostic), links to context.md
    ├── context.md             ← per-project context template
    ├── CHANGELOG.md           ← history of changes to the guide
    └── VERSION                ← current version number, kept in sync with CHANGELOG.md
```

## Usage

1. Read the global guide for the relevant stack (e.g. `Django Project/agents.md`) before starting any work.
2. For a new project, copy `projects/template/agents.md` into the project root and fill in the project-specific sections. It links back to the global guide so project rules layer on top of, rather than replace, the global ones.
3. When the global guide changes, record the change in that stack's `CHANGELOG.md`.

## Core rules (see each guide for full detail)

- "Plan mode" means plan only — do not execute until told to execute the plan.
- Never add an agent as a co-author on commits.
- Code comments and documentation are mandatory.
- Development is specs-driven — specs are updated before/alongside code changes.
