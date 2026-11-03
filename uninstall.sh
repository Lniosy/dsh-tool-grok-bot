#!/usr/bin/env bash
# 从本机 DeepSeek Harness 卸下本插件。
# 用法：./uninstall.sh
# 只卸一个：DSH_PROFILE=web ./uninstall.sh
set -euo pipefail

PLUGIN_NAME="dsh-tool-grok-bot"
DSH_ROOT="${DSH_HOME:-$HOME/.dsh}"
DEST_DIR="$DSH_ROOT/plugins/$PLUGIN_NAME"

step() { printf "\n==> %s\n" "$1"; }
ok()   { printf "    [OK] %s\n" "$1"; }
warn() { printf "    [!] %s\n" "$1"; }
err()  { printf "    [X] %s\n" "$1" >&2; }

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

step "检查安装"
if [[ -n "${DSH_PROFILE:-}" && ! -f "$DSH_ROOT/profiles/$DSH_PROFILE/package.json" ]]; then
  err "DSH_PROFILE=$DSH_PROFILE 下面没有 package.json：$DSH_ROOT/profiles/$DSH_PROFILE"
  exit 1
fi
profiles=()
if [[ -d "$DSH_ROOT/profiles" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && profiles+=("$line")
  done < <(list_profiles "$DSH_ROOT/profiles")
fi

changed_any=0
if [[ ${#profiles[@]} -gt 0 ]]; then
for PROFILE_DIR in "${profiles[@]}"; do
  PKG_PATH="$PROFILE_DIR/package.json"
  hit=$(node - "$PKG_PATH" "$PLUGIN_NAME" <<'NODE'
const fs = require("fs");
const [pkgPath, name] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
const deps = pkg.dependencies || {};
const bundles = (pkg.dsh && pkg.dsh.profile && pkg.dsh.profile.bundles) || [];
process.stdout.write(deps[name] !== undefined || bundles.includes(name) ? "1" : "0");
NODE
)
  if [[ "$hit" == "1" ]]; then changed_any=1; fi
done
fi
if [[ "$changed_any" -eq 0 && ! -d "$DEST_DIR" ]]; then
  warn "没有装过 ${PLUGIN_NAME}，不用卸。"
  exit 0
fi

if [[ ${#profiles[@]} -gt 0 ]]; then
for PROFILE_DIR in "${profiles[@]}"; do
  PKG_PATH="$PROFILE_DIR/package.json"
  step "改配置 $(basename "$PROFILE_DIR")"
  bak="$PKG_PATH.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$PKG_PATH" "$bak"
  ok "已备份：$bak"
  removed=$(node - "$PKG_PATH" "$PLUGIN_NAME" <<'NODE'
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
NODE
)
  if [[ "$removed" == "1" ]]; then
    ok "已从 dependencies 和 bundles 移除"
    step "pnpm install（$(basename "$PROFILE_DIR")）"
    if (cd "$PROFILE_DIR" && pnpm install); then
      ok "依赖已清理"
    else
      warn "pnpm install 没跑完。可稍后自己执行：cd $PROFILE_DIR && pnpm install"
    fi
  else
    ok "这份配置里没有本插件"
  fi
done
fi

step "删除插件目录"
still_used=0
if [[ -d "$DSH_ROOT/profiles" ]]; then
  for d in "$DSH_ROOT/profiles"/*/; do
    [[ -f "$d/package.json" ]] || continue
    hit=$(node - "${d%/}/package.json" "$PLUGIN_NAME" <<'NODE'
const fs = require("fs");
const [pkgPath, name] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
const deps = pkg.dependencies || {};
const bundles = (pkg.dsh && pkg.dsh.profile && pkg.dsh.profile.bundles) || [];
process.stdout.write(deps[name] !== undefined || bundles.includes(name) ? "1" : "0");
NODE
)
    if [[ "$hit" == "1" ]]; then still_used=1; fi
  done
fi
if [[ "$still_used" -eq 1 ]]; then
  ok "还有别的 profile 在用，插件目录先留着"
elif [[ -d "$DEST_DIR" ]]; then
  rm -rf "$DEST_DIR"
  ok "已删除：$DEST_DIR"
else
  warn "插件目录本来就不在"
fi

step "卸载完成"
printf "\n  完全退出 DeepSeek Harness 再打开即可。要装回去，运行 ./install.sh\n"
