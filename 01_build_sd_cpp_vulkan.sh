#!/bin/bash
# Build stable-diffusion.cpp with Vulkan backend (Ubuntu/Debian)
set -euo pipefail

SD_DIR="$HOME/stable-diffusion.cpp"
BUILD_TYPE="Release"
JOBS=$(nproc)

echo "======================================"
echo " stable-diffusion.cpp  Vulkan Build"
echo "======================================"

# ---------- dependencies ----------
echo "[1/4] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
    cmake \
    git \
    build-essential \
    pkg-config \
    python3-pip \
    libvulkan-dev \
    vulkan-tools \
    spirv-tools \
    glslang-tools \
    libshaderc-dev

# Install Vulkan SDK from LunarG if libvulkan-dev is too old (optional)
# curl -1sLf https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo gpg --dearmor -o /usr/share/keyrings/lunarg-archive-keyring.gpg
# echo "deb [signed-by=/usr/share/keyrings/lunarg-archive-keyring.gpg] https://packages.lunarg.com/vulkan jammy main" | sudo tee /etc/apt/sources.list.d/lunarg-vulkan.list
# sudo apt-get update && sudo apt-get install -y vulkan-sdk

echo "[2/4] Fetching stable-diffusion.cpp (latest master required for Wan 5D tensor support)..."
if [ -d "$SD_DIR/.git" ]; then
    echo "  → Existing repo found, pulling latest..."
    git -C "$SD_DIR" pull --ff-only
    git -C "$SD_DIR" submodule update --init --recursive
else
    git clone --recursive https://github.com/leejet/stable-diffusion.cpp "$SD_DIR"
fi

echo "[3/4] Configuring with CMake (Vulkan ON)..."
cmake -S "$SD_DIR" -B "$SD_DIR/build" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DGGML_VULKAN=ON

echo "[4/4] Compiling with $JOBS threads..."
cmake --build "$SD_DIR/build" --config "$BUILD_TYPE" -j"$JOBS"

echo ""
echo "======================================"
echo " Build complete!"
echo " Binary : $SD_DIR/build/bin/sd-cli"
echo "======================================"

# Verify Vulkan device is visible
echo ""
echo "[INFO] Vulkan devices detected:"
vulkaninfo --summary 2>/dev/null | grep -E "GPU|deviceName|apiVersion" || echo "  (run 'vulkaninfo' for full details)"
