import json
import sys
import socket  # IP adresini bulmak için eklendi
from pywebostv.discovery import *    # Because I'm lazy, don't do this.
from pywebostv.connection import *
from pywebostv.controls import *

# Bağlantı anahtarlarını saklayacak dosya
BAGLANTI_ANAHTAR_DOSYASI = "~/.scripts/TV/.tv/webos_baglantilari.json"


def get_local_ip_for_target(target_ip):
    """
    Verilen hedef IP'ye (TV'nin IP'si) ulaşmak için 
    kullanılan yerel ağ IP adresini bulur.
    
    Bu, bilgisayarda birden fazla ağ kartı (örn. WiFi ve Ethernet) 
    olsa bile doğru IP'yi bulmayı garanti eder.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # TV'nin IP'sine (herhangi bir porta) bağlanmayı dener gibi yapar
        # Gerçek bir bağlantı kurmaz, sadece yolu belirler
        s.connect((target_ip, 80))
        # İşletim sisteminin bu bağlantı için atadığı yerel IP'yi alır
        local_ip = s.getsockname()[0]
        return local_ip
    except Exception as e:
        print(f"[HATA] TV'ye ({target_ip}) giden yerel IP adresi bulunamadı: {e}", file=sys.stderr)
        print("Bilgisayarınızın ve TV'nizin aynı ağda olduğundan emin olun.", file=sys.stderr)
        return None
    finally:
        s.close()

# --- 1. Adım: Kullanıcıdan Port Numarasını Al ---

port_str = ""
port = 0
while True:
    #port_str = input("TV'nin bağlanmasını istediğiniz PORT numarasını girin (örn: 8000): ")
    try:
        port = 1701
        #port = int(port_str)
        if not (1 <= port <= 65535):
            print("HATA: Port numarası 1 ile 65535 arasında olmalıdır.")
        else:
            break  # Geçerli port alındı, döngüden çık
    except ValueError:
        print("HATA: Lütfen sadece sayısal bir değer girin.")

print(f"Port {port} olarak ayarlandı.\n")


# --- 2. Adım: TV'yi Bul ve IP Adreslerini Çıkar ---

# Kayıtlı anahtarları yükle
store = {}
try:
    with open(BAGLANTI_ANAHTAR_DOSYASI, 'r') as f:
        store = json.load(f)
    print(f"Daha önceden kaydedilmiş {len(store)} adet TV anahtarı yüklendi.")
except FileNotFoundError:
    print(f"'{BAGLANTI_ANAHTAR_DOSYASI}' dosyası bulunamadı. Yeni bir tane oluşturulacak.")
except json.JSONDecodeError:
    print(f"'{BAGLANTI_ANAHTAR_DOSYASI}' dosyasında hata var. Sıfırdan başlanıyor.")

print("\nYerel ağdaki LG webOS TV'ler taranıyor...")
client = None

try:
    # Ağı tara
    found_clients = WebOSClient.discover(secure=True) 

    if not found_clients:
        print("\n[HATA] Ağda herhangi bir LG webOS TV bulunamadı.")
        print("Lütfen kontrol edin:")
        print("1. TV'nizin açık olduğundan emin olun.")
        print("2. Bilgisayarınızın ve TV'nizin aynı yerel ağa (Wi-Fi/kablolu) bağlı olduğundan emin olun.")
        sys.exit(1) # Hata ile çık

    # Bulunan ilk TV'yi seç
    client = found_clients[0]
    TV_IP_ADRESI = client.host
    print(f"\nBaşarılı! TV bulundu. IP Adresi: {TV_IP_ADRESI}")

    # --- 3. Adım: Bilgisayarın IP'sini Bul ve URL'yi Oluştur ---
    
    # TV'nin IP'sini kullanarak bilgisayarın doğru yerel IP'sini bul
    BILGISAYAR_IP = get_local_ip_for_target(TV_IP_ADRESI)
    
    if not BILGISAYAR_IP:
        print("Bilgisayarın yerel IP'si alınamadığı için script durduruluyor.")
        sys.exit(1)
        
    print(f"Bilgisayarınızın yerel IP adresi (TV'nin göreceği): {BILGISAYAR_IP}")
    
    # Hedef URL'yi dinamik olarak oluştur
    ACILACAK_URL = f"http://{BILGISAYAR_IP}:{port}"
    print(f"Oluşturulan Hedef URL: {ACILACAK_URL}")

    # --- 4. Adım: TV'ye Bağlan ve URL'yi Aç ---

    print(f"\n{TV_IP_ADRESI} IP adresli TV'ye bağlanılıyor...")
    client.connect()
    
    # Gerekirse TV'den izin iste (Eşleştirme)
    for status in client.register(store):
        if status == WebOSClient.PROMPTED:
            print("\n*** ÖNEMLİ ***")
            print("Lütfen TV ekranınıza bakın ve 'İzin Ver' (Allow) seçeneğini onaylayın.")
        elif status == WebOSClient.REGISTERED:
            print("TV'ye başarıyla kaydedildi!")
            # Alınan yeni anahtarı dosyaya kaydet
            with open(BAGLANTI_ANAHTAR_DOSYASI, 'w') as f:
                json.dump(store, f)
                print(f"Bağlantı anahtarı '{BAGLANTI_ANAHTAR_DOSYASI}' dosyasına kaydedildi.")

    print("\nTV'ye başarıyla bağlandı.")

    # Sistem kontrolcüsünü oluştur
    system = SystemControl(client)

    # Oluşturduğumuz dinamik URL'yi TV'de aç
    app = ApplicationControl(client)
    apps = app.list_apps()  
    browser = [x for x in apps if "web" in x["title"].lower()][0]
    print(f"'{ACILACAK_URL}' adresi TV'de açılıyor...")
    app.launch(browser, content_id=ACILACAK_URL)
    print("Komut başarıyla gönderildi.")

except Exception as e:
    print(f"\n[HATA] Bir sorun oluştu: {e}")

finally:
    # İşlem bittiğinde bağlantıyı her zaman kapat:
    client.close()
    print("TV ile bağlantı kapatıldı.")
