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

Pick the guide that matches the project: `Generic/` for general-purpose onboarding, `Django Project/` for Django-related projects.

### Generic

1. Read `Generic/agents.md` before starting any work; it links to `Generic/context.md`.
2. For a new project, copy `Generic/context.md` into the project root and fill in the project-specific sections.
3. When the global guide changes, record the change in `Generic/CHANGELOG.md` and bump `Generic/VERSION`.

### Django Project

1. Read `Django Project/agents.md` before starting any work on a Django project.
2. For a new project, copy `Django Project/projects/template/agents.md` into the project root and fill in the project-specific sections. It links back to the global guide so project rules layer on top of, rather than replace, the global ones.
3. When the global guide changes, record the change in `Django Project/CHANGELOG.md`.

## Core rules (see each guide for full detail)

- "Plan mode" means plan only — do not execute until told to execute the plan.
- Never add an agent as a co-author on commits.
- Code comments and documentation are mandatory.
- Development is specs-driven — specs are updated before/alongside code changes.
