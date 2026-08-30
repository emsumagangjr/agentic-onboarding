# [Project Name] — Agent Guide

> Project-specific context for agents working on this project.
> Read the global guide first: [f:\MyAgents\agents.md](../../agents.md)

---

## 1. Project Context & Goals

**Project path on disk:** `<absolute path to project>`

**What this project is:**
_Describe the project purpose in 2-3 sentences._

**Current status:**
_Active development / Maintenance / On hold_

**Key goals:**
- _Goal 1_
- _Goal 2_

---

## 2. Agent Roles

| Agent | Responsibility |
|---|---|
| Plan | _What planning looks like for this project_ |
| Execute | _What execution involves — stack, patterns to follow_ |
| Review | _What to check — performance, security, UX, style_ |
| Verify | _How to run and test this project locally_ |

---

## 3. Custom Instructions

_List any rules, constraints, or overrides specific to this project that differ from the global guide._

- **Do:** _e.g., always use the existing `BaseView` class for new Django views_
- **Don't:** _e.g., do not modify the legacy `reports/` module without explicit instruction_
- **Stack notes:** _e.g., uses Django REST Framework, Celery for async tasks_

---

## 4. File & Folder Map

```
<project-root>/
├── <key folder>       ← description
├── <key folder>       ← description
├── <key file>         ← description
└── <key file>         ← description
```

**Entry points:**
- Run server: `_command_`
- Run tests: `_command_`
- Install dependencies: `_command_`

**Important files:**
| File | Purpose |
|---|---|
| `path/to/file` | _What it does_ |
| `path/to/file` | _What it does_ |
