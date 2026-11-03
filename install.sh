#!/usr/bin/env bash
# 把本插件装进本机 DeepSeek Harness。
# 复制到 ~/.dsh/plugins，备份并改 profile 的 package.json，再 pnpm install。
# 用法：chmod +x install.sh && ./install.sh
# 只装一个：DSH_PROFILE=web ./install.sh    或    DSH_PROFILE=default ./install.sh
# 换数据目录：DSH_HOME=/path/to/.dsh ./install.sh
set -euo pipefail

PLUGIN_NAME="dsh-tool-grok-bot"
DSH_ROOT="${DSH_HOME:-$HOME/.dsh}"
PLUGINS_DIR="$DSH_ROOT/plugins"
DEST_DIR="$PLUGINS_DIR/$PLUGIN_NAME"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf "\n==> %s\n" "$1"; }
ok()   { printf "    [OK] %s\n" "$1"; }
warn() { printf "    [!] %s\n" "$1"; }
err()  { printf "    [X] %s\n" "$1" >&2; }

# 打印要安装的 profile 目录，一行一个。调用前先确认目录存在。
list_profiles() {
  local root="$1" d
  if [[ -n "${DSH_PROFILE:-}" ]]; then
    printf '%s\n' "$root/$DSH_PROFILE"
    return 0
  fi
  for d in "$root"/*/; do
    if [[ -d "$d" && -f "$d/package.json" ]]; then
      printf '%s\n' "${d%/}"
    fi
  done
}

step "检查环境"
[[ -d "$DSH_ROOT" ]] || { err "未找到 DSH 目录：$DSH_ROOT"; exit 1; }
command -v node >/dev/null 2>&1 || { err "未检测到 node"; exit 1; }
command -v pnpm >/dev/null 2>&1 || { err "未检测到 pnpm。先执行：npm install -g pnpm"; exit 1; }
ok "node、pnpm 可用"
ok "DSH 目录：$DSH_ROOT"

if [[ -n "${DSH_PROFILE:-}" && ! -f "$DSH_ROOT/profiles/$DSH_PROFILE/package.json" ]]; then
  err "DSH_PROFILE=$DSH_PROFILE 下面没有 package.json：$DSH_ROOT/profiles/$DSH_PROFILE"
  exit 1
fi
profiles=()
while IFS= read -r line; do
  [[ -n "$line" ]] && profiles+=("$line")
done < <(list_profiles "$DSH_ROOT/profiles")
if [[ ${#profiles[@]} -eq 0 ]]; then
  err "未找到 profile。请先打开过 DeepSeek Harness，或设置 DSH_PROFILE=web / default。"
  exit 1
fi

step "复制插件"
mkdir -p "$PLUGINS_DIR"
if [[ "$SRC_DIR" == "$DEST_DIR" ]]; then
  ok "脚本就在插件目录里，跳过复制"
else
  rm -rf "$DEST_DIR"
  mkdir -p "$DEST_DIR"
  cp -R "$SRC_DIR"/. "$DEST_DIR"/
  rm -rf "$DEST_DIR/.git" "$DEST_DIR/node_modules" \
    "$DEST_DIR/install.sh" "$DEST_DIR/uninstall.sh" \
    "$DEST_DIR/install.ps1" "$DEST_DIR/uninstall.ps1"
  ok "已复制到：$DEST_DIR"
fi

for PROFILE_DIR in "${profiles[@]}"; do
  PKG_PATH="$PROFILE_DIR/package.json"
  step "写入 $(basename "$PROFILE_DIR")"
  bak="$PKG_PATH.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$PKG_PATH" "$bak"
  ok "已备份：$bak"
  node - "$PKG_PATH" "$PLUGIN_NAME" <<'NODE'
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
NODE
  ok "dependencies 与 bundles 已写入"

  nm="$PROFILE_DIR/node_modules/$PLUGIN_NAME"
  if [[ -d "$nm" ]]; then
    rm -rf "$nm"
    ok "已去掉 node_modules 里的旧拷贝"
  fi

  step "pnpm install（$(basename "$PROFILE_DIR")）"
  ( cd "$PROFILE_DIR" && pnpm install )
  ok "依赖安装完成"
done

step "安装完成"
cat <<EOF

  插件已安装。
  最后一步：完全退出 DeepSeek Harness 再打开。Web 版刷新页面。
  确认：新会话调用 grok_bot_status，能看到登录状态和 Bot 数量。
  卸载：./uninstall.sh
EOF
