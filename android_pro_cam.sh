#!/bin/bash

# Android Webcam Ultimate v12.0
# (Interactive, Full Control, Strict Mono Mic, Pure Scrcpy, Auto-Reconnect)

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
        sudo modprobe -r v4l2loopback
    fi
    
    echo -e "${GREEN}✓ Her şey temizlendi. Görüşmek üzere!${NC}"
}
trap cleanup EXIT

# --- BAŞLANGIÇ ---
clear
echo -e "${GREEN}=== Android Webcam Ultimate (v12.0) ===${NC}"
echo -e "Saf Scrcpy Akışı, Mono Ses Sabitleyici ve Kopma Koruması.\n"

# 0. ÇALIŞMA MODU SEÇİMİ
echo -e "${YELLOW}[0] Çalışma Modunu Seçin:${NC}"
echo "1) Sadece Mikrofon"
echo "2) Sadece Kamera"
echo "3) Kamera + Mikrofon (İkisi Birden) - VARSAYILAN"
read -p "Seçim (1-3) [Varsayılan: 3]: " mode_choice
mode_choice=${mode_choice:-3}

# --- VİDEO AYARLARI (Mod 2 ve 3 için) ---
if [[ "$mode_choice" == "2" || "$mode_choice" == "3" ]]; then
    echo -e "\n${YELLOW}[VİDEO] Video Sürücüsü Hazırlanıyor...${NC}"
    sudo modprobe -r v4l2loopback > /dev/null 2>&1
    sudo modprobe v4l2loopback exclusive_caps=1 card_label="AndroidCam" video_nr=10 max_buffers=2
    if [ ! -e /dev/video10 ]; then
        echo -e "${RED}Hata: /dev/video10 oluşturulamadı.${NC}"; exit 1
    fi

    echo -e "\n${YELLOW}[VİDEO] Hangi kamerayı kullanacaksın?${NC}"
    echo "1) Arka Kamera (Genel kullanım)"
    echo "2) Ön Kamera (Selfie/Yüz) - VARSAYILAN"
    read -p "Seçim (1-2) [Varsayılan: 2]: " cam_choice
    cam_choice=${cam_choice:-2}
    if [ "$cam_choice" == "2" ]; then CAM_ID=1; else CAM_ID=0; fi

    echo -e "\n${YELLOW}[VİDEO] Çözünürlük Seçimi:${NC}"
    echo "1) 1920x1080 (Full HD)"
    echo "2) 1280x720  (HD) - VARSAYILAN"
    echo "3) 800x600   (Düşük)"
    read -p "Seçim (1-3) [Varsayılan: 2]: " res_choice
    res_choice=${res_choice:-2}
    case $res_choice in
        1) MAX_SIZE=1920 ;;
        2) MAX_SIZE=1280 ;;
        3) MAX_SIZE=800 ;;
        *) MAX_SIZE=1280 ;;
    esac

    echo -e "\n${YELLOW}[VİDEO] FPS Seçimi:${NC}"
    echo "1) 30 FPS (Standart) - VARSAYILAN"
    echo "2) 60 FPS (Akıcı)"
    read -p "Seçim (1-2) [Varsayılan: 1]: " fps_choice
    fps_choice=${fps_choice:-1}
    if [ "$fps_choice" == "2" ]; then MAX_FPS=60; else MAX_FPS=30; fi

    echo -e "\n${YELLOW}[VİDEO] Bitrate Seçimi:${NC}"
    echo "1) 2 Mbps (Düşük gecikme, zayıf Wi-Fi)"
    echo "2) 4 Mbps (Dengeli Standart) - VARSAYILAN"
    echo "3) 8 Mbps (Yüksek Kalite)"
    echo "4) Limitsiz (Scrcpy varsayılanı)"
    read -p "Seçim (1-4) [Varsayılan: 2]: " bitrate_input
    bitrate_input=${bitrate_input:-2}
    case $bitrate_input in
        1) BITRATE_PARAM="-b 2M" ;;
        2) BITRATE_PARAM="-b 4M" ;;
        3) BITRATE_PARAM="-b 8M" ;;
        4) BITRATE_PARAM="" ;;
        *) BITRATE_PARAM="-b 4M" ;;
    esac

    echo -e "\n${YELLOW}[VİDEO] Döndürme Açısı:${NC}"
    echo "0) @0   -> YATAY(İÇ KAMERA SOLDA KALACAK ŞEKİLDE) - VARSAYILAN"
    echo "1) @90  -> TERS DİKEY"
    echo "2) @180 -> TERS YATAY"
    echo "3) @270 -> DİKEY"
    read -p "Açı Seçimi (0-3) [Varsayılan: 0]: " rot_input
    rot_input=${rot_input:-0}
    case $rot_input in
        0) ORIENTATION="@0" ;;
        1) ORIENTATION="@90" ;;
        2) ORIENTATION="@180" ;;
        3) ORIENTATION="@270" ;;
        *) ORIENTATION="@270" ;;
    esac
fi

# --- SES AYARLARI (Mod 1 ve 3 için) ---
if [[ "$mode_choice" == "1" || "$mode_choice" == "3" ]]; then
    echo -e "\n${YELLOW}[SES] Ses Girişi (Mono Sabitlenmiş Mikrofon) Oluşturuluyor...${NC}"
    SINK_NAME="Android_Raw_Sink"
    pactl load-module module-null-sink sink_name=$SINK_NAME format=s16le rate=48000 channels=1 sink_properties=device.description="Android_Raw_Input" > /dev/null
    SOURCE_NAME="Android_Mic_Final"
    pactl load-module module-remap-source master=$SINK_NAME.monitor source_name=$SOURCE_NAME channels=1 source_properties=device.description="Android_Microphone" > /dev/null
    echo -e "${GREEN}✓ 'Android_Microphone' hazır!${NC}"
fi

# --- ARGÜMANLARI HAZIRLA ---
SCRCPY_ARGS=""
if [[ "$mode_choice" == "2" || "$mode_choice" == "3" ]]; then
    SCRCPY_ARGS="$SCRCPY_ARGS --video-source=camera --camera-id=$CAM_ID --v4l2-sink=/dev/video10 --max-size=$MAX_SIZE --max-fps=$MAX_FPS --capture-orientation=$ORIENTATION $BITRATE_PARAM"
else
    SCRCPY_ARGS="$SCRCPY_ARGS --no-video"
fi

if [[ "$mode_choice" == "1" || "$mode_choice" == "3" ]]; then
    SCRCPY_ARGS="$SCRCPY_ARGS --audio-source=mic"
    export PULSE_SINK=$SINK_NAME
else
    SCRCPY_ARGS="$SCRCPY_ARGS --no-audio"
fi

# --- ÇALIŞTIRMA ---
clear
echo -e "${GREEN}=== YAYIN BAŞLIYOR ===${NC}"
if [[ "$mode_choice" == "2" || "$mode_choice" == "3" ]]; then
    echo -e "Kamera:  /dev/video10 (AndroidCam) - $ORIENTATION"
    echo -e "Kalite:  ${MAX_SIZE}p / ${MAX_FPS}fps"
    echo -e "Bitrate: ${BITRATE_PARAM:-(Limitsiz)}"
fi
if [[ "$mode_choice" == "1" || "$mode_choice" == "3" ]]; then
    echo -e "Mikrofon: Android_Microphone (Mono Sabit)"
fi
echo "----------------------------------------------"
echo "Kapatmak için Ctrl+C'ye bas..."

# --- HATA TOLERANSLI ÇALIŞTIRMA DÖNGÜSÜ ---
while true; do
    # Scrcpy'i çalıştır
    scrcpy $SCRCPY_ARGS --no-window
    
    # Çıkış kodunu (Exit Code) al
    EXIT_CODE=$?
    
    # Kullanıcı Ctrl+C ile bilerek kapattıysa (130) veya normal çıkış (0) yaptıysa döngüden çık
    if [ $EXIT_CODE -eq 130 ] || [ $EXIT_CODE -eq 0 ]; then
        break
    fi

    # Eğer Yüz Tanıma kamerayı alırsa veya kablo anlık koparsa burası çalışır:
    echo -e "${YELLOW}[!] Android kameraya el koydu (Yüz Tanıma vb.) veya bağlantı koptu.${NC}"
    echo -e "${CYAN}2 saniye içinde geri bağlanıyor...${NC}"
    
    # 2 saniye bekle ve scrcpy'i tekrar tetikle
    sleep 2
done
