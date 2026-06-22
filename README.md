# 🚀 Mini Auto Refresh Bot & Floating Browser (Flutter)

Aplikasi peramban mini (*mini browser*) berbasis Android yang dibangun menggunakan Flutter dan ditenagai oleh `flutter_inappwebview`. Dirancang secara elegan untuk memonitor dan menyegarkan (*refresh*) situs web secara otomatis, dilengkapi fitur pelolosan keamanan bypass anti-bot (Cloudflare) tingkat native, serta antarmuka pengguna (UI) yang bersih.

Developed by: **[@rohmansyah23](https://github.com/rohmansyah23)**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) 
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) 
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) 

---

## ✨ Fitur Unggulan

* **🍔 Floating Control Menu:** Seluruh kontrol utama (*Start, Stop, Delay, Desktop Mode*) tersimpan rapi di dalam tombol menu mengambang (tiga garis) yang interaktif. Memberikan pengalaman pandang web 100% tanpa gangguan (*Clean View*).
* **⏱ Auto Refresh (Custom Delay):** Fitur penyegaran otomatis tanpa batas dengan opsi input jeda waktu (*looping delay*) dalam satuan detik. Sangat fleksibel, mulai dari hitungan detik hingga berjam-jam.
* **🖥 Desktop Spoofing:** Mengubah arsitektur *viewport meta* CSS & string *User-Agent* secara seketika (*runtime change*) di latar belakang. Fitur ini memaksa UI website beralih menjadi tampilan layar lebar (3-kolom ke atas), bukan sekadar mengubah *User-Agent* mentah seperti WebView standar. Sangat optimal jika dipadukan dengan orientasi *landscape*.
* **🛡 Anti-Bot & Cloudflare Bypass:** Menginjeksi jembatan **Jendela Multi-PopUp (`Modal Windows`)** secara native di tengah layar layaknya peramban desktop. Memastikan sistem otentikasi pihak ketiga seperti *Sign In with Google* atau *Apple* tetap berfungsi normal tanpa terblokir oleh Turnstile atau sistem anti-bot.
* **🔎 Dynamic CSS Zoom Scale:** Kontrol khusus untuk mengatur skala tampilan konten mulai dari resolusi 20% yang secara cerdas merender ulang tata letak *responsive* UI/UX web.

---

## 🛠 Instalasi dan Penggunaan

Ikuti langkah-langkah berikut untuk memasang atau menjalankan proyek ini dari *source code*:

### Prasyarat
* `Flutter SDK` >= V3.0.0 sudah terinstal di perangkat Anda.

### Langkah-Langkah

1. **Clone Repository**
   ```bash
   git clone [https://github.com/rohmansyah23/flutter-auto-refresh-bot.git](https://github.com/rohmansyah23/flutter-auto-refresh-bot.git)
   cd flutter-auto-refresh-bot

```

2. **Unduh Dependensi / Package**
```bash
flutter pub get

```


3. **Jalankan Aplikasi**
Hubungkan perangkat Android Anda via USB Debugging atau aktifkan Android Emulator, kemudian jalankan perintah:
```bash
flutter run

```



---

## 📦 Panduan Build Production (Optimasi APK)

Jika Anda ingin menghasilkan file APK yang optimal dan berukuran kecil (*split per ABI*) serta menyamarkan kode (*obfuscate*), gunakan perintah berikut:

```bash
flutter build apk --split-per-abi --obfuscate --split-debug-info=./debug_info

```

*Perintah ini akan memecah APK berdasarkan arsitektur CPU target (misal: ARM v8-a), sehingga ukurannya jauh lebih ringan dibanding gabungan fat APK.*

---

## 💡 Potensi Pemanfaatan

Proyek peramban serbaguna ini dapat dikembangkan lebih lanjut untuk berbagai kebutuhan personal maupun bisnis, seperti:

* **🤖 Automated Monitoring:** Memonitor dasbor kerja atau mengeksekusi tugas berbasis web yang membutuhkan durasi waktu aktif (*viewing timer ads/dashboard*).
* **📉 Live Statistik & Chart:** Menampilkan grafik saham, kripto, atau papan statistik interaktif yang membutuhkan pembaruan data secara *real-time*.
* **📺 Dedicated Dashboard/CCTV:** Memanfaatkan ponsel Android lama sebagai layar monitor *CCTV/NVR server* internal melalui URL IP Address lokal secara penuh tanpa *timeout*.

---

## 🤝 Kontribusi & Dukungan

Kontribusi, pelaporan *bug*, dan saran fitur sangat terbuka untuk proyek ini. Silakan lakukan **Fork** dan buat *Pull Request* jika Anda ingin memodifikasi repositori ini.

Jika proyek ini bermanfaat bagi Anda, jangan lupa untuk memberikan bintang **⭐** pada repositori ini!

---

*Disclaimer: Penggunaan alat otomatisasi ini sepenuhnya menjadi tanggung jawab pengguna masing-masing.*