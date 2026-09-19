#!/usr/bin/env bash
#
# yngshared - share private files from .shared/ with git worktrees:
#             --link, --copy or --unlink.
#
#   Name:     yngshared.sh
#   Version:  1.0.0
#   Created:  2026-09-19
#   Author:   Emeterio M. Sumagang Jr.
#   Company:  yngsoftware (www.yngsoftware.com)
#
# macOS / Linux counterpart of yngshared.ps1.
#
# DESCRIPTION
#   Works with any project laid out as a bare repository with one folder per
#   worktree (the "Bare Repository + Git Worktrees" pattern):
#
#       <project-root>/
#       |-- .bare/          shared git database
#       |-- .shared/        private, untracked files (.env, secrets/, ...)
#       |-- main/           worktree
#       |-- <other>/        more worktrees (epic, task, agent, ...)
#       `-- yngshared.sh    <- this script (must sit at the project root)
#
#   Every file or folder directly inside .shared/ is an "item". Choose exactly
#   one action, and the worktree(s) to apply it to:
#
#       --link     Put a relative symbolic link to each item in the worktree.
#                  The worktree follows .shared/: edit the file through any
#                  worktree and every linked worktree sees the change.
#       --copy     Put a real, independent copy of each item in the worktree.
#                  Same result as --link followed by --unlink. Use it when a
#                  worktree needs its own .env values.
#       --unlink   Turn each link into a real copy of the item it pointed to.
#                  Only links into .shared/ are touched; real files are never
#                  changed.
#
#   Nothing inside .shared/ is ever changed, moved or deleted.
#
# REQUIREMENTS
#   - bash 3.2+ (the macOS default is fine) and standard tools: ln, cp, mv,
#     cmp, diff, readlink.
#   - Git on PATH (only needed for --all).
#   - A project root containing .bare/ and .shared/ as shown above.
#
# INSTALL
#   Copy this file into the project root, beside .bare/ and .shared/, and make
#   it executable (chmod +x yngshared.sh). The script treats its own folder as
#   the project root, so it cannot be run from anywhere else.
#
# HOW TO RUN
#   ./yngshared.sh --link main                 link every .shared item into main/
#   ./yngshared.sh --link main epic-auth       several worktrees at once
#   ./yngshared.sh --link --all --what-if      preview every worktree
#   ./yngshared.sh --copy agent-x --name .env  agent-x gets its own .env only
#   ./yngshared.sh --unlink dev                dev's links become real copies
#   ./yngshared.sh --link main dev --force     replace real files (backed up)
#
# OPTIONS
#   --link | --copy | --unlink   the action (exactly one)
#   --all                        every worktree from 'git worktree list'
#   --name a,b                   limit to these items from .shared/
#   --force                      with --link/--copy: also replace a real file or
#                                folder (after a backup) and a link that points
#                                somewhere else. No effect with --unlink.
#   --what-if                    show what would happen, change nothing
#                                (recommended before --copy, --unlink, --force
#                                or --all)
#   -h, --help                   show this help
#
# WHAT HAPPENS TO WHAT IS ALREADY IN THE WORKTREE
#
#     At the path                  --link            --copy            --unlink
#     ---------------------------  ----------------  ----------------  ----------------
#     nothing there                symlink           real copy         skip
#     link into .shared/           keep (already     convert to a      convert to a
#                                  linked)           real copy         real copy
#     real file or folder          keep              keep              keep
#       ...with --force            back up, symlink  back up, copy     keep (no effect)
#     link somewhere else, or      warn and skip     warn and skip     warn and skip
#     broken link
#       ...with --force            replace with a    replace with a    warn and skip
#                                  symlink           copy
#
#   Without --force nothing real is ever overwritten, so a worktree's own .env
#   survives and re-running is always safe. A worktree opts out of sharing
#   simply by having its own real file at that path.
#
# --FORCE AND BACKUPS
#   With --force, a real file or folder that differs from the shared item is
#   first renamed inside the same worktree to
#       <name>.yngshared-bak-<yyyyMMdd-HHmmss>
#   The first time a backup is made, the pattern *.yngshared-bak-* is added to
#   .bare/info/exclude, a local Git file that is never committed and applies to
#   every worktree, so backups (which may contain secrets) can never show up in
#   'git status'. No backup is made when the existing file is identical to the
#   shared one. The script never deletes backups; delete them yourself.
#
# SYMBOLIC LINKS
#   Links are relative (for example ../.shared/.env), so they keep working if
#   the project folder is moved or renamed.
#
# GIT
#   Links and copies must not be committed. Make sure each private name is
#   ignored in every branch's .gitignore (for example /.env). A pattern with a
#   trailing slash does not match a symlink. Afterwards 'git status --short'
#   should not list them.
#
# OUTPUT (one line per item; "would ..." instead when --what-if is used)
#   symlink  created a relative symbolic link      copy   created a real copy
#   backup   renamed an existing real file (force) keep   left alone
#   skip     nothing to do                         warn   refused (a problem)
#   error    something failed (a problem)
#
# EXIT CODE
#   0 = success, 1 = a warning or error occurred, 2 = usage mistake.

set -u

ROOT=$(cd "$(dirname "$0")" && pwd -P)
SHARED="$ROOT/.shared"
STAMP=$(date +%Y%m%d-%H%M%S)
PROBLEMS=0
EXCLUDE_DONE=0

LINK=0; COPY=0; UNLINK=0; ALL=0; FORCE=0; WHATIF=0
NAMES=""
WORKTREES=()

usage() {
    # Print the header comment block (line 2 up to the first non-comment line).
    sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

die_usage() {
    echo "ERROR: $1" >&2
    echo >&2
    usage >&2
    exit 2
}

# --------------------------------------------------------------------------
# Command line
# --------------------------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        --link)    LINK=1 ;;
        --copy)    COPY=1 ;;
        --unlink)  UNLINK=1 ;;
        --all)     ALL=1 ;;
        --force)   FORCE=1 ;;
        --what-if) WHATIF=1 ;;
        --name)
            [ $# -ge 2 ] || die_usage "--name needs a value, e.g. --name .env,secrets"
            NAMES="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        -*)        die_usage "Unknown option: $1" ;;
        *)         WORKTREES+=("$1") ;;
    esac
    shift
done

count=$((LINK + COPY + UNLINK))
[ "$count" -eq 0 ] && die_usage "Choose one action: --link, --copy or --unlink."
[ "$count" -gt 1 ] && die_usage "Choose only one of --link, --copy and --unlink."
if [ "$LINK" -eq 1 ]; then ACTION=link; elif [ "$COPY" -eq 1 ]; then ACTION=copy; else ACTION=unlink; fi

if [ "$ALL" -eq 1 ] && [ ${#WORKTREES[@]} -gt 0 ]; then die_usage "Use either --all or worktree names, not both."; fi
if [ "$ALL" -eq 0 ] && [ ${#WORKTREES[@]} -eq 0 ]; then die_usage "Name at least one worktree, or use --all."; fi

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

report() {   # report STATUS PATH [NOTE]
    local status="$1" path="$2" note="${3:-}" text
    text="$status"
    if [ "$WHATIF" -eq 1 ]; then
        case "$status" in symlink|copy|backup) text="would $status" ;; esac
    fi
    if [ -n "$note" ]; then text="$text  $path  ($note)"; else text="$text  $path"; fi
    case "$status" in
        warn)  printf '\033[33m%s\033[0m\n' "$text" ;;
        error) printf '\033[31m%s\033[0m\n' "$text" ;;
        *)     printf '%s\n' "$text" ;;
    esac
}

problem() { PROBLEMS=$((PROBLEMS + 1)); }

# Absolute path of a possibly-nonexistent entry: resolve its folder, keep the name.
abs_path() {
    local d b
    d=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) || return 1
    b=$(basename "$1")
    if [ "$d" = "/" ]; then printf '/%s' "$b"; else printf '%s/%s' "$d" "$b"; fi
}

# Classify what is at $1 relative to shared item $2:
#   none | shared (symlink to this item) | other (symlink elsewhere/broken) | real
get_state() {
    local dest="$1" item="$2" target
    if [ -L "$dest" ]; then
        target=$(readlink "$dest")
        case "$target" in /*) ;; *) target="$(dirname "$dest")/$target" ;; esac
        target=$(abs_path "$target") || target=""
        if [ -n "$target" ] && [ "$target" = "$(abs_path "$item")" ]; then echo shared; else echo other; fi
    elif [ -e "$dest" ]; then
        echo real
    else
        echo none
    fi
}

same_content() {   # same_content PATH SHARED_PATH
    if [ -d "$1" ] && [ -d "$2" ]; then diff -rq "$1" "$2" >/dev/null 2>&1
    elif [ -f "$1" ] && [ -f "$2" ] && [ ! -d "$1" ] && [ ! -d "$2" ]; then cmp -s "$1" "$2"
    else return 1
    fi
}

# Keep backups out of 'git status' for every worktree without touching a
# tracked file: .bare/info/exclude is local to this repository.
add_git_exclude() {
    [ "$EXCLUDE_DONE" -eq 1 ] && return 0
    local pattern='*.yngshared-bak-*' dir="$ROOT/.bare/info" file
    file="$dir/exclude"
    mkdir -p "$dir"
    if [ ! -f "$file" ] || ! grep -qxF "$pattern" "$file"; then
        # Make sure we start on a fresh line.
        if [ -s "$file" ] && [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then printf '\n' >> "$file"; fi
        printf '%s\n' "$pattern" >> "$file"
    fi
    EXCLUDE_DONE=1
}

backup_existing() {   # prints the backup path
    local dest="$1" bak="$1.yngshared-bak-$STAMP"
    if [ -e "$bak" ] || [ -L "$bak" ]; then bak="$bak-$RANDOM"; fi
    mv "$dest" "$bak" || return 1
    add_git_exclude
    printf '%s' "$bak"
}

# relative link target: one "../" per folder level between root and worktree.
make_symlink() {   # make_symlink DEST ITEM_NAME LABEL
    local dest="$1" name="$2" label="$3" up="" depth i
    depth=$(printf '%s' "$label" | awk -F/ '{print NF}')
    for ((i = 0; i < depth; i++)); do up="../$up"; done
    ln -s "${up}.shared/$name" "$dest"
}

install_item() {   # install_item WHAT DEST ITEM LABEL   (WHAT = link|copy)
    local what="$1" dest="$2" item="$3" label="$4"
    if [ "$what" = link ]; then make_symlink "$dest" "$(basename "$item")" "$label"
    else cp -R "$item" "$dest"
    fi
}

# Replace a link by a real copy. The copy is made first, so a failure leaves
# the link in place.
convert_to_copy() {   # convert_to_copy DEST ITEM
    local dest="$1" item="$2" tmp="$1.yngshared-tmp"
    if [ -e "$tmp" ] || [ -L "$tmp" ]; then echo "Leftover temporary path exists: $tmp" >&2; return 1; fi
    cp -R "$item" "$tmp" || { rm -rf "$tmp"; return 1; }
    rm -f "$dest" && mv "$tmp" "$dest"
}

invoke_item_action() {   # invoke_item_action ACTION DEST ITEM LABEL
    local action="$1" dest="$2" item="$3" label="$4" name rel state place same bak
    name=$(basename "$item"); rel="$label/$name"
    state=$(get_state "$dest" "$item")
    if [ "$action" = link ]; then place=symlink; else place=copy; fi

    case "$state" in
        none)
            if [ "$action" = unlink ]; then report skip "$rel" "not present"; return; fi
            if [ "$WHATIF" -eq 0 ]; then install_item "$action" "$dest" "$item" "$label" || { report error "$rel" "could not create"; problem; return; }; fi
            report "$place" "$rel"
            ;;
        shared)
            if [ "$action" = link ]; then report keep "$rel" "already linked"; return; fi
            if [ "$WHATIF" -eq 0 ]; then convert_to_copy "$dest" "$item" || { report error "$rel" "could not convert"; problem; return; }; fi
            report copy "$rel" "replaced symlink"
            ;;
        real)
            if [ "$action" = unlink ]; then report keep "$rel" "not a link"; return; fi
            if [ "$FORCE" -eq 0 ]; then report keep "$rel" "real file or folder; --force replaces it"; return; fi
            if same_content "$dest" "$item"; then same=1; else same=0; fi
            if [ "$same" -eq 1 ] && [ "$action" = copy ]; then report keep "$rel" "already an identical copy"; return; fi
            bak=""
            if [ "$same" -eq 0 ]; then
                if [ "$WHATIF" -eq 0 ]; then bak=$(backup_existing "$dest") || { report error "$rel" "backup failed"; problem; return; }; fi
                report backup "$rel" "to $rel.yngshared-bak-$STAMP"
            elif [ "$WHATIF" -eq 0 ]; then
                rm -rf "$dest"   # identical to the shared item: nothing to lose
            fi
            if [ "$WHATIF" -eq 0 ]; then
                if ! install_item "$action" "$dest" "$item" "$label"; then
                    [ -n "$bak" ] && mv "$bak" "$dest"
                    report error "$rel" "could not create"; problem; return
                fi
            fi
            report "$place" "$rel"
            ;;
        other)
            if [ "$action" = unlink ] || [ "$FORCE" -eq 0 ]; then
                report warn "$rel" "link points somewhere else or is broken; --force replaces it"
                problem; return
            fi
            if [ "$WHATIF" -eq 0 ]; then
                rm -f "$dest"
                install_item "$action" "$dest" "$item" "$label" || { report error "$rel" "could not create"; problem; return; }
            fi
            report "$place" "$rel" "replaced other link"
            ;;
    esac
}

# Resolve a worktree argument: sets WT_PATH and WT_LABEL, or returns 1 with a message.
resolve_worktree() {
    local arg="$1" p
    if [ -d "$arg" ]; then p=$(cd "$arg" && pwd -P)
    elif [ -d "$ROOT/$arg" ]; then p=$(cd "$ROOT/$arg" && pwd -P)
    else WT_ERR="Not a folder: $arg"; return 1
    fi
    case "$p/" in
        "$ROOT"/*) ;;
        *) WT_ERR="Not inside the project root ($ROOT): $p"; return 1 ;;
    esac
    WT_PATH="$p"
    WT_LABEL="${p#"$ROOT"/}"
    if [ "$p" = "$ROOT" ]; then WT_ERR="Not a worktree: the project root itself"; return 1; fi
    case "$WT_LABEL" in .shared|.bare) WT_ERR="Not a worktree: $WT_LABEL"; return 1 ;; esac
    return 0
}

# --------------------------------------------------------------------------
# Preconditions
# --------------------------------------------------------------------------

if [ ! -d "$SHARED" ]; then
    echo "ERROR: $SHARED does not exist. Create it and put the private files there first." >&2
    exit 1
fi

ITEMS=()
while IFS= read -r line; do ITEMS+=("$line"); done < <(find "$SHARED" -mindepth 1 -maxdepth 1 | sort)

if [ -n "$NAMES" ]; then
    FILTERED=()
    IFS=',' read -r -a WANTED <<< "$NAMES"
    missing=""
    for w in "${WANTED[@]}"; do
        found=0
        for it in "${ITEMS[@]+"${ITEMS[@]}"}"; do
            if [ "$(basename "$it")" = "$w" ]; then found=1; FILTERED+=("$it"); fi
        done
        [ "$found" -eq 0 ] && missing="$missing $w"
    done
    if [ -n "$missing" ]; then echo "ERROR: not in .shared/:$missing" >&2; exit 1; fi
    ITEMS=("${FILTERED[@]}")
fi

if [ ${#ITEMS[@]} -eq 0 ]; then echo "Nothing to do: .shared/ is empty."; exit 0; fi

# --------------------------------------------------------------------------
# Work out the worktrees, then apply the action
# --------------------------------------------------------------------------

TARGETS=()
if [ "$ALL" -eq 1 ]; then
    if ! out=$(git --git-dir="$ROOT/.bare" worktree list --porcelain 2>&1); then
        echo "ERROR: 'git worktree list' failed: $out" >&2
        exit 1
    fi
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wp="${line#worktree }"
                # Canonicalize so the comparison with $ROOT is not fooled by
                # symlinked folders (e.g. /tmp -> /private/tmp on macOS).
                wp=$(cd "$wp" 2>/dev/null && pwd -P) || continue
                case "$wp" in
                    "$ROOT"/*) case "$wp" in */.bare) ;; *) TARGETS+=("$wp") ;; esac ;;
                esac ;;
        esac
    done <<< "$out"
else
    TARGETS=("${WORKTREES[@]}")
fi

for arg in "${TARGETS[@]+"${TARGETS[@]}"}"; do
    if ! resolve_worktree "$arg"; then
        printf '\033[31merror  %s  (%s)\033[0m\n' "$arg" "$WT_ERR"
        problem
        continue
    fi
    for item in "${ITEMS[@]}"; do
        invoke_item_action "$ACTION" "$WT_PATH/$(basename "$item")" "$item" "$WT_LABEL"
    done
done

[ "$WHATIF" -eq 1 ] && echo "WhatIf: nothing was changed."
[ "$PROBLEMS" -gt 0 ] && exit 1
exit 0
