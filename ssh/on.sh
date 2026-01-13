# Bu script termux olan telefonlarda ssh ayarları yapıldıktan sonra,
# adb'nin kendi bağlantısının stabil olmadığı durumlarda ssh üzerinden adb bağlantısını kurar.
adb devices
sleep 2

echo "Checking ADB connection"
# Cihaz sayısını kontrol et
ADB_DEVICES=$(adb devices | grep -w "device" | wc -l)

# IP'yi bir değişkene atamayı dene
DETECTED_IP=$(adb shell ifconfig | grep "inet addr:192." | awk '{print $2}' | cut -d: -f2 | head -n 1)

# IP Bulundu mu kontrol et
if [ -z "$DETECTED_IP" ]; then
    # DURUM 1: IP Bulunamadı
    echo "Otomatik IP bulunamadı."
    read -p "Lütfen bağlanmak istediğiniz IP adresini girin: " ip_addr
else
    # DURUM 2: IP Bulundu
    echo "Bulunan IP: $DETECTED_IP"
    read -p "Bu IP kullanılsın mı? (Evet için Enter'a basın, farklı bir IP girmek için IP'yi yazın): " user_input
    
    # Kullanıcı bir şey yazmazsa (Enter) bulunan IP'yi kullan, yazarsa yeni IP'yi kullan
    if [ -z "$user_input" ]; then
        ip_addr=$DETECTED_IP
    else
        ip_addr=$user_input
    fi
fi

echo "Hedef IP: $ip_addr"

adb tcpip 5555
# SSH tüneli (Arka planda çalışması için & işareti var, gerekirse -f parametresi de eklenebilir)
# Username ve  port kısmını kendi verileriniz ile değiştirin.
ssh -N -L 5555:localhost:5555 -p {port} {UserName}@$ip_addr &


adb kill-server
sleep 2
adb devices
