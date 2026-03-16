#!/bin/bash
# ============================================================
#  macOS 开发环境一键安装
#  Homebrew + Python 3 + VS Code
#  用法: 打开终端 → bash setup.sh
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[...]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }
progress(){ echo -e "${CYAN}    ➜ $1${NC}"; }

TOTAL_STEPS=4
current_step=0
show_step() {
    current_step=$((current_step + 1))
    pct=$((current_step * 100 / TOTAL_STEPS))
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [$current_step/$TOTAL_STEPS] ($pct%)  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo ""
echo "========================================"
echo "  macOS 开发环境安装"
echo "  Homebrew + Python 3 + VS Code"
echo "========================================"

# ----------------------------------------------------------
# 1. 网络检测
# ----------------------------------------------------------
show_step "检测网络连接"

progress "正在测试网络连通性 ..."
if curl -s --connect-timeout 5 https://brew.sh > /dev/null 2>&1; then
    info "网络连接正常"
else
    error "无法访问 brew.sh，请检查网络或代理设置"
    exit 1
fi

# ----------------------------------------------------------
# 2. Xcode Command Line Tools + Homebrew
# ----------------------------------------------------------
show_step "安装 Homebrew"

if ! xcode-select -p &>/dev/null; then
    warn "正在安装 Xcode Command Line Tools (会弹窗,点击\"安装\") ..."
    xcode-select --install
    echo ""
    error "请等待 Xcode CLT 安装完成后,重新运行此脚本"
    exit 0
else
    info "Xcode Command Line Tools 已就绪"
fi

if command -v brew &>/dev/null; then
    info "Homebrew 已安装: $(brew --version | head -1)"
    progress "正在更新 Homebrew ..."
    brew update --quiet
    info "Homebrew 已更新"
else
    warn "正在下载并安装 Homebrew ..."
    progress "这一步可能需要 1-3 分钟,取决于网络速度"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon 路径
    if [[ -f /opt/homebrew/bin/brew ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    info "Homebrew 安装完成"
fi

# ----------------------------------------------------------
# 3. Python 3
# ----------------------------------------------------------
show_step "安装 Python 3"

if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    info "Python 已安装: $PY_VER"
else
    warn "正在通过 Homebrew 安装 Python 3 ..."
    progress "下载中 ..."
    brew install python
    info "Python 安装完成: $(python3 --version)"
fi

progress "验证 pip ..."
python3 -m pip --version &>/dev/null || python3 -m ensurepip --upgrade
info "pip 可用: $(python3 -m pip --version)"

# ----------------------------------------------------------
# 4. VS Code
# ----------------------------------------------------------
show_step "安装 VS Code"

if command -v code &>/dev/null; then
    info "VS Code 已安装"
else
    warn "正在通过 Homebrew 安装 VS Code ..."
    progress "下载中 (约 100MB) ..."
    brew install --cask visual-studio-code
    info "VS Code 安装完成"
fi

progress "安装 Python 扩展 ..."
code --install-extension ms-python.python 2>/dev/null || true
info "Python 扩展已安装"

# ----------------------------------------------------------
# 完成
# ----------------------------------------------------------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  安装全部完成! (100%)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  已安装:"
echo "    • Homebrew  $(brew --version | head -1)"
echo "    • $(python3 --version)"
echo "    • pip       $(python3 -m pip --version 2>&1 | awk '{print $2}')"
echo "    • VS Code"
echo ""
echo -e "${YELLOW}  请打开 VS Code 验证 IDE 是否正常:${NC}"
echo ""
echo "    在终端输入:  code"
echo ""
echo "  VS Code 打开后, 新建一个 .py 文件, 输入:"
echo '    print("Hello Audio")'
echo "  然后右上角点 ▶ 运行, 看到输出即表示环境正常"
echo ""
