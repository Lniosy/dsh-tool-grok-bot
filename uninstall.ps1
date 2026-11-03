<#
  从本机 DeepSeek Harness 卸下本插件。
  用法：右键「使用 PowerShell 运行」，或  .\uninstall.ps1
  只卸一个：$env:DSH_PROFILE = "web"
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pluginName = 'dsh-tool-grok-bot'
$dshRoot = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$destDir = Join-Path $dshRoot "plugins\$pluginName"

function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "    [X] $Msg" -ForegroundColor Red }

function Get-ProfileDirs {
    param([string]$ProfilesRoot)
    if (-not (Test-Path $ProfilesRoot)) { return @() }
    if ($env:DSH_PROFILE) {
        $candidate = Join-Path $ProfilesRoot $env:DSH_PROFILE
        if (Test-Path (Join-Path $candidate 'package.json')) { return @($candidate) }
        Write-Err "DSH_PROFILE=$env:DSH_PROFILE 下面没有 package.json：$candidate"
        exit 1
    }
    $dirs = @(Get-ChildItem -LiteralPath $ProfilesRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'package.json') })
    return @($dirs | ForEach-Object { $_.FullName })
}

$seen = @'
const fs = require("fs");
const [pkgPath, name] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
const deps = pkg.dependencies || {};
const bundles = (pkg.dsh && pkg.dsh.profile && pkg.dsh.profile.bundles) || [];
process.stdout.write(deps[name] !== undefined || (Array.isArray(bundles) && bundles.includes(name)) ? "1" : "0");
'@

$remove = @'
const fs = require("fs");
const [pkgPath, name] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
let changed = false;
if (pkg.dependencies && pkg.dependencies[name] !== undefined) {
  delete pkg.dependencies[name];
  changed = true;
}
if (pkg.dsh && pkg.dsh.profile && Array.isArray(pkg.dsh.profile.bundles)) {
  const before = pkg.dsh.profile.bundles.length;
  pkg.dsh.profile.bundles = pkg.dsh.profile.bundles.filter((b) => b !== name);
  if (pkg.dsh.profile.bundles.length !== before) changed = true;
}
if (changed) fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
process.stdout.write(changed ? "1" : "0");
'@

Write-Host "`n接通 Grok Bot 一键卸载" -ForegroundColor Cyan
Write-Step '检查安装'
$profiles = @(Get-ProfileDirs (Join-Path $dshRoot 'profiles'))
$installed = Test-Path $destDir
foreach ($profileDir in $profiles) {
    $pkgPath = Join-Path $profileDir 'package.json'
    $hit = $seen | node - $pkgPath $pluginName
    if ($hit -eq '1') { $installed = $true }
}
if (-not $installed) {
    Write-Warn "没有装过 ${pluginName}，不用卸。"
    try { Read-Host '按回车键退出' } catch { }
    exit 0
}

foreach ($profileDir in $profiles) {
    $pkgPath = Join-Path $profileDir 'package.json'
    $name = Split-Path $profileDir -Leaf
    Write-Step "改配置 $name"
    $bak = "$pkgPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $pkgPath -Destination $bak -Force
    Write-Ok "已备份：$bak"
    $removed = $remove | node - $pkgPath $pluginName
    if ($removed -eq '1') {
        Write-Ok '已从 dependencies 和 bundles 移除'
        Write-Step "pnpm install（$name）"
        Push-Location $profileDir
        try {
            pnpm install
            if ($LASTEXITCODE -ne 0) { Write-Warn "pnpm install 没跑完。可稍后自己执行：cd $profileDir; pnpm install" }
            else { Write-Ok '依赖已清理' }
        } catch {
            Write-Warn "pnpm install 出错：$_"
        } finally {
            Pop-Location
        }
    } else {
        Write-Ok '这份配置里没有本插件'
    }
}

Write-Step '删除插件目录'
$still = $false
$profilesRoot = Join-Path $dshRoot 'profiles'
if (Test-Path $profilesRoot) {
    $all = @(Get-ChildItem -LiteralPath $profilesRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'package.json') })
    foreach ($dir in $all) {
        $hit = $seen | node - (Join-Path $dir.FullName 'package.json') $pluginName
        if ($hit -eq '1') { $still = $true }
    }
}
if ($still) {
    Write-Ok '还有别的 profile 在用，插件目录先留着'
} elseif (Test-Path $destDir) {
    Remove-Item -LiteralPath $destDir -Recurse -Force
    Write-Ok "已删除：$destDir"
} else {
    Write-Warn '插件目录本来就不在'
}

Write-Step '卸载完成'
Write-Host ''
Write-Host '  完全退出 DeepSeek Harness 再打开即可。要装回去，运行 install.ps1' -ForegroundColor Green
Write-Host ''
try { Read-Host '按回车键退出' } catch { }
