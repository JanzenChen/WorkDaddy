#!/usr/bin/env bash
# 在装有 WorkBuddy 的宿主机上派生兼容密钥，供无 Electron 运行时的容器注入使用。
#
# 用法：
#   tools/wd-compat-key.sh [输出文件]
# 默认输出到：
#   macOS: $HOME/Library/Application Support/WorkDaddy/.wb-compat-key（容器内为 /host-config/WorkDaddy/.wb-compat-key）
#   Linux: ${XDG_DATA_HOME:-$HOME/.local/share}/WorkDaddy/.wb-compat-key
#
# 容器侧只需设置 WORKDADDY_WB_KEY_FILE=<容器内路径> 即可，不要用 WORKDADDY_WB_KEY 传明文。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_JS="$SCRIPT_DIR/../scripts/lib.js"

if [[ ! -f "$LIB_JS" ]]; then
  echo "找不到 $LIB_JS" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    DEFAULT_OUT="$HOME/Library/Application Support/WorkDaddy/.wb-compat-key"
    CANDIDATES=(
      "$HOME/Applications/WorkBuddy.app/Contents/MacOS/Electron"
      "$HOME/Applications/WorkBuddy AI.app/Contents/MacOS/Electron"
      "/Applications/WorkBuddy.app/Contents/MacOS/Electron"
      "/Applications/WorkBuddy AI.app/Contents/MacOS/Electron"
    )
    ;;
  *)
    DEFAULT_OUT="${XDG_DATA_HOME:-$HOME/.local/share}/WorkDaddy/.wb-compat-key"
    CANDIDATES=(/opt/WorkBuddy/workbuddy /opt/WorkBuddy/workbuddy-ai)
    ;;
esac

OUT="${1:-$DEFAULT_OUT}"

EXE="${WORKDADDY_WB_EXE:-}"
if [[ -z "$EXE" ]]; then
  for candidate in "${CANDIDATES[@]}"; do
    if [[ -x "$candidate" ]]; then EXE="$candidate"; break; fi
  done
fi
if [[ -z "$EXE" ]]; then
  echo "未找到 WorkBuddy 可执行文件，可用 WORKDADDY_WB_EXE 指定完整路径" >&2
  exit 1
fi

# 密钥只经管道回传，本脚本不打印明文密钥。
KEY_LINE="$(ELECTRON_RUN_AS_NODE=1 "$EXE" "$LIB_JS" --wd-compat-print-key 2>/dev/null | grep -o 'WD_COMPAT_KEY [A-Za-z0-9+/=]*' || true)"
KEY="${KEY_LINE#WD_COMPAT_KEY }"
if [[ -z "$KEY" ]]; then
  echo "派生失败：$EXE 未能返回密钥（WorkBuddy 是否已登录过？）" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
umask 077
printf '%s\n' "$KEY" > "$OUT"
chmod 600 "$OUT"

echo "已写入：$OUT"
echo "容器内路径：/host-config/WorkDaddy/$(basename "$OUT")"
echo "启动参数：-e WORKDADDY_WB_KEY_FILE=/host-config/WorkDaddy/$(basename "$OUT")"
