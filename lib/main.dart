import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AutoRefreshPage(),
    );
  }
}

class AutoRefreshPage extends StatefulWidget {
  const AutoRefreshPage({super.key});

  @override
  State<AutoRefreshPage> createState() => _AutoRefreshPageState();
}

class _AutoRefreshPageState extends State<AutoRefreshPage> {
  InAppWebViewController? webViewController;
  Timer? timer;

  final TextEditingController _intervalController = TextEditingController(text: "3");
  
  bool _isRunning = false;
  bool _isDesktopMode = false;
  int _zoomValue = 100;
  
  // STATER STATUS TAMPILAN PANEL MENGAMBANG
  bool _isMenuTerbuka = false;

  final String pureMobileUserAgent =
      "Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";
  final String pureDesktopUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    supportMultipleWindows: true, // Dukungan Tembus Login Pop-UP Aktif 
    javaScriptCanOpenWindowsAutomatically: true,
    domStorageEnabled: true,
    supportZoom: true,
    builtInZoomControls: true, 
    displayZoomControls: false,
    useWideViewPort: true, // Untuk Dimensi Monitor Paksa Aktif (Biar Kolom nya jadi berjejer 3)
    loadWithOverviewMode: true, 
    userAgent: "Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    preferredContentMode: UserPreferredContentMode.MOBILE,
  );

  @override
  void dispose() {
    timer?.cancel();
    _intervalController.dispose();
    super.dispose();
  }

  // --- KUMPULAN LOGIKA PERINTAH TETAP TERJAGA KINERJANYA ---

  void _startAutoRefresh() {
    int intervalSeconds = int.tryParse(_intervalController.text) ?? 3;
    if (intervalSeconds <= 0) intervalSeconds = 2;
    setState(() => _isRunning = true);

    timer?.cancel();
    timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) { webViewController?.reload(); },
    );
  }

  void _stopAutoRefresh() {
    timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _toggleDesktopMode(bool? value) async {
    if (value == null) return;
    setState(() => _isDesktopMode = value);

    var webSettings = await webViewController?.getSettings();
    if (webSettings != null) {
      webSettings.userAgent = _isDesktopMode ? pureDesktopUserAgent : pureMobileUserAgent;
      webSettings.preferredContentMode = _isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE;
      await webViewController?.setSettings(settings: webSettings);
    }
    webViewController?.reload(); 
  }

  void _changeZoomLevel(int pertambahanValue) {
    setState(() {
      _zoomValue += pertambahanValue;
      if (_zoomValue < 20) _zoomValue = 20; 
      if (_zoomValue > 300) _zoomValue = 300; 
    });
    _applyLayoutSistemDanZoomDinamis();
  }

  void _applyLayoutSistemDanZoomDinamis() {
    String paksakanLebarScreenCF = _isDesktopMode
        ? "try{document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=1200');}catch(e){}" 
        : "try{document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=device-width, initial-scale=1');}catch(e){}"; 

    webViewController?.evaluateJavascript(source: """
       $paksakanLebarScreenCF 
       document.body.style.zoom = '${_zoomValue}%'; 
    """);
  }


  // ============== PEMBANGUNAN HALAMAN LAYAR 100% LAYOUT WEB BARU =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      
      // Halaman Dibagi berlapis (Stack). Web ada dibagian Bawah (Back), Tombol Mengambang & Box ada di paling Depan Lapisannya
      body: SafeArea(
        child: Stack(
          children: [
            
            // ================== LAYAP 1 (Lapis Utama Paling Belakang - Tampilan Situs Cuan Penuh Tanpa Batas 100%) ===================
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri("https://buzzcuan.id")), 
              initialSettings: settings,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStop: (controller, url) async {
                _applyLayoutSistemDanZoomDinamis();
              },
              
              // ============ (Google Pop UP Layar Sentuh Sistem Terapkan Langsung Ke-Mode Lapis Melayang - Tidak di ubah Sama!) ======
              onCreateWindow: (controller, createWindowAction) async {
                showDialog(
                  context: context,
                  barrierDismissible: false, 
                  builder: (context) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.95, 
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: Column(
                          children: [
                            Container(
                              color: Colors.blue.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(" 🌐  System Sign In / Login O-Auth...", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                                    onPressed: () {
                                      Navigator.of(context).pop(); 
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: InAppWebView(
                                windowId: createWindowAction.windowId, 
                                initialSettings: InAppWebViewSettings(userAgent: settings.userAgent), 
                                onCloseWindow: (childController) async {
                                  if(Navigator.canPop(context)) {
                                     Navigator.of(context).pop(); 
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                return true; 
              },
            ),

            
            // ================== LAYAP 2 ( Kotak Control Kendali Mengambang yg Dipanggil Tombol Garis-Tiga !! ) ================== 
            // Posisi dibuat interaktif kalau Form keyboard ketikan detik terbuka, Menu terbang sedikit agar terhindar (TIdak tertumpuk)
            if (_isMenuTerbuka)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: 80 + MediaQuery.of(context).viewInsets.bottom, 
                right: 16,
                left: 16,
                child: Material(
                  elevation: 12, // Mempunyai Bayangan
                  color: Colors.white.withOpacity(0.96), //  sedikit Transparan Estetik (ala Kaca putih susu) !
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        // Garis Dekorasi Kotaknya Biar Manis
                        Container( width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)) ),
                        
                        // BARIS ATAS = CEKLIS DEKSTOP DAN TOMBOL ZOOM 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             // -- CEKLIS DESKTOP --
                             Container(
                               decoration: BoxDecoration( color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                               padding: const EdgeInsets.symmetric(horizontal: 4),
                               child: Row(
                                 children: [
                                   Checkbox(
                                      value: _isDesktopMode,
                                      onChanged: _toggleDesktopMode,
                                      activeColor: Colors.blue,
                                    ),
                                   const Text("Desktop Web", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                                   const SizedBox(width: 8)
                                 ],
                               ),
                             ),

                            // -- MIN / PLUS (KOTAK KECIL ZOOOM -- )
                            Container(
                              height: 35,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300)
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove, size: 20, color: Colors.black87),
                                    onPressed: () => _changeZoomLevel(-10),
                                  ),
                                  Text("$_zoomValue%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add, size: 20, color: Colors.black87),
                                    onPressed: () => _changeZoomLevel(10),
                                  ),
                                ],
                              ),
                            )

                          ],
                        ),
                        
                        const SizedBox(height: 12),

                        // BARIS BAWAH = [ ISIAN ANGKA DETIK | START | STOP]  🔥🚀
                        Row(
                          children: [
                            // - Ketikan Waktu
                            Expanded(
                              child: TextField(
                                controller: _intervalController,
                                keyboardType: TextInputType.number,
                                enabled: !_isRunning,
                                decoration: InputDecoration(
                                  labelText: "Jeda/Detik",
                                  isDense: true, filled: true, fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // - Tombol RUN hijau Menyala
                            ElevatedButton.icon(
                              onPressed: _isRunning ? null : () { 
                                  // Tutup/Bakar Kotak Menu biar Leluasa ngelihat Cuannya berlimpah Otomatis
                                  setState(() => _isMenuTerbuka = false); 
                                  _startAutoRefresh(); 
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text("RUN!"),
                            ),
                            const SizedBox(width: 4),

                            // - Tombol Stop
                            ElevatedButton(
                              onPressed: _isRunning ? _stopAutoRefresh : null,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)),
                              child: const Icon(Icons.stop_rounded, size: 18),
                            ),
                          ],
                        )

                      ],
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),

      // ========================== MENU GARIS 3 ( HAMBURGER MENGAMBANG DI POJOK ! )  ===========================
      // Indikator Warna Garis 3 berubah Jadi Hijau Nyala kalau program Refresh Bot kamu lagi Bekerja 
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        backgroundColor: _isRunning ? Colors.green.shade500 : Colors.blue.shade700,
        onPressed: () {
          // Ketika ditekan Titik nya Memunculkan  / Menyembuyikan box ! 
          setState(() { _isMenuTerbuka = !_isMenuTerbuka; });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          // Bila di Pencet terbuka maka ICON Mengambang Menjadi Icon tanda SILANG [X] , kalo Di silang kembali Ke GARIS TIGA 
          child: Icon(
            _isMenuTerbuka ? Icons.close : Icons.menu,
            key: ValueKey(_isMenuTerbuka),
            color: Colors.white,
          ),
        ),
      ),


    );
  }
}