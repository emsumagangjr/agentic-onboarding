# Bare Repository + Git Worktrees for Agentic Development

## Purpose

This guide documents a Git workspace and integration pattern for
**agentic software development**, particularly when an Epic contains
multiple tasks that can be implemented concurrently by multiple AI
coding agents.

The conceptual principle is:

> **One Epic → one branch → multiple worktrees → multiple agents**

Because Git normally prevents the same branch from being checked out in
multiple worktrees simultaneously, the practical implementation is:

> **One Epic → one Epic branch → multiple task branches → multiple
> worktrees → multiple agents**

Each task branch is derived from the Epic branch. Each task branch
receives an isolated worktree and agent. Completed tasks are integrated
back into the Epic branch.

The protected `main` branch receives feature changes **only by merging
completed Epic branches**.

The complete promotion path is:

> **Agent → Task Branch → Epic Branch → Main**

------------------------------------------------------------------------

## 1. Architecture Overview

A conventional Git clone combines the Git repository metadata and a
single working directory:

``` text
myproject/
├── .git/
├── src/
├── README.md
└── ...
```

With the **Bare Repository + Git Worktrees Pattern**, Git metadata is
centralized while active branches receive separate working directories:

``` text
myproject/
│
├── .bare/                       # shared Git repository
├── .shared/                     # local, untracked files shared by default
│   ├── .env
│   ├── secrets/
│   └── config/
│
├── main/                        # protected main worktree
│   ├── .env -> ../.shared/.env
│   ├── secrets -> ../.shared/secrets
│   └── config -> ../.shared/config
│
├── epic-auth/                   # Epic integration worktree
│
├── agent-auth-oauth/            # Task worktree → Agent A
│
├── agent-auth-permissions/      # Task worktree → Agent B
│
└── agent-auth-audit/            # Task worktree → Agent C
```

A corresponding branch hierarchy might be:

``` text
main
│
└── epic/AUTH-100-authentication
      │
      ├── task/AUTH-101-oauth
      ├── task/AUTH-102-permissions
      └── task/AUTH-103-audit
```

The `.bare/` repository owns the shared Git history, objects, refs,
configuration, and worktree metadata.

The root `.shared/` directory holds local files that worktrees follow by
default. A worktree can replace an individual link with its own copy.

------------------------------------------------------------------------

## 2. Core Principles

### Epic-level ownership

An Epic represents a significant body of related work and receives its
own integration branch.

``` text
Epic
  ↓
Epic Branch
```

### Parallel task execution

The Epic is decomposed into tasks that can be assigned independently:

``` text
Epic Branch
    │
    ├── Task A
    ├── Task B
    └── Task C
```

Each task receives its own branch, worktree, and agent:

``` text
Epic Branch
    │
    ├── Task Branch → Worktree → Agent A
    ├── Task Branch → Worktree → Agent B
    └── Task Branch → Worktree → Agent C
```

### Main is protected

The `main` branch is not a development workspace.

> **`main` can only receive feature changes by merging a completed Epic
> branch.**

There is deliberately no normal development path from an agent or task
branch directly into `main`.

``` text
Agent ─────────── X ──────────► main

Task Branch ───── X ──────────► main
```

The supported path is:

``` text
Agent
  ↓
Task Branch
  ↓
Epic Branch
  ↓
Integration Testing / Review / CI
  ↓
main
```

------------------------------------------------------------------------

## 3. Why This Works Well for Agentic Programming

AI coding agents commonly need to inspect source code, edit files,
install dependencies, create migrations, run tests, start development
servers, inspect diffs, and commit changes.

Running multiple agents against one working directory creates
unnecessary interference. An agent can change a file while another agent
is reading or testing it.

Worktrees provide filesystem-level separation:

``` text
                         .bare/
                    Shared Git database
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
 agent-auth-oauth/  agent-auth-permissions/ agent-auth-audit/
        │                  │                  │
        ▼                  ▼                  ▼
     Agent A            Agent B            Agent C
```

This provides:

-   concurrent task development;
-   isolated files and Git indexes;
-   less branch switching and stashing;
-   shared Git history without multiple full clones;
-   clear task/agent ownership;
-   easy creation and cleanup of temporary workspaces;
-   parallel builds and tests when runtime resources are also isolated.

------------------------------------------------------------------------

## 4. The Epic as the Integration Boundary

Consider an Epic:

``` text
AUTH-100
Authentication Improvements
```

with tasks:

``` text
AUTH-101    Microsoft OAuth
AUTH-102    Role permissions
AUTH-103    Authentication audit logging
```

The branch model becomes:

``` text
main
  │
  └── epic/AUTH-100-authentication
          │
          ├── task/AUTH-101-oauth
          ├── task/AUTH-102-permissions
          └── task/AUTH-103-audit
```

The agent model becomes:

``` text
                  epic/AUTH-100-authentication
                             │
             ┌───────────────┼───────────────┐
             │               │               │
             ▼               ▼               ▼
        AUTH-101          AUTH-102         AUTH-103
             │               │               │
             ▼               ▼               ▼
       Task Branch       Task Branch      Task Branch
             │               │               │
             ▼               ▼               ▼
         Worktree          Worktree         Worktree
             │               │               │
             ▼               ▼               ▼
          Agent A           Agent B          Agent C
```

Individual task success does not imply that the complete Epic is ready
for `main`. The Epic branch provides a controlled place for integration
testing and conflict resolution.

------------------------------------------------------------------------

## 5. Initial Repository Setup

Assume the remote repository is:

``` text
git@github.com:username/myproject.git
```

Create the project directory and its shared local-files folder:

``` bash
mkdir myproject
cd myproject
mkdir -p .shared/secrets .shared/config
```

Create `.shared/` once, at the project root beside `.bare/`. It is a
local folder outside all worktrees, so Git does not include it in any
branch. Put the private files that worktrees should follow by default
there.

Populate it from an existing checkout or your project's approved local
configuration source. For example, if the old checkout is beside
`myproject/`:

``` bash
cp ../myproject-old/.env .shared/.env
cp -R ../myproject-old/secrets/. .shared/secrets/
cp -R ../myproject-old/config/. .shared/config/
```

Run only the copy commands for paths your project actually has. For a
new project, create `.shared/.env` from its provided example file and
enter the local values; populate `secrets/` and `config/` in the same
way if needed. Do not put real credentials in a tracked example file.
Populate each item before linking it into worktrees. Later edits to a
shared item appear in every worktree that still follows its link.

Clone the remote as a bare repository:

``` bash
git clone --bare git@github.com:username/myproject.git .bare
```

Configure normal remote-tracking branch fetching:

``` bash
git --git-dir=.bare config remote.origin.fetch \
    "+refs/heads/*:refs/remotes/origin/*"

git --git-dir=.bare fetch origin
```

The initial structure, before creating any worktrees, is:

``` text
myproject/
├── .bare/
└── .shared/
    ├── .env                     # add your local values
    ├── secrets/
    └── config/
```

Keep `.shared/` outside every worktree and out of version control. Give
it access permissions appropriate for the secrets it contains; do not
commit or push those files.

------------------------------------------------------------------------

## 6. Create the Main Worktree

If the primary branch is `main`:

``` bash
git --git-dir=.bare worktree add main main
```

Result:

``` text
myproject/
├── .bare/
├── .shared/
└── main/
```

The `main/` worktree should remain clean and protected from normal
feature development.

Repository branch protection should also reject direct pushes to `main`
where possible.

------------------------------------------------------------------------

## 7. Create an Epic Branch and Worktree

For:

``` text
Epic: AUTH-100
Authentication Improvements
```

create an Epic branch from `main`:

``` bash
git --git-dir=.bare worktree add \
    -b epic/AUTH-100-authentication \
    epic-auth \
    main
```

Result:

``` text
myproject/
├── .bare/
├── main/
└── epic-auth/
```

The Epic worktree is the integration workspace for all tasks belonging
to the Epic.

------------------------------------------------------------------------

## 8. Create Task Worktrees for Multiple Agents

Create Agent A's task:

``` bash
git --git-dir=.bare worktree add \
    -b task/AUTH-101-oauth \
    agent-auth-oauth \
    epic/AUTH-100-authentication
```

Create Agent B's task:

``` bash
git --git-dir=.bare worktree add \
    -b task/AUTH-102-permissions \
    agent-auth-permissions \
    epic/AUTH-100-authentication
```

Create Agent C's task:

``` bash
git --git-dir=.bare worktree add \
    -b task/AUTH-103-audit \
    agent-auth-audit \
    epic/AUTH-100-authentication
```

Result:

``` text
myproject/
├── .bare/
├── main/
├── epic-auth/
├── agent-auth-oauth/
├── agent-auth-permissions/
└── agent-auth-audit/
```

Each agent now has an independent working directory.

------------------------------------------------------------------------

## 9. Git Constraint: Why Task Branches Are Necessary

The conceptual model is:

> **One Epic → one branch → multiple worktrees → multiple agents**

However, Git normally prevents one branch from being checked out in
several worktrees simultaneously.

Therefore, do not attempt:

``` text
agent-a/ → epic/AUTH-100
agent-b/ → epic/AUTH-100
agent-c/ → epic/AUTH-100
```

Instead, derive task branches from the Epic:

``` text
epic/AUTH-100
    │
    ├── task/AUTH-101 → agent-a/
    ├── task/AUTH-102 → agent-b/
    └── task/AUTH-103 → agent-c/
```

This also gives each agent an explicit unit of ownership and a clean
commit history.

------------------------------------------------------------------------

## 10. Agent Task Workflow

An agent works only inside its assigned task worktree.

For example:

``` bash
cd agent-auth-oauth

git status

# Agent edits, builds and tests.

git diff
git add .
git commit -m "AUTH-101 Add Microsoft OAuth"
git push -u origin task/AUTH-101-oauth
```

The task should then follow the project's normal review and validation
process.

Agents should not merge their task branches directly into `main`.

------------------------------------------------------------------------

## 11. Integrating Tasks into the Epic

After AUTH-101 is approved:

``` bash
cd epic-auth
git merge task/AUTH-101-oauth
```

Then integrate the remaining approved tasks:

``` bash
git merge task/AUTH-102-permissions
git merge task/AUTH-103-audit
```

The Epic branch becomes the combined implementation:

``` text
main
  │
  └── epic/AUTH-100
          │
          ├── AUTH-101 ✓
          ├── AUTH-102 ✓
          └── AUTH-103 ✓
```

Task integration may be performed through pull requests instead of local
merges when repository governance requires review or CI before merging.

------------------------------------------------------------------------

## 12. Main Branch Protection and Integration Rule

The `main` branch is the stable integration boundary.

The core rule is:

> **`main` can only be edited through the merge of a completed Epic
> branch.**

Normal feature development must not occur directly in `main`.

The complete flow is:

``` text
Task A ──► Task Branch ──┐
                         │
Task B ──► Task Branch ──┼──► Epic Branch ──► main
                         │
Task C ──► Task Branch ──┘
```

The three levels have distinct responsibilities:

``` text
MAIN
│
│  Stable / protected
│  Epic merges only
│
└── EPIC BRANCH
      │
      │  Integration boundary
      │
      ├── TASK BRANCH → WORKTREE → AGENT A
      ├── TASK BRANCH → WORKTREE → AGENT B
      └── TASK BRANCH → WORKTREE → AGENT C
```

### Rules

1.  Agents never implement features directly on `main`.
2.  Developers do not use `main` as a feature-development workspace.
3.  Every significant body of feature work belongs to an Epic.
4.  Every Epic receives an Epic branch derived from `main`.
5.  Tasks receive task branches derived from the Epic branch.
6.  Each concurrently active task receives its own worktree.
7.  Each worktree is owned by one task/agent at a time.
8.  Completed task branches merge into the Epic branch, not `main`.
9.  Integration testing is performed against the combined Epic branch.
10. Only a completed, reviewed, and validated Epic branch may merge into
    `main`.
11. Repository protection should reject direct pushes to `main`.

This creates a controlled promotion path:

> **Agent → Task Branch → Epic Branch → Main**

------------------------------------------------------------------------

## 13. Completing an Epic

After all required tasks have been integrated:

``` text
task/AUTH-101 ─┐
task/AUTH-102 ─┼──► epic/AUTH-100 ──► main
task/AUTH-103 ─┘
```

Before the Epic is merged into `main`, run the appropriate Epic-level:

-   integration tests;
-   regression tests;
-   code review;
-   security checks;
-   database migration validation;
-   CI pipeline;
-   acceptance checks.

The Epic branch then goes through the repository's normal pull
request/merge process.

This gives two levels of validation:

``` text
Task-level testing
        ↓
Task integration
        ↓
Epic branch
        ↓
Epic-level integration testing
        ↓
Review / CI
        ↓
main
```

------------------------------------------------------------------------

## 14. Multiple Epics Can Run Concurrently

The same model supports several independent Epics:

``` text
                       PROTECTED
                          MAIN
                           ▲
                           │
                     Epic merges
                           │
              ┌────────────┴────────────┐
              │                         │
          EPIC A                     EPIC B
              ▲                         ▲
        ┌─────┼─────┐             ┌─────┼─────┐
        │     │     │             │     │     │
       T1    T2    T3            T1    T2    T3
        ▲     ▲     ▲             ▲     ▲     ▲
        │     │     │             │     │     │
       A1    A2    A3            A4    A5    A6
```

Each Epic acts as an independent integration boundary while `main`
remains protected from partial implementations.

------------------------------------------------------------------------

## 15. Environment Isolation

Git worktrees isolate source files and Git indexes, but they do not
automatically isolate runtime resources.

Each active agent may need independent:

-   `.env` values when its branch opts out of the shared defaults;
-   Python virtual environment;
-   database or database schema;
-   development server port;
-   Docker Compose project;
-   Redis namespace or instance;
-   Celery queue;
-   temporary directories;
-   test artifacts.

For example:

``` text
epic-auth/                 → port 8000
agent-auth-oauth/          → port 8001
agent-auth-permissions/    → port 8002
agent-auth-audit/          → port 8003
```

For Django projects, database migrations require particular care when
several agents create migrations concurrently.

For Docker Compose, assign a unique project name per worktree so
containers, networks, and volumes do not collide.

### Shared private files with a per-worktree opt out

The project root's `.shared/` folder is the default source for local
`.env`, `secrets/`, and `config/`. Link each item into a new worktree
after `git worktree add`.

**On Windows, use `yngshared.ps1`.** Copy [yngshared.ps1](yngshared.ps1)
into the project root beside `.bare/` and `.shared/`, then run it from
there. It handles every item in `.shared/` (not just the three above),
never overwrites real files without `-Force`, and backs up anything it
replaces:

``` powershell
.\yngshared.ps1 -link main epic-auth -WhatIf   # preview
.\yngshared.ps1 -link main epic-auth           # symlink shared items
.\yngshared.ps1 -link -All                     # every worktree
.\yngshared.ps1 -copy agent-auth-oauth -Name .env   # opt out: own .env
.\yngshared.ps1 -unlink agent-auth-oauth       # links -> independent copies
```

Symlinks on Windows need Developer Mode or an elevated shell. Run
`Get-Help .\yngshared.ps1 -Full` for requirements, all switches, and the
exact behavior for each existing-file case.

On macOS/Linux, or to see what the script does, the equivalent manual
loop from `myproject/` is:

``` bash
# Run for each new worktree; replace main with its directory name.
for name in .env secrets config; do
    if [ -e ".shared/$name" ] && [ ! -e "main/$name" ] &&
       [ ! -L "main/$name" ]; then
        ln -s "../.shared/$name" "main/$name"
    fi
done
```

Repeat for `epic-auth` and each task worktree, or put this loop in the
worktree creation script. Existing files are left alone. If a tracked
file already occupies one of these paths, keep it tracked and choose a
different local path for the shared data.

By default, every linked worktree reads the same underlying files. A
change through one link is visible in all linked worktrees. To opt a
branch out for one item, use `yngshared.ps1 -copy <worktree> -Name <item>`
on Windows, or replace that worktree's link with a local copy manually:

``` bash
# From myproject/: give the OAuth task its own .env.
test -L agent-auth-oauth/.env
cp -L agent-auth-oauth/.env agent-auth-oauth/.env.local-copy
unlink agent-auth-oauth/.env
mv agent-auth-oauth/.env.local-copy agent-auth-oauth/.env
```

The OAuth task now has independent `.env` values; its `secrets/` and
`config/` links still follow `.shared/`. The same approach works for a
directory: copy its contents into a temporary directory in that
worktree, unlink the directory link, then rename the temporary directory
to the original name. To opt out when creating a worktree, simply omit
the selected link and create a local file or directory at that path.
Only unlink a path after confirming it is a symbolic link; deleting or
editing the shared target affects every branch that follows it.

Ensure the relevant paths are ignored in every branch's `.gitignore`
or a local Git excludes file. Directory patterns with a trailing slash
do not ignore symbolic links, so use patterns that match both the link
and an independent directory:

``` gitignore
/.env
/secrets
/config
```

Add only entries that are genuinely private and untracked in the
project. For example, do not ignore a tracked application `config/`
directory; share a specific local file within it instead. Verify with
`git status --short` that neither the links nor local copies appear as
untracked files before committing. Each worktree keeps its own
dependencies, build outputs, and runtime resources.

------------------------------------------------------------------------

## 16. Agent Safety Rules

A coding agent operating under this architecture should:

1.  Work only inside its assigned task worktree.
2.  Stay on its assigned task branch unless explicitly instructed
    otherwise.
3.  Treat the Epic branch as an integration branch.
4.  Never modify another agent's worktree.
5.  Never manually modify `.bare/`.
6.  Never implement feature work directly on `main`.
7.  Never merge a task branch directly into `main`.
8.  Check `git status` before starting work.
9.  Inspect `git diff` before committing.
10. Run relevant tests before marking a task complete.
11. Keep commits scoped to the assigned task.
12. Push the task branch for review/integration.
13. Coordinate changes affecting shared architecture, dependencies,
    schemas, or common configuration.
14. Treat databases, ports, containers, queues, and caches as separate
    isolation concerns.
15. Follow the project's existing specifications, agent instructions,
    review requirements, and commit conventions.

------------------------------------------------------------------------

## 17. Integration Conflicts Still Exist

Worktrees eliminate filesystem collisions, but they do not eliminate
normal integration conflicts.

For example, Agent A and Agent B may independently modify:

``` text
settings.py
```

Their workspaces remain isolated while they develop.

However, merging both task branches into the Epic may produce a Git
conflict.

Worktrees solve:

``` text
workspace collision
```

They do not automatically solve:

``` text
merge conflicts
task dependency conflicts
architectural conflicts
database migration conflicts
integration failures
semantic conflicts
```

Good Epic decomposition, task boundaries, interfaces, and communication
remain important.

------------------------------------------------------------------------

## 18. Cleanup

After a task is merged into the Epic:

``` bash
git --git-dir=.bare worktree remove agent-auth-oauth
```

Delete its local task branch when appropriate:

``` bash
git --git-dir=.bare branch -d task/AUTH-101-oauth
```

After the completed Epic is merged into `main`:

``` bash
git --git-dir=.bare worktree remove epic-auth
```

Then remove the local Epic branch:

``` bash
git --git-dir=.bare branch -d epic/AUTH-100-authentication
```

If a worktree directory was manually deleted, prune stale metadata:

``` bash
git --git-dir=.bare worktree prune
```

------------------------------------------------------------------------

## 19. Listing Active Worktrees

Use:

``` bash
git --git-dir=.bare worktree list
```

Example:

``` text
/path/myproject/.bare                    (bare)
/path/myproject/main                     abc1234 [main]
/path/myproject/epic-auth                def5678 [epic/AUTH-100-authentication]
/path/myproject/agent-auth-oauth         123abcd [task/AUTH-101-oauth]
/path/myproject/agent-auth-permissions   456efgh [task/AUTH-102-permissions]
```

This is useful for both developers and agent orchestrators because it
provides a view of active local workspaces and branch ownership.

------------------------------------------------------------------------

## 20. Quick Reference

### Create repository

``` bash
git clone --bare <repository-url> .bare

git --git-dir=.bare config remote.origin.fetch \
    "+refs/heads/*:refs/remotes/origin/*"

git --git-dir=.bare fetch origin
```

### Create main worktree

``` bash
git --git-dir=.bare worktree add main main
```

### Create Epic

``` bash
git --git-dir=.bare worktree add \
    -b epic/AUTH-100-authentication \
    epic-auth \
    main
```

### Create agent task

``` bash
git --git-dir=.bare worktree add \
    -b task/AUTH-101-oauth \
    agent-auth-oauth \
    epic/AUTH-100-authentication
```

### List active worktrees

``` bash
git --git-dir=.bare worktree list
```

### Commit agent work

``` bash
cd agent-auth-oauth

git status
git diff
git add .
git commit -m "AUTH-101 Add Microsoft OAuth"
git push -u origin task/AUTH-101-oauth
```

### Integrate task into Epic

``` bash
cd ../epic-auth
git merge task/AUTH-101-oauth
```

### Remove completed task

``` bash
git --git-dir=.bare worktree remove agent-auth-oauth
git --git-dir=.bare branch -d task/AUTH-101-oauth
```

### Remove completed Epic after merge to main

``` bash
git --git-dir=.bare worktree remove epic-auth
git --git-dir=.bare branch -d epic/AUTH-100-authentication
```

### Prune stale metadata

``` bash
git --git-dir=.bare worktree prune
```

------------------------------------------------------------------------

## Summary

The **Bare Repository + Git Worktrees Pattern** provides a structured
foundation for parallel agentic software development organized around
Epics.

The conceptual principle is:

> **One Epic → one branch → multiple worktrees → multiple agents**

The practical Git implementation is:

> **One Epic → one Epic branch → multiple task branches → multiple
> worktrees → multiple agents**

And the controlled integration path is:

> **Agent → Task Branch → Epic Branch → Main**

`main` is protected and does not serve as a feature-development
workspace. Feature changes reach `main` only through a completed,
reviewed, tested, and validated Epic branch.

``` text
                         MAIN
                    Stable / Protected
                           ▲
                           │
                     Epic merge only
                           │
                    EPIC BRANCH
                 Integration Boundary
                           ▲
              ┌────────────┼────────────┐
              │            │            │
          Task Branch  Task Branch  Task Branch
              ▲            ▲            ▲
              │            │            │
           Worktree      Worktree      Worktree
              ▲            ▲            ▲
              │            │            │
           Agent A       Agent B       Agent C
```

This architecture enables multiple agents to work concurrently while
maintaining filesystem isolation, explicit task ownership, controlled
Epic-level integration, and a clean promotion path into the protected
`main` branch.
