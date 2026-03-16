#!/bin/bash
# ============================================================
#  PyAudioTest 开发环境一键安装脚本
#  适用系统: macOS (Tahoe / Sequoia / Sonoma 等)
#  用法: 打开终端 → cd 到此文件所在目录 → bash setup_audio_dev.sh
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo "========================================"
echo "  PyAudioTest 开发环境安装"
echo "  Python 3 + VS Code + 音频开发库"
echo "========================================"
echo ""

# ----------------------------------------------------------
# 1. Xcode Command Line Tools (很多东西的前置依赖)
# ----------------------------------------------------------
if xcode-select -p &>/dev/null; then
    info "Xcode Command Line Tools 已安装"
else
    warn "正在安装 Xcode Command Line Tools (可能会弹窗,点击\"安装\")"
    xcode-select --install
    echo "    安装完成后请重新运行此脚本"
    exit 0
fi

# ----------------------------------------------------------
# 2. Homebrew
# ----------------------------------------------------------
if command -v brew &>/dev/null; then
    info "Homebrew 已安装: $(brew --version | head -1)"
else
    warn "正在安装 Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon 的 brew 路径需要加到 PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    info "Homebrew 安装完成"
fi

# ----------------------------------------------------------
# 3. Python 3
# ----------------------------------------------------------
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    info "Python 已安装: $PY_VER"
else
    warn "正在通过 Homebrew 安装 Python 3 ..."
    brew install python
    info "Python 安装完成: $(python3 --version)"
fi

# 确保 pip 可用
python3 -m pip --version &>/dev/null || python3 -m ensurepip --upgrade

# ----------------------------------------------------------
# 4. 创建项目虚拟环境 (推荐隔离依赖,不污染系统)
# ----------------------------------------------------------
PROJECT_DIR="$HOME/PyAudioTest"
VENV_DIR="$PROJECT_DIR/.venv"

mkdir -p "$PROJECT_DIR"

if [[ -d "$VENV_DIR" ]]; then
    info "虚拟环境已存在: $VENV_DIR"
else
    warn "正在创建虚拟环境 ..."
    python3 -m venv "$VENV_DIR"
    info "虚拟环境创建完成: $VENV_DIR"
fi

# 激活虚拟环境
source "$VENV_DIR/bin/activate"
info "虚拟环境已激活"

# ----------------------------------------------------------
# 5. 安装 Python 依赖库
# ----------------------------------------------------------
warn "正在安装 Python 依赖库 ..."

pip install --upgrade pip

pip install \
    numpy \
    scipy \
    sounddevice \
    soundfile \
    matplotlib \
    openpyxl \
    pyserial

info "Python 依赖库安装完成"

# 验证关键库
echo ""
echo "--- 验证已安装的库 ---"
python3 -c "
import numpy; print(f'  numpy       {numpy.__version__}')
import scipy; print(f'  scipy       {scipy.__version__}')
import sounddevice; print(f'  sounddevice {sounddevice.__version__}')
import soundfile; print(f'  soundfile   {soundfile.__version__}')
import matplotlib; print(f'  matplotlib  {matplotlib.__version__}')
import openpyxl; print(f'  openpyxl    {openpyxl.__version__}')
import serial; print(f'  pyserial    {serial.__version__}')
"
echo ""

# ----------------------------------------------------------
# 6. VS Code
# ----------------------------------------------------------
if command -v code &>/dev/null; then
    info "VS Code 已安装"
else
    warn "正在通过 Homebrew 安装 VS Code ..."
    brew install --cask visual-studio-code
    info "VS Code 安装完成"
fi

# 安装 VS Code Python 扩展
if command -v code &>/dev/null; then
    warn "正在安装 VS Code Python 扩展 ..."
    code --install-extension ms-python.python          2>/dev/null || true
    code --install-extension ms-python.debugpy         2>/dev/null || true
    info "VS Code 扩展安装完成"
fi

# ----------------------------------------------------------
# 7. 创建 VS Code 工作区配置 (自动识别虚拟环境)
# ----------------------------------------------------------
VSCODE_DIR="$PROJECT_DIR/.vscode"
mkdir -p "$VSCODE_DIR"

cat > "$VSCODE_DIR/settings.json" << 'EOF'
{
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
    "python.terminal.activateEnvironment": true,
    "editor.fontSize": 14,
    "editor.tabSize": 4,
    "files.encoding": "utf8"
}
EOF
info "VS Code 工作区配置已生成"

# ----------------------------------------------------------
# 8. 生成一个验证脚本,确认硬件能否被识别
# ----------------------------------------------------------
cat > "$PROJECT_DIR/check_hardware.py" << 'PYEOF'
"""
硬件检测脚本 - 运行此脚本确认声卡和串口是否能被 macOS 识别
用法: python check_hardware.py
"""
import sys

print("=" * 50)
print("  PyAudioTest 硬件检测")
print("=" * 50)
print()

# --- 1. 检测音频设备 ---
print("【音频设备】")
try:
    import sounddevice as sd
    devices = sd.query_devices()
    print(f"  找到 {len(devices)} 个音频设备:\n")
    for i, d in enumerate(devices):
        tag = ""
        if d['max_input_channels'] > 0 and d['max_output_channels'] > 0:
            tag = " [输入+输出]"
        elif d['max_input_channels'] > 0:
            tag = " [输入]"
        elif d['max_output_channels'] > 0:
            tag = " [输出]"
        print(f"  [{i}] {d['name']}{tag}")
        print(f"      输入通道: {d['max_input_channels']}, 输出通道: {d['max_output_channels']}")
        print(f"      默认采样率: {d['default_samplerate']}")
        print()

    # 检查有没有 RSAudio 或类似设备
    rs_found = [d for d in devices if 'RSAudio' in d['name'] or 'RS Audio' in d['name']]
    if rs_found:
        print(f"  ✓ 检测到 RSAudio 设备!")
    else:
        print("  ✗ 未检测到 RSAudio 设备")
        print("    → 请确认声卡已连接并安装了 macOS 驱动")

except Exception as e:
    print(f"  ✗ 音频设备检测失败: {e}")

print()

# --- 2. 检测串口设备 (蓝牙模块) ---
print("【串口设备 (蓝牙模块)】")
try:
    import serial.tools.list_ports
    ports = list(serial.tools.list_ports.comports())
    if ports:
        print(f"  找到 {len(ports)} 个串口设备:\n")
        for p in ports:
            print(f"  {p.device}")
            print(f"      描述: {p.description}")
            print(f"      厂商: {p.manufacturer or '未知'}")
            print()

        prolific = [p for p in ports if p.vid == 0x067B]  # Prolific VID
        if prolific:
            print(f"  ✓ 检测到 Prolific USB-Serial (蓝牙模块)")
        else:
            print("  ? 未检测到 Prolific 设备, 请确认蓝牙模块已连接")
    else:
        print("  ✗ 未检测到任何串口设备")
        print("    → 蓝牙模块未连接或需要安装 Prolific 驱动")

except Exception as e:
    print(f"  ✗ 串口检测失败: {e}")

print()

# --- 3. 简单的回环测试提示 ---
print("【下一步】")
print("  如果上面能看到 RSAudio 设备, 运行以下命令做一个简单的录音测试:")
print()
print('  python -c "')
print('  import sounddevice as sd')
print('  import numpy as np')
print("  # 录制1秒看看有没有信号")
print('  rec = sd.rec(48000, samplerate=48000, channels=2, dtype="float32")')
print('  sd.wait()')
print('  peak = 20 * np.log10(np.max(np.abs(rec)) + 1e-10)')
print(f'  print(f"峰值电平: {{peak:.1f}} dBFS")')
print('  "')
print()
print("=" * 50)
PYEOF

info "硬件检测脚本已生成: $PROJECT_DIR/check_hardware.py"

# ----------------------------------------------------------
# 完成
# ----------------------------------------------------------
echo ""
echo "========================================"
echo -e "${GREEN}  安装全部完成!${NC}"
echo "========================================"
echo ""
echo "  项目目录:  $PROJECT_DIR"
echo "  虚拟环境:  $VENV_DIR"
echo ""
echo "  接下来:"
echo "  1. 打开 VS Code:"
echo "     code $PROJECT_DIR"
echo ""
echo "  2. 插上声卡和蓝牙模块, 运行硬件检测:"
echo "     cd $PROJECT_DIR"
echo "     source .venv/bin/activate"
echo "     python check_hardware.py"
echo ""
echo "  3. 如果硬件能识别, 告诉我结果, 我们继续写测试代码"
echo ""
