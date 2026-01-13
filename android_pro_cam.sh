#!/bin/bash

# Android Webcam Ultimate v9.0
# (Interactive, Full Control, Real Virtual Mic, Bitrate Control)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# --- FONKSİYONLAR ---

cleanup() {
    echo -e "\n${YELLOW}[Temizlik] Sistem temizleniyor...${NC}"
    
    # Sanal Ses Cihazlarını Sil
    if pactl list short modules | grep -q "Android_Mic_Final"; then
        pactl unload-module module-remap-source > /dev/null 2>&1
    fi
    if pactl list short modules | grep -q "Android_Raw_Sink"; then
        pactl unload-module module-null-sink > /dev/null 2>&1
    fi

    # Sanal Kamerayı Sil
    if lsmod | grep -q "v4l2loopback"; then
        sudo modprobe -r v4l2loopback > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}✓ Her şey temizlendi. Görüşmek üzere!${NC}"
}

trap cleanup EXIT

# --- BAŞLANGIÇ ---
clear
echo -e "${GREEN}=== Android Webcam Ultimate (v9.0) ===${NC}"
echo -e "Tam kontrol, bitrate ayarı ve varsayılan destekli.\n"

# 1. V4L2 Modül Kurulumu
echo -e "${YELLOW}[1/7] Video Sürücüsü Hazırlanıyor...${NC}"
sudo modprobe -r v4l2loopback > /dev/null 2>&1
sudo modprobe v4l2loopback exclusive_caps=1 card_label="AndroidCam" video_nr=10 max_buffers=2
if [ ! -e /dev/video10 ]; then
    echo -e "${RED}Hata: /dev/video10 oluşturulamadı.${NC}"; exit 1
fi

# 2. KAMERA SEÇİMİ
echo -e "\n${YELLOW}[2/7] Hangi kamerayı kullanacaksın?${NC}"
echo "1) Arka Kamera (Genel kullanım)"
echo "2) Ön Kamera (Selfie/Yüz) - VARSAYILAN"
read -p "Seçim (1-2) [Varsayılan: 2]: " cam_choice
cam_choice=${cam_choice:-2} # Enter'a basılırsa 2 olur

if [ "$cam_choice" == "2" ]; then CAM_ID=1; else CAM_ID=0; fi

# 3. ÇÖZÜNÜRLÜK SEÇİMİ
echo -e "\n${YELLOW}[3/7] Çözünürlük Seçimi:${NC}"
echo "1) 1920x1080 (Full HD)"
echo "2) 1280x720  (HD) - VARSAYILAN"
echo "3) 800x600   (Düşük)"
read -p "Seçim (1-3) [Varsayılan: 2]: " res_choice
res_choice=${res_choice:-2} # Enter'a basılırsa 2 olur

case $res_choice in
    1) MAX_SIZE=1920 ;;
    2) MAX_SIZE=1280 ;;
    3) MAX_SIZE=800 ;;
    *) MAX_SIZE=1280 ;;
esac

# 4. FPS SEÇİMİ
echo -e "\n${YELLOW}[4/7] FPS (Kare Hızı) Seçimi:${NC}"
echo "1) 30 FPS (Standart) - VARSAYILAN"
echo "2) 60 FPS (Akıcı)"
read -p "Seçim (1-2) [Varsayılan: 1]: " fps_choice
fps_choice=${fps_choice:-1} # Enter'a basılırsa 1 olur

if [ "$fps_choice" == "2" ]; then MAX_FPS=60; else MAX_FPS=30; fi

# 5. BITRATE (KALİTE/AKIŞ) SEÇİMİ - YENİ
echo -e "\n${YELLOW}[5/7] Bitrate (Görüntü Veri Akış Hızı):${NC}"
echo "1) 2 Mbps (Düşük gecikme, zayıf Wi-Fi)"
echo "2) 4 Mbps (Dengeli Standart) - VARSAYILAN"
echo "3) 8 Mbps (Yüksek Kalite)"
echo "4) Limitsiz ( scrcpy varsayılanı, en yüksek kalite ama gecikme olabilir)"
read -p "Seçim (1-4) [Varsayılan: 2]: " bitrate_input
bitrate_input=${bitrate_input:-2} # Enter'a basılırsa 2 olur

case $bitrate_input in
    1) BITRATE_PARAM="-b 2M" ;;
    2) BITRATE_PARAM="-b 4M" ;;
    3) BITRATE_PARAM="-b 8M" ;;
    4) BITRATE_PARAM="" ;; # Parametre göndermiyoruz, scrcpy default'u kullanıyor
    *) BITRATE_PARAM="-b 4M" ;;
esac

# 6. DÖNDÜRME (ROTATION) SEÇİMİ
echo -e "\n${YELLOW}[6/7] Döndürme Açısı:${NC}"
echo "0) @0   -> YATAY (Doğal) - VARSAYILAN"
echo "1) @90  -> DİKEY (Sola Yatık)"
echo "2) @180 -> TERS YATAY"
echo "3) @270 -> DİKEY (Sağa Yatık)"
read -p "Açı Seçimi (0-3) [Varsayılan: 0]: " rot_input
rot_input=${rot_input:-0} # Enter'a basılırsa 0 olur

case $rot_input in
    0) ORIENTATION="@0" ;;
    1) ORIENTATION="@90" ;;
    2) ORIENTATION="@180" ;;
    3) ORIENTATION="@270" ;;
    *) ORIENTATION="@0" ;;
esac

# 7. SES SİSTEMİ KURULUMU
echo -e "\n${YELLOW}[7/7] Ses Girişi (Mikrofon) Oluşturuluyor...${NC}"

SINK_NAME="Android_Raw_Sink"
pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description="Android_Raw_Input" > /dev/null

SOURCE_NAME="Android_Mic_Final"
pactl load-module module-remap-source master=$SINK_NAME.monitor source_name=$SOURCE_NAME source_properties=device.description="Android_Microphone" > /dev/null

echo -e "${GREEN}✓ 'Android_Microphone' hazır!${NC}"

# --- ÇALIŞTIRMA ---
clear
echo -e "${GREEN}=== YAYIN BAŞLIYOR ===${NC}"
echo -e "Kamera:  /dev/video10 ($ORIENTATION)"
echo -e "Mikrofon: Android_Microphone"
echo -e "Kalite:  ${MAX_SIZE}p / ${MAX_FPS}fps"
echo -e "Bitrate: ${BITRATE_PARAM:-(Limitsiz)}"
echo "----------------------------------------------"
echo "Kapatmak için Ctrl+C'ye bas..."

# Bitrate parametresini komuta dahil ediyoruz
PULSE_SINK=$SINK_NAME scrcpy \
    --video-source=camera \
    --camera-id=$CAM_ID \
    --v4l2-sink=/dev/video10 \
    --max-size=$MAX_SIZE \
    --max-fps=$MAX_FPS \
    --capture-orientation=$ORIENTATION \
    $BITRATE_PARAM \
    --audio-source=mic \
    --audio-buffer=50 \
    --no-window
