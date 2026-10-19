# ============================================================
# VotV Archipelago mod auto-updater (apfix)
# Pulls the latest main.lua / item_map.lua from GitHub and
# installs them into the mod folder. Makes a backup first.
# Run: double-click Update-APFix.bat  (or: powershell -File update-apfix.ps1)
# ============================================================

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Branch = "arena/756c58a7-fixer"
$Base   = "https://raw.githubusercontent.com/dodecube/fixer/$Branch"
$Files  = @("Scripts/main.lua", "Scripts/item_map.lua")

Write-Host "=== VotV AP mod auto-updater ===" -ForegroundColor Cyan

function Get-SteamGameRoots {
    $roots = @()
    $steam = $null
    try {
        $steam = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction Stop).SteamPath
    } catch {
        try { $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath } catch {}
    }
    $libs = @()
    if ($steam) {
        $libs += $steam
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            Select-String -Path $vdf -Pattern '"path"' | ForEach-Object {
                $p = ($_.Line -split '"')[3] -replace '\\\\', '\'
                $libs += $p
            }
        }
    }
    foreach ($lib in $libs) {
        $g = Join-Path $lib "steamapps\common\Voices of the Void"
        if (Test-Path $g) { $roots += $g }
        $g2 = Join-Path $lib "Voices of the Void"
        if (Test-Path $g2) { $roots += $g2 }
    }
    return $roots | Select-Object -Unique
}

function Find-ModFolder {
    $candidates = @()
    foreach ($root in (Get-SteamGameRoots)) {
        foreach ($modsRoot in @(
            (Join-Path $root "Binaries\Win64\UE4SS\Mods"),
            (Join-Path $root "Binaries\Win64\Mods")
        )) {
            if (-not (Test-Path $modsRoot)) { continue }
            Get-ChildItem -Path $modsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $scripts = Join-Path $_.FullName "Scripts"
                if ((Test-Path (Join-Path $scripts "main.lua")) -or (Test-Path (Join-Path $scripts "archipelago.lua"))) {
                    $candidates += $scripts
                }
            }
        }
    }
    return $candidates | Select-Object -Unique
}

# --- locate target folder ----------------------------------------------
$target = $null
if ($args.Count -ge 1) {
    $target = $args[0]
    if (-not (Test-Path $target)) { Write-Host "Folder not found: $target" -ForegroundColor Red; exit 1 }
} else {
    $found = Find-ModFolder
    if ($found.Count -eq 1) {
        $target = $found[0]
    } elseif ($found.Count -gt 1) {
        Write-Host "Found several mod folders:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $found.Count; $i++) { Write-Host "  [$i] $($found[$i])" }
        $sel = Read-Host "Which one to update? (number)"
        $target = $found[[int]$sel]
    } else {
        Write-Host "Could not find the mod folder automatically." -ForegroundColor Yellow
        Write-Host "Example: C:\...\Voices of the Void\Binaries\Win64\UE4SS\Mods\<mod>\Scripts"
        $target = Read-Host "Paste the Scripts folder path"
        if (-not (Test-Path $target)) { Write-Host "Folder not found: $target" -ForegroundColor Red; exit 1 }
    }
}
Write-Host "Mod folder: $target" -ForegroundColor Green

# --- make sure the game is not running ----------------------------------
if (Get-Process -Name "VotV*" -ErrorAction SilentlyContinue) {
    Write-Host "VotV is RUNNING. Close the game first (Lua files load only at startup)." -ForegroundColor Red
    $ans = Read-Host "Continue anyway? (y/n)"
    if ($ans -ne "y") { exit 1 }
}

# --- download to temp and validate --------------------------------------
$tmp = Join-Path $env:TEMP ("apfix_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
$downloaded = @()
foreach ($f in $Files) {
    $name = Split-Path $f -Leaf
    $dest = Join-Path $tmp $name
    Write-Host "Downloading $f ..."
    try {
        Invoke-WebRequest -Uri "$Base/$f" -OutFile $dest -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    $head = (Get-Content $dest -TotalCount 1) -join ""
    if ($head -notlike "*MyLuaMod*") {
        Write-Host "Downloaded $name does not look like the mod file (got: $head)" -ForegroundColor Red
        exit 1
    }
    $downloaded += @{ src = $dest; name = $name }
}
$mainHead = (Get-Content (Join-Path $tmp "main.lua") -TotalCount 1) -join ""
Write-Host "Version marker: $mainHead" -ForegroundColor Green

# --- backup and install ---------------------------------------------------
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
foreach ($d in $downloaded) {
    $dest = Join-Path $target $d.name
    if (Test-Path $dest) {
        Copy-Item $dest "$dest.bak-$stamp" -Force
        Write-Host "Backup: $($d.name).bak-$stamp"
    }
    Copy-Item $d.src $dest -Force
    Write-Host "Installed: $($d.name) ($([math]::Round((Get-Item $dest).Length/1KB,1)) KB)" -ForegroundColor Green
}
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. Start the game, load the save, connect as usual." -ForegroundColor Cyan
Write-Host "Check UE4SS.log for: $mainHead" -ForegroundColor Cyan
Write-Host "In-game: F9 claims items. UE4SS console (Home): panic <Item Name>, apdebug <Item Name>, apdump"
if ($Host.Name -eq "ConsoleHost") { Read-Host "Press Enter to close" | Out-Null }
