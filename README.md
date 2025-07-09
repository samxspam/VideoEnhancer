# 🎬 Video Quality Booster - RIFE + Real-ESRGAN
# Script by samxspam
This script automates the process of:
1. Interpolating videos to 60 FPS using [RIFE](https://github.com/megvii-research/ECCV2022-RIFE)
2. Upscaling using [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN)
3. GPU-based reassembly with NVENC (FFmpeg)

## 💻 How to Use

```bash
chmod +x run_video_upscale.sh
./run_video_upscale.sh
