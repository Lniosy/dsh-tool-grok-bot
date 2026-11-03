<#
  把本插件装进本机 DeepSeek Harness。
  用法：右键「使用 PowerShell 运行」，或  .\install.ps1
  只装一个：$env:DSH_PROFILE = "web"   或  "default"
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pluginName = 'dsh-tool-grok-bot'
$dshRoot = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$pluginsDir = Join-Path $dshRoot 'plugins'
$destDir = Join-Path $pluginsDir $pluginName
$srcDir = $PSScriptRoot

function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "    [X] $Msg" -ForegroundColor Red }

function Get-ProfileDirs {
    param([string]$ProfilesRoot)
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

Write-Host "`n接通 Grok Bot 一键安装" -ForegroundColor Cyan
Write-Step '检查环境'
if (-not (Test-Path $dshRoot)) {
    Write-Err "未找到 DSH 目录：$dshRoot"
    exit 1
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Err '未检测到 node'; exit 1 }
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Err '未检测到 pnpm。先执行：npm install -g pnpm'
    exit 1
}
Write-Ok "DSH 目录：$dshRoot"

$profiles = @(Get-ProfileDirs (Join-Path $dshRoot 'profiles'))
if ($profiles.Count -eq 0) {
    Write-Err '未找到 profile。请先打开过 DeepSeek Harness，或设置 DSH_PROFILE=web / default。'
    exit 1
}

Write-Step '复制插件'
if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null }
if ($srcDir -eq $destDir) {
    Write-Ok '脚本就在插件目录里，跳过复制'
} else {
    if (Test-Path $destDir) { Remove-Item -LiteralPath $destDir -Recurse -Force }
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    robocopy $srcDir $destDir /E /NFL /NDL /NJH /NJS /NC /NS `
        /XD .git node_modules `
        /XF install.ps1 uninstall.ps1 install.sh uninstall.sh | Out-Null
    if ($LASTEXITCODE -ge 8) {
        Write-Err "复制失败（robocopy 退出码 $LASTEXITCODE）"
        exit 1
    }
    $global:LASTEXITCODE = 0
    Write-Ok "已复制到：$destDir"
}

$patch = @'
const fs = require("fs");
const [pkgPath, name] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
pkg.dependencies = pkg.dependencies || {};
pkg.dependencies[name] = "file:../../plugins/" + name;
pkg.dsh = pkg.dsh || {};
pkg.dsh.profile = pkg.dsh.profile || {};
const bundles = Array.isArray(pkg.dsh.profile.bundles) ? pkg.dsh.profile.bundles : [];
if (!bundles.includes(name)) bundles.push(name);
pkg.dsh.profile.bundles = bundles;
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
'@

foreach ($profileDir in $profiles) {
    $pkgPath = Join-Path $profileDir 'package.json'
    $name = Split-Path $profileDir -Leaf
    Write-Step "写入 $name"
    $bak = "$pkgPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $pkgPath -Destination $bak -Force
    Write-Ok "已备份：$bak"
    $patch | node - $pkgPath $pluginName
    if ($LASTEXITCODE -ne 0) { Write-Err '写入 package.json 失败'; exit 1 }
    Write-Ok 'dependencies 与 bundles 已写入'

    $nm = Join-Path $profileDir "node_modules\$pluginName"
    if (Test-Path $nm) {
        Remove-Item -LiteralPath $nm -Recurse -Force
        Write-Ok '已去掉 node_modules 里的旧拷贝'
    }

    Write-Step "pnpm install（$name）"
    Push-Location $profileDir
    try {
        pnpm install
        if ($LASTEXITCODE -ne 0) { Write-Err "pnpm install 失败。可手动：cd $profileDir; pnpm install"; exit 1 }
        Write-Ok '依赖安装完成'
    } finally {
        Pop-Location
    }
}

try {
    $exe = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek-Harness\DeepSeek Harness.exe'
    $regPath = 'HKCU:\Software\Classes\dsh'
    if ((Test-Path $exe) -and -not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name '(default)' -Value 'DeepSeek Harness Protocol'
        Set-ItemProperty -Path $regPath -Name 'URL Protocol' -Value ''
        $cmdPath = Join-Path $regPath 'shell\open\command'
        New-Item -Path $cmdPath -Force | Out-Null
        Set-ItemProperty -Path $cmdPath -Name '(default)' -Value "`"$exe`" `"%1`""
        Write-Ok '已注册 dsh:// ，之后可以点 README 里的安装按钮'
    }
} catch { }

Write-Step '安装完成'
Write-Host ''
Write-Host '  插件已安装。' -ForegroundColor Green
Write-Host '  最后一步：完全退出 DeepSeek Harness 再打开。Web 版刷新页面。'
Write-Host '  确认：新会话调用 grok_bot_status，能看到登录状态和 Bot 数量。'
Write-Host '  卸载：运行 uninstall.ps1'
Write-Host ''
try { Read-Host '按回车键退出' } catch { }
