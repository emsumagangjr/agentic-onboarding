<#
.SYNOPSIS
    Shares private files from .shared\ with git worktrees: -link, -copy or -unlink.

.DESCRIPTION
    Author:  Emeterio M. Sumagang Jr.
    Company: yngsoftware (www.yngsoftware.com)

    Works with any project laid out as a bare repository with one folder per
    worktree (the "Bare Repository + Git Worktrees" pattern):

        <project-root>\
        |-- .bare\          shared git database
        |-- .shared\        private, untracked files (.env, secrets\, ...)
        |-- main\           worktree
        |-- <other>\        more worktrees (epic, task, agent, ...)
        `-- yngshared.ps1   <- this script (must sit at the project root)

    REQUIREMENTS
    - Windows PowerShell 5.1 or PowerShell 7+, on Windows (uses cmd's mklink
      and fsutil).
    - Git on PATH (only needed for -All).
    - A project root containing .bare\ and .shared\ as shown above.
    - For -link: Developer Mode or an elevated shell (see SYMBOLIC LINKS).

    INSTALL
    Copy this file into the project root, beside .bare\ and .shared\. The
    script treats its own folder as the project root, so it cannot be run from
    anywhere else. Nothing else needs installing.

    HOW TO RUN
    From the project root (or via its full path), pick one action and the
    worktree(s) to apply it to, for example:  .\yngshared.ps1 -link main
    See the EXAMPLES section below. Preview any run first with -WhatIf.

    Every file or folder directly inside .shared\ is an "item". Choose exactly
    one action, and the worktree(s) to apply it to:

        -link     Put a symbolic link to each item in the worktree. The worktree
                  follows .shared\: edit the file through any worktree and every
                  linked worktree sees the change.
        -copy     Put a real, independent copy of each item in the worktree.
                  Same result as -link followed by -unlink. Use it when a
                  worktree needs its own .env values.
        -unlink   Turn each link into a real copy of the item it pointed to.
                  Only links into .shared\ are touched; real files are never
                  changed.

    Nothing inside .shared\ is ever changed, moved or deleted.

    WHAT HAPPENS TO WHAT IS ALREADY IN THE WORKTREE

    "Link" below means a symlink, junction or hard link that points into
    .shared\ (older versions of this script sometimes left hard links; they are
    recognised and handled like symlinks).

      At the path                  -link              -copy               -unlink
      ---------------------------  -----------------  ------------------  ------------------
      nothing there                symlink            real copy           skip (not present)
      link into .shared\           keep (already      convert to a real   convert to a real
                                   linked); a hard    copy                copy
                                   link or junction
                                   becomes a symlink
      real file or folder          keep               keep                keep
        ...with -Force             back up, symlink   back up, copy       keep (no effect)
      link somewhere else, or      warn and skip      warn and skip       warn and skip
      broken link
        ...with -Force             replace with a     replace with a      warn and skip
                                   symlink            copy

    Without -Force nothing real is ever overwritten, so a worktree's own .env
    survives and re-running is always safe. A worktree opts out of sharing simply
    by having its own real file at that path.

    -FORCE AND BACKUPS
    With -Force, a real file or folder that differs from the shared item is
    first renamed inside the same worktree to
        <name>.yngshared-bak-<yyyyMMdd-HHmmss>
    for example .env.yngshared-bak-20260919-153000. The first time a backup is
    made, the pattern *.yngshared-bak-* is added to .bare\info\exclude, a local
    Git file that is never committed and applies to every worktree, so backups
    (which may contain secrets) can never show up in 'git status' or be
    committed by accident. No backup is made when the existing file is
    byte-identical to the shared one, or when the path is only a stray link.
    The script never deletes backups; delete them yourself when you are happy.

    SYMBOLIC LINKS
    Links are relative (for example ..\.shared\.env), so they keep working if the
    project folder is moved or renamed. Creating symlinks on Windows needs
    Developer Mode (Settings > System > Advanced > For developers) or an
    elevated (administrator) shell. If they are not permitted, -link stops with
    an error and changes nothing. -copy and -unlink do not need symlinks.

    MISTAKES SHOW THE HELP
    No action, more than one action, an unknown switch, or no worktree (and no
    -All) prints a one-line reason followed by this help, changes nothing, and
    exits with code 2.

    GIT
    Links and copies must not be committed. Make sure each private name is
    ignored in every branch's .gitignore (for example /.env). A pattern with a
    trailing slash does not match a symlink. Afterwards 'git status --short'
    should not list them.

    HOW TO TELL A LINK
        ls -Force dev                  # shows  .env -> ..\.shared\.env
        Get-Item dev\.env -Force | Select-Object LinkType, Target

.PARAMETER Link
    Action: link each item into the worktree(s) with a relative symlink.

.PARAMETER Copy
    Action: put a real copy of each item into the worktree(s).

.PARAMETER Unlink
    Action: convert each link into the worktree(s) into a real copy.

.PARAMETER Worktree
    One or more worktree folders, separated by spaces (no parameter name
    needed). Each may be a name relative to the project root (dev), a path
    relative to the current directory (.\dev, or . when you are already inside
    the worktree), or a full path. The folder must exist and be inside the
    project root. Use this or -All, not both.

.PARAMETER All
    Act on every worktree reported by 'git worktree list' (the bare repository
    is skipped). Use this or worktree names, not both.

.PARAMETER Name
    Limit the run to these items from .shared\, for example -Name .env,secrets.
    Default: every item in .shared\. A name that is not in .shared\ is an error.

.PARAMETER Force
    With -link or -copy: also replace a real file or folder (after a backup, see
    above) and a link that points somewhere else. Has no effect with -unlink.

.PARAMETER WhatIf
    Show what would happen ("would symlink ...") without changing anything.
    Recommended before -copy, -unlink, or anything with -Force or -All.

.EXAMPLE
    .\yngshared.ps1 -link dev

    Link everything in .shared\ into dev\.

.EXAMPLE
    .\yngshared.ps1 -link -All -WhatIf

    Preview linking every worktree; nothing is changed.

.EXAMPLE
    .\yngshared.ps1 -copy agent-x -Name .env

    Give the agent-x worktree its own copy of .env only (opt out of sharing
    for that item).

.EXAMPLE
    .\yngshared.ps1 -unlink dev

    Make dev's links into real, independent copies.

.EXAMPLE
    .\yngshared.ps1 -link main dev -Force

    Link two worktrees, replacing any real .env already there (backed up first).

.NOTES
    Name:         yngshared
    Version:      1.0.0
    Created:      2026-09-19
    Author:       Emeterio M. Sumagang Jr.
    Company:      yngsoftware (www.yngsoftware.com)

    Works in Windows PowerShell 5.1 and PowerShell 7.

    Output, one line per item ("would ..." instead when -WhatIf is used):
        symlink   created a relative symbolic link
        copy      created a real copy
        backup    renamed an existing real file or folder (-Force)
        keep      left alone (see the note after it)
        skip      nothing to do
        warn      refused; counts as a problem
        error     something failed; counts as a problem

    Exit code: 0 = success, 1 = a warning or error occurred, 2 = usage mistake.

    Type switches out in full. PowerShell accepts short abbreviations, but one
    that fits more than one switch (such as -E or -W, which also match
    PowerShell's built-in switches) is rejected by PowerShell itself before
    this script can print the help.
#>
param(
    [switch]$Link,
    [switch]$Copy,
    [switch]$Unlink,
    [switch]$All,
    [switch]$Force,
    [switch]$WhatIf,
    [string[]]$Name,

    # Catches worktree names AND any unknown -switch (as text) so mistakes can
    # show the help instead of PowerShell's terse binding error.
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Worktree
)

$root     = $PSScriptRoot
$shared   = Join-Path $root '.shared'
$stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$problems = 0
$excludeDone = $false

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

function Stop-WithHelp([string]$Message) {
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Write-Host ''
    Write-Host (Get-Help $PSCommandPath -Full | Out-String)
    exit 2
}

function Report([string]$Status, [string]$Path, [string]$Note = '') {
    $mutating = $Status -in 'symlink', 'copy', 'backup'
    $text = if ($WhatIf -and $mutating) { "would $Status" } else { $Status }
    if ($Note) { $text += "  $Path  ($Note)" } else { $text += "  $Path" }
    $color = switch ($Status) { 'warn' { 'Yellow' } 'error' { 'Red' } default { $null } }
    if ($color) { Write-Host $text -ForegroundColor $color } else { Write-Host $text }
}

# Classify what is at $Path relative to the shared $Item:
#   none    nothing there
#   shared  a symlink/junction/hard link that points at this shared item
#   other   a symlink/junction pointing elsewhere, or broken
#   real    an ordinary file or folder
function Get-State([string]$Path, $Item) {
    $e = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $e) { return @{ Kind = 'none' } }
    $type  = $e.LinkType
    $isDir = [bool]$e.PSIsContainer

    if ($type -in 'SymbolicLink', 'Junction') {
        $t = @($e.Target)[0]
        if ($t) {
            $t = $t -replace '^\\\?\?\\', ''
            if (-not [IO.Path]::IsPathRooted($t)) { $t = Join-Path (Split-Path -Parent $Path) $t }
            try { $t = [IO.Path]::GetFullPath($t) } catch { }
        }
        $kind = if ($t -and ($t.TrimEnd('\') -ieq $Item.FullName.TrimEnd('\'))) { 'shared' } else { 'other' }
        return @{ Kind = $kind; LinkType = $type; IsDir = $isDir }
    }

    if ($type -eq 'HardLink' -and -not $isDir) {
        # A hard link is just another name for the same file: ask NTFS whether
        # the shared item is one of this file's names (drive letter dropped).
        $mine  = $Item.FullName.Substring(2)
        $names = @(& fsutil hardlink list $Path 2>$null)
        if ($names | Where-Object { $_.Trim() -ieq $mine }) {
            return @{ Kind = 'shared'; LinkType = 'HardLink'; IsDir = $false }
        }
    }
    return @{ Kind = 'real'; IsDir = $isDir }
}

function Get-HashMap([string]$Dir) {
    $map = @{}
    Get-ChildItem -LiteralPath $Dir -Recurse -Force -File | ForEach-Object {
        $map[$_.FullName.Substring($Dir.Length)] = (Get-FileHash -LiteralPath $_.FullName).Hash
    }
    $map
}

# True when the existing path holds exactly the same content as the shared item.
function Test-SameContent([string]$Path, [string]$SharedPath) {
    $aDir = Test-Path -LiteralPath $Path -PathType Container
    $bDir = Test-Path -LiteralPath $SharedPath -PathType Container
    if ($aDir -ne $bDir) { return $false }
    if (-not $aDir) {
        return (Get-FileHash -LiteralPath $Path).Hash -eq (Get-FileHash -LiteralPath $SharedPath).Hash
    }
    $a = Get-HashMap $Path
    $b = Get-HashMap $SharedPath
    if ($a.Count -ne $b.Count) { return $false }
    foreach ($k in $a.Keys) { if ($a[$k] -ne $b[$k]) { return $false } }
    return $true
}

# Delete a link (or hard link name) without touching what it points to.
function Remove-LinkEntry([string]$Path, [bool]$IsDir) {
    if ($IsDir) { [IO.Directory]::Delete($Path) } else { [IO.File]::Delete($Path) }
}

function New-SharedSymlink([string]$Dest, $Item, [string]$Label) {
    # One "..\" per folder level between the project root and the worktree.
    $up     = '..\' * (($Label -split '\\').Count)
    $target = "$up.shared\$($Item.Name)"
    # cmd's mklink stores the target text exactly as written, so the link is
    # relative to its own folder. New-Item -Target would instead resolve a
    # relative path against the current directory and fail.
    $flag = if ($Item.PSIsContainer) { '/D' } else { '' }
    $out  = cmd /c mklink $flag "`"$Dest`"" "`"$target`"" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "mklink failed: $out" }
}

# Replace a link by a real copy. The copy is made first, so a failure leaves the
# link in place.
function ConvertTo-RealCopy([string]$Dest, $Item, [bool]$IsDir) {
    $tmp = "$Dest.yngshared-tmp"
    if (Get-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue) { throw "Leftover temporary path exists: $tmp" }
    Copy-Item -LiteralPath $Item.FullName -Destination $tmp -Recurse
    Remove-LinkEntry $Dest $IsDir
    Move-Item -LiteralPath $tmp -Destination $Dest
}

function Backup-Existing([string]$Dest) {
    $bak = "$Dest.yngshared-bak-$stamp"
    if (Get-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue) {
        $bak += '-' + [guid]::NewGuid().ToString('N').Substring(0, 4)
    }
    Move-Item -LiteralPath $Dest -Destination $bak
    Add-GitExclude
    $bak
}

# Keep backups out of 'git status' for every worktree, without touching any
# tracked file: .bare\info\exclude is local to this repository.
function Add-GitExclude {
    if ($script:excludeDone) { return }
    $pattern = '*.yngshared-bak-*'
    $dir  = Join-Path $root '.bare\info'
    $file = Join-Path $dir 'exclude'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $raw = if (Test-Path -LiteralPath $file) { Get-Content -LiteralPath $file -Raw } else { '' }
    if (-not $raw -or -not ($raw -split "`r?`n" | Where-Object { $_.Trim() -eq $pattern })) {
        $line = if ($raw -and -not $raw.EndsWith("`n")) { "`n$pattern" } else { $pattern }
        Add-Content -LiteralPath $file -Value $line
    }
    $script:excludeDone = $true
}

# Resolve a worktree argument to its full path and its path under the project
# root (the "label"), refusing anything that is not a folder inside the root.
function Resolve-Worktree([string]$Arg) {
    # Current directory first (so "." and ".\dev" work), then relative to the
    # project root (so "dev" works from anywhere).
    $p = if (Test-Path -LiteralPath $Arg -PathType Container) { Convert-Path -LiteralPath $Arg }
         else { [IO.Path]::GetFullPath((Join-Path $root $Arg)) }
    $p = $p.TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $p -PathType Container)) { throw "Not a folder: $Arg" }
    if (-not $p.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Not inside the project root ($root): $p"
    }
    $label = $p.Substring($root.Length + 1)
    if ($label -in '.shared', '.bare') { throw "Not a worktree: $label" }
    [pscustomobject]@{ Path = $p; Label = $label }
}

# Put the shared item at $Dest as a symlink (-link) or a real copy (-copy).
function Install-SharedItem([string]$Dest, $Item, [string]$Label, [string]$What) {
    if ($What -eq 'link') { New-SharedSymlink $Dest $Item $Label }
    else { Copy-Item -LiteralPath $Item.FullName -Destination $Dest -Recurse }
}

function Invoke-ItemAction([string]$Action, [string]$Dest, $Item, [string]$Label) {
    $rel   = "$Label\$($Item.Name)"
    $st    = Get-State $Dest $Item
    $place = if ($Action -eq 'link') { 'symlink' } else { 'copy' }

    switch ($st.Kind) {
        'none' {
            if ($Action -eq 'unlink') { Report 'skip' $rel 'not present'; return }
            if (-not $WhatIf) { Install-SharedItem $Dest $Item $Label $Action }
            Report $place $rel
        }
        'shared' {
            if ($Action -eq 'link') {
                if ($st.LinkType -eq 'SymbolicLink') { Report 'keep' $rel 'already linked'; return }
                if (-not $WhatIf) {
                    Remove-LinkEntry $Dest $st.IsDir
                    New-SharedSymlink $Dest $Item $Label
                }
                Report 'symlink' $rel "replaced $(($st.LinkType -replace 'SymbolicLink', 'symlink').ToLower())"
            }
            else {
                if (-not $WhatIf) { ConvertTo-RealCopy $Dest $Item $st.IsDir }
                Report 'copy' $rel "replaced $(($st.LinkType -replace 'SymbolicLink', 'symlink').ToLower())"
            }
        }
        'real' {
            if ($Action -eq 'unlink') { Report 'keep' $rel 'not a link'; return }
            if (-not $Force) { Report 'keep' $rel 'real file or folder; -Force replaces it'; return }
            $same = Test-SameContent $Dest $Item.FullName
            if ($same -and $Action -eq 'copy') { Report 'keep' $rel 'already an identical copy'; return }
            $bak = $null
            if (-not $same) {
                if (-not $WhatIf) { $bak = Backup-Existing $Dest }
                Report 'backup' $rel "to $($rel).yngshared-bak-$stamp"
            }
            elseif (-not $WhatIf) {
                # Identical to the shared item: nothing to lose, drop it.
                if ($st.IsDir) { [IO.Directory]::Delete($Dest, $true) } else { [IO.File]::Delete($Dest) }
            }
            if (-not $WhatIf) {
                try { Install-SharedItem $Dest $Item $Label $Action }
                catch {
                    if ($bak) { Move-Item -LiteralPath $bak -Destination $Dest }
                    throw
                }
            }
            Report $place $rel
        }
        'other' {
            if ($Action -eq 'unlink' -or -not $Force) {
                Report 'warn' $rel 'link points somewhere else or is broken; -Force replaces it'
                $script:problems++
                return
            }
            if (-not $WhatIf) {
                Remove-LinkEntry $Dest $st.IsDir
                Install-SharedItem $Dest $Item $Label $Action
            }
            Report $place $rel 'replaced other link'
        }
    }
}

# --------------------------------------------------------------------------
# Validate the command line (any mistake prints the help)
# --------------------------------------------------------------------------

$unknown = @($Worktree | Where-Object { $_ -like '-*' })
if ($unknown.Count) { Stop-WithHelp "Unknown option: $($unknown -join ', ')" }

$actions = @()
if ($Link)   { $actions += 'link' }
if ($Copy)   { $actions += 'copy' }
if ($Unlink) { $actions += 'unlink' }
if ($actions.Count -eq 0) { Stop-WithHelp 'Choose one action: -link, -copy or -unlink.' }
if ($actions.Count -gt 1) { Stop-WithHelp 'Choose only one of -link, -copy and -unlink.' }
$action = $actions[0]

if ($All -and $Worktree)      { Stop-WithHelp 'Use either -All or worktree names, not both.' }
if (-not $All -and -not $Worktree) { Stop-WithHelp 'Name at least one worktree, or use -All.' }

# --------------------------------------------------------------------------
# Preconditions
# --------------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $shared -PathType Container)) {
    Write-Host "ERROR: $shared does not exist. Create it and put the private files there first." -ForegroundColor Red
    exit 1
}

$items = @(Get-ChildItem -LiteralPath $shared -Force)
if ($Name) {
    $missing = @($Name | Where-Object { $n = $_; -not ($items | Where-Object { $_.Name -ieq $n }) })
    if ($missing.Count) {
        Write-Host "ERROR: not in .shared\: $($missing -join ', ')" -ForegroundColor Red
        exit 1
    }
    $items = @($items | Where-Object { $Name -contains $_.Name })
}
if (-not $items.Count) { Write-Host 'Nothing to do: .shared\ is empty.'; exit 0 }

if ($action -eq 'link') {
    # Fail before changing anything if symlinks are not allowed on this machine.
    $probe = Join-Path $env:TEMP ('yngshared-probe-' + [guid]::NewGuid().ToString('N'))
    cmd /c mklink /D "`"$probe`"" "`"$shared`"" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'ERROR: cannot create symbolic links. Turn on Developer Mode (Settings > System > Advanced > For developers) or run as administrator. Nothing was changed.' -ForegroundColor Red
        exit 1
    }
    [IO.Directory]::Delete($probe)
}

# --------------------------------------------------------------------------
# Work out the worktrees, then apply the action
# --------------------------------------------------------------------------

$targets = @($Worktree)
if ($All) {
    $lines = & git --git-dir="$root\.bare" worktree list --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: 'git worktree list' failed: $lines" -ForegroundColor Red
        exit 1
    }
    $targets = @($lines | Where-Object { $_ -like 'worktree *' } |
        ForEach-Object { [IO.Path]::GetFullPath($_.Substring(9)) } |
        Where-Object { $_.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase) -and $_ -notlike '*\.bare' })
}

foreach ($arg in $targets) {
    try { $wt = Resolve-Worktree $arg }
    catch {
        Write-Host "error  $arg  ($($_.Exception.Message))" -ForegroundColor Red
        $problems++
        continue
    }

    foreach ($item in $items) {
        try { Invoke-ItemAction $action (Join-Path $wt.Path $item.Name) $item $wt.Label }
        catch {
            Report 'error' "$($wt.Label)\$($item.Name)" $_.Exception.Message
            $problems++
        }
    }
}

if ($WhatIf) { Write-Host 'WhatIf: nothing was changed.' }
if ($problems) { exit 1 }
exit 0
