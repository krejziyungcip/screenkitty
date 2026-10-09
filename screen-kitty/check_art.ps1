# Validates that every string literal in KittyFrames.swift is exactly
# 4 characters (all literals in that file are pixel-grid chunks).
$ErrorActionPreference = "Stop"
$path = Join-Path $PSScriptRoot "Packages\KittyKit\Sources\KittyKit\PixelArt\KittyFrames.swift"
$content = Get-Content -Raw $path

$all = [regex]::Matches($content, '"([^"]*)"')
$bad = @()
foreach ($m in $all) {
    $s = $m.Groups[1].Value
    if ($s.Length -ne 4) { $bad += "[$($s.Length)] $s" }
}

Write-Host "string literals checked: $($all.Count)"
if ($bad.Count -eq 0) {
    Write-Host "OK: every literal is exactly 4 chars (rows are guaranteed 16 wide)"
} else {
    Write-Host "BAD LITERALS:"
    $bad | ForEach-Object { Write-Host "  $_" }
    exit 1
}
