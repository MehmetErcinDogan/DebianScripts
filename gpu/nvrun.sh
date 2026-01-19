#!/bin/bash
# Evrensel NVIDIA PRIME/VA-API çalıştırma betiği

# 1. Ortam Değişkenlerini Tanımla
export LIBVA_DRIVER_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# 2. Parametre Kontrolü
if [ $# -eq 0 ]; then
    # EĞER parametre yoksa: Ayarların geçerli olduğu yeni bir terminal (shell) başlat.
    echo "NVIDIA Render Offload ortamına giriş yapıldı."
    echo "Bu terminaldeki tüm komutlar NVIDIA üzerinden çalışacak."
    echo "Çıkmak ve normale dönmek için 'exit' yazabilirsin."
    
    # Mevcut kullanıcının varsayılan kabuğunu (bash, zsh vb.) başlat
    exec "$SHELL"
else
    # EĞER parametre varsa: Sadece o komutu çalıştır.
    exec "$@"
fi
