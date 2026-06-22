# 🚀 Mini Auto Refresh Bot & Floating Browser (Flutter)

Sebuah aplikasi peramban mini berbasis *Android* dan dibangun menggunakan arsitektur **Flutter (`flutter_inappwebview`)**. Dirancang secara elegan untuk memonitor, menyegarkan (*refresh*) otomatis berbagai situs website dengan fitur pelolosan keamanan (Anti-bot Bypass / Cloudflare) secara native dan *user interface* UI bersih.

Dikembangkan oleh: **[@rohmansyah23](https://github.com/rohmansyah23)**.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) 

---

## ✨ Fitur Unggulan

- **🍔 Floating Control Menu:** Seluruh fitur (*Start, Stop, Delay, Desktop Mode*) tersimpan tersembunyi rapi ke dalam Tombol Menu Garis 3 Mengambang yang interaktif, guna mendapatkan pengalaman pandang web (Area Layar Utama) 100% tanpa gangguan (*Clean View*).
- **⏱ Auto Refresh (Delay Kustom):** Timer otomatis penyegaran (refresh) tak berbatas dengan opsi masukkan form *loop* jeda detik. Sangat fleksibel (dari detik sampai hitungan berjam-jam).
- **🖥 Dekstop Spoofing (Bypass Layar Ponsel):** Merubah arsitektur *View-port meta CSS* & String User-Agent seketika (_Runtime Change_) di *Background*, mendeteksi UI Website beralih menjadi 3-kolom keatas (*Wide-screen Display*), tak hanya mengubah User-Agent mentah seperti WebView biasa. Cocok digabungkan dengan rotasi landscape Layar sentuh.
- **🛡 Anti-Bot & Popup Cloudflare Otorisasi:** Aplikasi menginjeksi jembatan **Jendela Multi-PopUp (`Modals Windows`)** secara native dengan memunculkannya di tengah layar (Seperti komputer Asli). Hal ini memastikan segala sistem "Daftar Melalui Akun Pihak Ketiga (seperti Sign In with Google, Apple, dsb)" tetap berfungsi layaknya peramban Normal/Asli. TurnStile tidak akan melumpuhkan fungsi _popup window_. 
- **🔎 Fitur Dinamis + & - Skala Zoom In CSS**: Kontrol khusus pengelihatan konten dari 20% _scaling_ yang merender resolusi tata kelola _Web responsive UI/UX Layout_-nya. 

## 🛠 Instalasi dan Panduan

Untuk dapat langsung memasang atau mencobanya dari kode dasar *Repository* ini:
1. Pastikan Perangkat kalian sudah mendukung *Framework* minimal standar:
   - `Flutter SDK` >= V3+ Terinstall pada Komputermu. 

2.  _Clone repository_ saya kedalam Memori Komputer milikmu dengan kode Git berikut:
```bash
git clone https://github.com/rohmansyah23/flutter-auto-refresh-bot.git
cd flutter-auto-refresh-bot
Jalankan penyelesaian / download paket Library module internal:
code
Bash
flutter pub get
Sambungkan Kabel USB dari OS Android kesayangan ke Laptop atau Gunakan Virtual Android bawaan Komputer.
code
Bash
flutter run
🤝 Build File Optimal dan Kecil untuk HP:
Bagi teman-teman jika kalian merasa aplikasi web view memiliki ukuram (fat APK) Terlalu besar hingga memakan hampir Ratusan Mega Byte karena gabungan OS. Kalian sanggup membelahnya menjadi satu OS target ringan, Contoh pada OS Arm V8-a di kebanyakan gawai saat ini:
code
Bash
flutter build apk --split-per-abi --obfuscate --split-debug-info=./debug_info
📸 Potensi Cara Pemanfaatan / Kegunaan Bebas
Kode / Project Flutter Peramban serbaguna ini bisa kembangkan guna kebutuhan Pribadi atau Usaha Anda secara bebas yang terkait dengan monitoring, misal :
🤖 Alat untuk mengeksekusi Cuan Website tertentu dari skrip-tugas berjalan yang membutuhkan durasi (viewing timer ads/dashboard click).
📉 Display layar Auto Grafik Saham Web View / Papan Statistik yang butuh pengawas ter-update.
📺 Jaringan Penyiaran atau Dashboard server CCTV dari URL Ip address pribadi kamu agar menahanya tampil selalu penuh di ponsel lamamu !.
Dan lainnya..
Silakan Fork (Modifkasi Repo ini) Bila kalian Merasa Hal Ini Membantu Misi Pekerjaan Kamu!, Jangan lupa Klik Tombol Bintang / ⭐ untuk Repository @Roshmansyah23 ini !!! 😄🙏.