#!/bin/bash
# Generate video with Wan2.1 I2V 14B 480p (Q8_0) — Vulkan
# Optimized for 16 GB VRAM: VAE on CPU, 33 frames at 480x832
set -euo pipefail

# ====== USER CONFIG ======
SD_BIN="$HOME/stable-diffusion.cpp/build/bin/sd"
MODEL_DIR="$HOME/models/wan21_i2v_480p"

INPUT_IMAGE="${1:-input.jpg}"          # arg 1: input image path
PROMPT="${2:-A cinematic scene, smooth camera motion, high quality}"
NEG_PROMPT="blurry, distorted, ugly, low quality, artifacts"

WIDTH=480
HEIGHT=832
FRAMES=33                              # 33 frames ≈ 2s at 16fps; lower to 17 if OOM
STEPS=30
CFG_SCALE=7.0
SEED=-1                                # -1 = random
FPS=16
VK_DEVICE=0                            # Vulkan GPU index (0 = first GPU)

OUTPUT_DIR="$HOME/sd-outputs/wan21_480p"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="$OUTPUT_DIR/output_${TIMESTAMP}.mp4"
# =========================

mkdir -p "$OUTPUT_DIR"

# Resolve model files (pick first .gguf found in each subdirectory)
MAIN_MODEL=$(find "$MODEL_DIR/main"        -name "*.gguf" | sort | head -1)
T5_MODEL=$(find   "$MODEL_DIR/t5xxl"       -name "*.gguf" | sort | head -1)
CLIP_VIS=$(find   "$MODEL_DIR/clip_vision" -name "*.gguf" | sort | head -1)
VAE_MODEL=$(find  "$MODEL_DIR/vae"         -name "*.gguf" | sort | head -1)

echo "======================================"
echo " Wan2.1 I2V 14B 480p — Vulkan"
echo "======================================"
echo " Input image  : $INPUT_IMAGE"
echo " Prompt       : $PROMPT"
echo " Resolution   : ${WIDTH}x${HEIGHT}  Frames: $FRAMES  FPS: $FPS"
echo " Steps        : $STEPS   CFG: $CFG_SCALE   Seed: $SEED"
echo " Main model   : $MAIN_MODEL"
echo " T5 encoder   : $T5_MODEL"
echo " CLIP-Vision  : $CLIP_VIS"
echo " VAE          : $VAE_MODEL"
echo " Output       : $OUTPUT"
echo "======================================"

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "ERROR: Input image not found: $INPUT_IMAGE"
    echo "Usage: $0 <input_image.jpg> [\"prompt\"]"
    exit 1
fi

"$SD_BIN" \
    --model          "$MAIN_MODEL" \
    --t5xxl          "$T5_MODEL" \
    --clip-l-vision  "$CLIP_VIS" \
    --vae            "$VAE_MODEL" \
    --vae-on-cpu \
    --init-img       "$INPUT_IMAGE" \
    --prompt         "$PROMPT" \
    --negative-prompt "$NEG_PROMPT" \
    -W $WIDTH \
    -H $HEIGHT \
    --video-frames   $FRAMES \
    --fps            $FPS \
    --steps          $STEPS \
    --cfg-scale      $CFG_SCALE \
    --seed           $SEED \
    --vk-device      $VK_DEVICE \
    --output         "$OUTPUT"

echo ""
echo "Done! Output saved to: $OUTPUT"
