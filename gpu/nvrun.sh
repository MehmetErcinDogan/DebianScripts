#!/bin/bash -x
# Evrensel NVIDIA PRIME/VA-API çalıştırma betiği
# Bu betik, hem 3D (PRIME Offload) hem de VA-API video decode (NVIDIA NVDEC) için zorlama yapar.

# Video Kod Çözme (VA-API/NVDEC) zorlaması
export LIBVA_DRIVER_NAME=nvidia

# Genel 3D/GLX/Vulkan render offload zorlaması
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# Çalıştırılacak uygulamayı başlat
exec "$@" #>/dev/null 2>&1 &
