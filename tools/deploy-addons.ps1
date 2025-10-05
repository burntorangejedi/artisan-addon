<#
Deploy the addon folder to your World of Warcraft AddOns directory.

Usage:
  pwsh.exe .\tools\deploy-addons.ps1 [-AddonName <name>] [-Target <AddOnsPath>]

If -Target is omitted the script will try to auto-detect common WoW AddOns locations and prompt you to pick one, or allow you to enter a path.
#>

param(
    [string]$AddonName = "artisan-addon",
    [string]$Target,
    [switch]$ExcludeDev,
    [switch]$IncludeDev,
    [switch]$PreserveSavedVariables,
    [switch]$DryRun,
    [switch]$NoPrompt,
    [switch]$Debug
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$source = $repoRoot

function Write-ErrAndExit($msg) {
    Write-Error $msg
    exit 1
}

function Run-Robocopy($argList) {
    # Build a quoted command string and invoke via cmd.exe /c so complex paths are parsed correctly
    $quote = { param($s) if ($s -match '\s') { '"' + $s + '"' } else { $s } }
    $argString = ($argList | ForEach-Object { & $quote $_ }) -join ' '
    $cmd = "robocopy $argString"
    Write-Host "Running robocopy via cmd: $cmd" -ForegroundColor Cyan

    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList '/c', $cmd -NoNewWindow -Wait -PassThru
    $ec = $proc.ExitCode
    try { $ec = [int]$ec } catch { $ec = $proc.ExitCode }
    Write-Host "Robocopy exit code: $ec" -ForegroundColor Cyan
    return $ec
}

if (-not (Test-Path $source)) { Write-ErrAndExit "Source folder not found: $source" }

# Candidate AddOns directories to check
$candidates = @()
if ($env:ProgramFiles) {
    $candidates += Join-Path $env:ProgramFiles "World of Warcraft\_retail_\Interface\AddOns"
    $candidates += Join-Path $env:ProgramFiles "World of Warcraft\_classic_\Interface\AddOns"
}
if ($env:ProgramFiles -and $env:ProcessorArchitecture -eq 'x86') {
    # On 64-bit Windows ProgramFiles(x86) exists
}
    # On 64-bit Windows ProgramFiles(x86) may exist; read it safely
    $pf86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if ($pf86) {
        $candidates += Join-Path $pf86 "World of Warcraft\_retail_\Interface\AddOns"
        $candidates += Join-Path $pf86 "World of Warcraft\_classic_\Interface\AddOns"
    }
# Also check common Blizzard install location under LocalAppData
$candidates += Join-Path $env:LOCALAPPDATA "Blizzard\World of Warcraft\_retail_\Interface\AddOns"
$candidates += Join-Path $env:LOCALAPPDATA "Blizzard\World of Warcraft\_classic_\Interface\AddOns"

$existing = @($candidates | Where-Object { Test-Path $_ } | Select-Object -Unique)

if ($Target) {
    $chosen = $Target
} elseif ($existing.Count -gt 0 -and $NoPrompt) {
    # Non-interactive: pick the first detected AddOns folder
    $chosen = $existing[0]
} elseif ($existing.Count -gt 0) {
    Write-Host "Found the following possible AddOns folders:" -ForegroundColor Cyan
    $i = 1
    foreach ($p in $existing) { Write-Host "  [$i] $p"; $i++ }
    Write-Host "  [M] Enter a custom path"
    $choice = Read-Host "Choose a destination (number or M)"
    if ($choice -match '^[0-9]+$') {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $existing.Count) { $chosen = $existing[$idx] }
        else { Write-ErrAndExit "Invalid selection" }
    } elseif ($choice -match '^[Mm]') {
        $chosen = Read-Host "Enter full path to AddOns folder"
    } else {
        Write-ErrAndExit "Invalid choice"
    }
} else {
    Write-Host "No common AddOns folders were detected." -ForegroundColor Yellow
    $chosen = Read-Host "Enter full path to your World of Warcraft Interface\AddOns folder"
}

if (-not (Test-Path $chosen)) {
    Write-Host "The path you provided does not exist: $chosen" -ForegroundColor Yellow
    $create = Read-Host "Create it? (y/N)"
    if ($create -match '^[Yy]') {
        New-Item -ItemType Directory -Path $chosen -Force | Out-Null
        Write-Host "Created $chosen"
    } else {
        Write-ErrAndExit "Aborting: target folder does not exist"
    }
}

# Destination path for the addon inside the chosen AddOns folder
$dest = Join-Path $chosen $AddonName

Write-Host "Deploy target chosen: $chosen" -ForegroundColor Cyan
Write-Host "Deployment destination: $dest" -ForegroundColor Cyan

# Informational check about existing addon folder (dry-run vs real)
if ($DryRun) {
    Write-Host "[DryRun] Previous addon folder would have been removed: $dest"
} else {
    if (-not (Test-Path $dest)) {
        Write-Host "No previous addon folder present at: $dest" -ForegroundColor Green
    } else {
        Write-Host "Previous addon folder detected at: $dest" -ForegroundColor Yellow
    }
}

if (Test-Path $dest) {
    Write-Host "Existing addon found at $dest" -ForegroundColor Yellow

    # Optionally preserve SavedVariables by copying them to a temp location
    $savedTemp = $null
    if ($PreserveSavedVariables) {
        $svPath = Join-Path $dest 'SavedVariables'
        if (Test-Path $svPath) {
            $savedTemp = Join-Path $env:TEMP ("artisan_savedvars_" + (Get-Date -Format yyyyMMddHHmmss))
            if ($DryRun) {
                Write-Host "[DryRun] Would copy SavedVariables from $svPath to $savedTemp"
            } else {
                New-Item -ItemType Directory -Path $savedTemp -Force | Out-Null
                Copy-Item -Path (Join-Path $svPath '*') -Destination $savedTemp -Recurse -Force
                Write-Host "SavedVariables copied to $savedTemp"
            }
        }
    }

    # Remove existing addon folder
    if ($DryRun) {
        Write-Host "[DryRun] Would remove existing folder $dest"
    } else {
        Write-Host "Removing existing addon at $dest" -ForegroundColor Yellow
        try {
            Remove-Item -Recurse -Force -LiteralPath $dest -ErrorAction Stop

        } catch {
            Write-Host "Failed to remove existing folder, trying Robocopy cleanup..." -ForegroundColor Yellow
            # try robocopy to remove contents
            $rcArgs = @($source, $dest, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS")
                $rcExit = Run-Robocopy $rcArgs
                # attempt to remove any remaining items
                Remove-Item -Recurse -Force -LiteralPath $dest -ErrorAction SilentlyContinue
                if (Test-Path $dest) {
                    Write-Host "Robocopy cleanup exit code: $rcExit; destination still exists: $dest" -ForegroundColor Yellow
                }
        }

        # After the removal attempt, ensure the destination folder is gone; abort if it's not
        if (Test-Path $dest) {
            Write-ErrAndExit "Failed to remove existing addon folder: $dest. Aborting deployment."
        } else {
            Write-Host "Previous addon folder removed: $dest" -ForegroundColor Green
        }
    }
}

Write-Host "Preparing to copy from $source to $dest" -ForegroundColor Green

# Confirm with the user before performing destructive actions (unless NoPrompt is set)
if (-not $NoPrompt) {
    $promptMsg = "Proceed with deployment to '$dest'? (y/N)"
    $confirm = Read-Host $promptMsg
    if ($confirm -notmatch '^[Yy]') {
        Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Default excludes (can be overridden with -IncludeDev)
$defaultExcludeDirs = @('.git','tools','.vscode')
$defaultExcludeFiles = @('.gitignore')
$doExclude = $ExcludeDev -or (-not $IncludeDev)

# Build robocopy args
$robocopyArgs = @($source, $dest, "/MIR")
if ($doExclude) {
    # Exclude directories
    $robocopyArgs += "/XD"
    $robocopyArgs += $defaultExcludeDirs
    # Exclude files
    $robocopyArgs += "/XF"
    $robocopyArgs += $defaultExcludeFiles
}

if ($DryRun) {
    $quote = { param($s) if ($s -match '\s') { '"' + $s + '"' } else { $s } }
    $argString = ($robocopyArgs | ForEach-Object { & $quote $_ }) -join ' '
    Write-Host "[DryRun] Would run robocopy with arguments: $argString"
} else {
    # Prefer robocopy for robust copying when exclusions or preservation are needed
    if ($doExclude -or $PreserveSavedVariables) {
    $rcExit = Run-Robocopy $robocopyArgs
    if ($rcExit -ge 8) { Write-ErrAndExit "Robocopy failed with exit code $rcExit" }
    } else {
        try {
            # Perform Copy-Item but skip excluded names if needed
            if ($doExclude) {
                $children = Get-ChildItem -Path $source -Force
                foreach ($child in $children) {
                    if ($defaultExcludeDirs -contains $child.Name -or $defaultExcludeFiles -contains $child.Name) {
                        continue
                    }
                    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
                    Copy-Item -Path $child.FullName -Destination $dest -Recurse -Force -ErrorAction Stop
                }
            } else {
                if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
                Copy-Item -Path (Join-Path $source '*') -Destination $dest -Recurse -Force -ErrorAction Stop
            }
        } catch {
            Write-Host "Copy-Item failed, falling back to Robocopy..." -ForegroundColor Yellow
            $rcExit = Run-Robocopy $robocopyArgs
            if ($rcExit -ge 8) { Write-ErrAndExit "Robocopy failed with exit code $rcExit" }
        }
    }

    Write-Host "Deployment complete." -ForegroundColor Green

    # Restore SavedVariables if we preserved them
    if ($savedTemp) {
        $destSv = Join-Path $dest 'SavedVariables'
        if (-not (Test-Path $destSv)) { New-Item -ItemType Directory -Path $destSv | Out-Null }
        Copy-Item -Path (Join-Path $savedTemp '*') -Destination $destSv -Recurse -Force
        Write-Host "Restored SavedVariables to $destSv"
    }
}
