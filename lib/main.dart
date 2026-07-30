import 'dart:async';
import 'dart:collection'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable(); 
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

  final TextEditingController _intervalController = TextEditingController(text: "1,5");
  final TextEditingController _widthController = TextEditingController(text: "1200");
  final TextEditingController _urlController = TextEditingController(text: "https://www.google.com");
  bool _canGoBack = false;
  bool _canGoForward = false;

  bool _isRunning = false;
  bool _isDesktopMode = false;
  int _zoomValue = 100;
  bool _isMenuTerbuka = false;

  int _rotationIndex = 0;
  final List<DeviceOrientation> _orientasiRotasiTipe = [
    DeviceOrientation.portraitUp,     
    DeviceOrientation.landscapeLeft,  
    DeviceOrientation.portraitDown,   
    DeviceOrientation.landscapeRight  
  ];
  final List<String> _teksNamaRotasi = [
    "Normal", "Miring", "Atas-Bwh", "Miring 2"
  ];

  final String pureMobileUserAgent =
      "Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";
  final String pureDesktopUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: true,
    domStorageEnabled: true,
    supportZoom: true,
    builtInZoomControls: true,
    displayZoomControls: false,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    userAgent: "Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    preferredContentMode: UserPreferredContentMode.MOBILE,
  );

  @override
  void dispose() {
    timer?.cancel();
    _intervalController.dispose();
    _widthController.dispose();
    _urlController.dispose();
    WakelockPlus.disable(); 
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, 
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, 
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _startAutoRefresh() {
    int intervalSeconds = int.tryParse(_intervalController.text) ?? 3;
    if (intervalSeconds <= 0) intervalSeconds = 2;
    setState(() => _isRunning = true);
    timer?.cancel();
    timer = Timer.periodic( Duration(seconds: intervalSeconds), (_) { webViewController?.reload(); } );
  }

  void _stopAutoRefresh() {
    timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _toggleDesktopMode(bool value) async {
    setState(() => _isDesktopMode = value);
    var webSettings = await webViewController?.getSettings();
    if (webSettings != null) {
      webSettings.userAgent = _isDesktopMode ? pureDesktopUserAgent : pureMobileUserAgent;
      webSettings.preferredContentMode = _isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE;
      await webViewController?.setSettings(settings: webSettings);
    }
    webViewController?.reload();
    _applyLayoutSistemDanZoomDinamis();
  }

  void _goToUrl(String url) {
    if (url.isEmpty) return;
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
    }
    webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    FocusScope.of(context).unfocus();
  }

  void _goBack() {
    webViewController?.goBack();
  }

  void _goForward() {
    webViewController?.goForward();
  }

  void _refresh() {
    webViewController?.reload();
  }

  void _gantiUrutanRotasiSistemLayar() {
    setState(() { _rotationIndex = (_rotationIndex + 1) % 4; });
    SystemChrome.setPreferredOrientations([ _orientasiRotasiTipe[_rotationIndex] ]);
    Future.delayed(const Duration(milliseconds: 350), () => _applyLayoutSistemDanZoomDinamis());
  }

  void _changeZoomLevel(int pertambahanValue) {
    setState(() {
      _zoomValue += pertambahanValue;
      if (_zoomValue < 20) _zoomValue = 20;
      if (_zoomValue > 300) _zoomValue = 300;
    });
    _applyLayoutSistemDanZoomDinamis();
  }

  // === 🔥 ULTIMATE WEB ANTI-CRASH & MODAL BLOCKER === 
  final String scriptDewaAntiBerkedipDanAmanBagiWeb = """
      (function(){
        
        // CSS GHOSTING: Mencegah Kedip Saat Web Muat Tiba Tiba
        var antiFlickerCssSiluman = document.createElement('style');
        antiFlickerCssSiluman.type = 'text/css';
        antiFlickerCssSiluman.innerHTML = `
             html[data-nuke-target="aktif"] aside,
             html[data-nuke-target="aktif"] nav,
             html[data-nuke-target="aktif"] header,
             html[data-nuke-target="aktif"] [id*="sidebar"],
             html[data-nuke-target="aktif"] [class*="bottom-menu"],
             html[data-nuke-target="aktif"] div.fixed.inset-0.z-50[class*="backdrop-blur"] {
                  display: none !important; 
                  pointer-events: none !important;
             }
        `;
        function taruhPenangkalStyleAwal() {
            if (document.head || document.documentElement) {
                (document.head || document.documentElement).appendChild(antiFlickerCssSiluman);
            } else { setTimeout(taruhPenangkalStyleAwal, 2); }
        }
        taruhPenangkalStyleAwal();

        // MOTOR PENYUSUP ENGINE / Fps FRAME CATCHER !! 
        function peredamModeAman() {
            var urlLengkap = window.location.href.toLowerCase();
            var domainBuzzcuan = urlLengkap.includes('buzzcuan.id') || urlLengkap.includes('buzzcuan.com');
            var sedangDidalamDashboardTask = domainBuzzcuan && urlLengkap.includes('dashboard/tasks');
            if(sedangDidalamDashboardTask){
                 
                 document.documentElement.setAttribute('data-nuke-target', 'aktif');
                 
                 // ====== 1. SISTEM ANTIMATTER MODAL OVERLAY KHUSUS =====
                 // Mendeteksi Keberadaan Overlay <div class="fixed inset-0 bg-slate... dsbnya"> secara aman !!
                 document.querySelectorAll('div.fixed.inset-0.z-50').forEach(function(modalHantu) {
                     var atributClassOverlay = modalHantu.getAttribute('class') || '';
                     if (atributClassOverlay.includes('bg-slate-') || atributClassOverlay.includes('backdrop-blur')) {
                         
                         // Dihiden Tanpa meRemove (Menipu Crash pada sistem SPA website !) 
                         modalHantu.style.setProperty('display', 'none', 'important');
                         modalHantu.style.setProperty('opacity', '0', 'important');
                         modalHantu.style.setProperty('visibility', 'hidden', 'important');
                         modalHantu.style.setProperty('pointer-events', 'none', 'important'); 
                         
                         // Penting! Atasi freeze (Stuck Gabisa Dihandle Geser Ke Bawah ) 
                         document.body.style.setProperty('overflow', 'auto', 'important');
                         document.body.style.setProperty('pointer-events', 'auto', 'important');
                     }
                 });


                 // ====== 2. EKSEKUTOR TITLE, SUB TITLE TEXT TARGETS !! ====
                 var keywordDilarang = ['REWARD MARKETPLACE', 'BUZZCUAN TASKS', 'PILIH TUGAS', 'MENAMPILKAN 1 -'];
                 
                 document.querySelectorAll('main p, main h1, main h2, main span, main h3').forEach(function(el) {
                     var tekAsliHurufBsr = (el.innerText || "").toUpperCase();
                     for(var k=0; k < keywordDilarang.length; k++) {
                        if (tekAsliHurufBsr.includes(keywordDilarang[k])) {
                            // Sembunyikan diam2 dr layar secara Absolut (No physical render !)
                            el.style.setProperty('display', 'none', 'important'); 
                            el.style.setProperty('visibility', 'hidden', 'important'); 
                            el.style.setProperty('height', '0px', 'important');
                            el.style.setProperty('margin', '0px', 'important');
                            el.style.setProperty('padding', '0px', 'important');
                        }
                     }
                 });


                 // ===== 3. TUTUP MENU OPTION FILTER / PAGES ====  
                 document.querySelectorAll('main .card').forEach(function(kartuObjk) {
                     var textKelasAttrKotor = kartuObjk.getAttribute('class') || '';
                     
                     // Pastikan Jangan Sampai Elemen Card Target asli ikut Kesapu : 
                     if( !kartuObjk.querySelector('.task-card') && !textKelasAttrKotor.includes('task-card') ) {
                         if (textKelasAttrKotor.includes('p-3.5') || 
                             textKelasAttrKotor.includes('p-4') || 
                             (kartuObjk.innerText && kartuObjk.innerText.includes('Tampilkan'))) {
                             kartuObjk.style.setProperty('display', 'none', 'important');
                             kartuObjk.style.setProperty('padding', '0px', 'important'); 
                             kartuObjk.style.setProperty('margin', '0px', 'important'); 
                             kartuObjk.style.setProperty('height', '0px', 'important'); 
                             kartuObjk.style.setProperty('overflow', 'hidden', 'important'); 
                         }
                     }
                 });
                 
                 // ====== 4. AUTOPILOT PEMBENTUK POSTUR LURUS DARI PARENT SAMPAI MENTOK BAWAH =====
                 var bksPenahanParentMain = document.querySelector('main');
                 while (bksPenahanParentMain && bksPenahanParentMain.tagName !== 'BODY') {
                     // Paksa ratakan pinggiran Tailwind
                     bksPenahanParentMain.style.setProperty('padding', '0px', 'important');
                     bksPenahanParentMain.style.setProperty('margin', '0px', 'important');
                     
                     // Paksa rata center tanpa sisa porsi flex col ! 
                     bksPenahanParentMain.style.setProperty('width', '100%', 'important');
                     bksPenahanParentMain.style.setProperty('display', 'flex', 'important');
                     bksPenahanParentMain.style.setProperty('flex-direction', 'column', 'important');
                     bksPenahanParentMain.style.setProperty('align-items', 'center', 'important');
                     bksPenahanParentMain.style.setProperty('max-width', '100vw', 'important');
                     
                     bksPenahanParentMain = bksPenahanParentMain.parentElement;
                 }

                 // Kuncian pada area barisan Container Anak Task-Card-nya biar ditengah Monitor presisi  
                 document.querySelectorAll('.grid[class*="gap"]').forEach(function(gGr1id) {
                     gGr1id.style.setProperty('width', '100%', 'important');
                     gGr1id.style.setProperty('max-width', '1200px', 'important'); 
                     gGr1id.style.setProperty('justify-content', 'center', 'important');
                     gGr1id.style.setProperty('align-items', 'center', 'important');
                     gGr1id.style.setProperty('margin', '0 auto', 'important');
                 });

            } else {
                 document.documentElement.removeAttribute('data-nuke-target');
            }

            requestAnimationFrame(peredamModeAman); 
        }
        requestAnimationFrame(peredamModeAman);

      })();
  """;

  void _applyLayoutSistemDanZoomDinamis() {
    String lebarYgDisetelFormText = _widthController.text.trim();
    if(lebarYgDisetelFormText.isEmpty) lebarYgDisetelFormText = "1024";

    String paksakanLebarScreenCF = _isDesktopMode
        ? "try{document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=$lebarYgDisetelFormText');}catch(e){}"
        : "try{document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=device-width, initial-scale=1');}catch(e){}";

    webViewController?.evaluateJavascript(source: """
       $paksakanLebarScreenCF 
       document.body.style.zoom = '$_zoomValue%'; 
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900, 
      resizeToAvoidBottomInset: false, 

      body: SafeArea(
        child: Column(
          children: [
            _buildAddressBar(),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri("https://www.google.com")),
                    initialSettings: settings,
                    
                    initialUserScripts: UnmodifiableListView<UserScript>([
                      UserScript(
                         source: scriptDewaAntiBerkedipDanAmanBagiWeb, 
                         injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START 
                      ),
                    ]),

                    onWebViewCreated: (controller) => webViewController = controller,
                    onLoadStop: (controller, url) async { _applyLayoutSistemDanZoomDinamis(); },
                    onUpdateVisitedHistory: (controller, url, isReload) async {
                      _canGoBack = await controller.canGoBack();
                      _canGoForward = await controller.canGoForward();
                      _urlController.text = url.toString();
                      setState(() {});
                    },
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
                                        const Text(" 🌐 Secure Auth...", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: InAppWebView(
                                      windowId: createWindowAction.windowId,
                                      initialSettings: InAppWebViewSettings(userAgent: settings.userAgent),
                                      onCloseWindow: (childController) async {
                                        if(Navigator.canPop(context)) Navigator.of(context).pop();
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

                  if (_isMenuTerbuka)
                    Positioned(
                      bottom: 80,
                      right: 16,
                      left: 16,
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic, 
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Container(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                          ),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center( child: Container( width: 50, height: 4, margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)) ) ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade100,
                                          foregroundColor: Colors.blue.shade900,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                        ),
                                        icon: Icon( (_rotationIndex == 1 || _rotationIndex == 3) ? Icons.screen_lock_landscape : Icons.screen_lock_portrait, size: 20 ),
                                        label: Text(_teksNamaRotasi[_rotationIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        onPressed: _gantiUrutanRotasiSistemLayar, 
                                      ),
                    
                                      Container(
                                        height: 38,
                                        decoration: BoxDecoration( color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200) ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton( padding: EdgeInsets.zero, icon: const Icon(Icons.remove, size: 18), color: Colors.black87, onPressed: () => _changeZoomLevel(-10) ),
                                            Container( width: 45, alignment: Alignment.center, child: Text("$_zoomValue%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)) ),
                                            IconButton( padding: EdgeInsets.zero, icon: const Icon(Icons.add, size: 18), color: Colors.black87, onPressed: () => _changeZoomLevel(10) ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration( borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade100) ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Material(
                                      color: Colors.blueGrey.shade50,
                                      child: Column(
                                        children: [
                                          SwitchListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                            visualDensity: VisualDensity.compact,
                                            activeThumbColor: Colors.blue, 
                                            activeTrackColor: Colors.blue.withValues(alpha: 0.3),
                                            title: const Text("PC/Tablet Dimensi View", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blueGrey)),
                                            value: _isDesktopMode,
                                            onChanged: (bool onUpdateTgl) => _toggleDesktopMode(onUpdateTgl),
                                          ),
                                          
                                          if(_isDesktopMode)
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                              child: Row(
                                                children: [
                                                  const Text("Atur Lebar Px Area:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 38,
                                                      child: TextField(
                                                        controller: _widthController,
                                                        keyboardType: TextInputType.number,
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                        decoration: const InputDecoration(
                                                          hintText: "Misal 800",
                                                          contentPadding: EdgeInsets.zero,
                                                          suffixText: "Px   ", suffixStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                                          fillColor: Colors.white, filled: true,
                                                          border: OutlineInputBorder()
                                                        ),
                                                        onSubmitted: (_) { FocusScope.of(context).unfocus(); _applyLayoutSistemDanZoomDinamis(); },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, thickness: 1, color: Colors.black12), 
                                  const SizedBox(height: 12),
                    
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: TextField(
                                          controller: _intervalController,
                                          keyboardType: TextInputType.number,
                                          enabled: !_isRunning,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            labelText: "⏱️ Interval(s)",
                                            labelStyle: const TextStyle(fontSize: 11),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                            filled: true, fillColor: _isRunning ? Colors.grey.shade200 : Colors.green.shade50,
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.green.shade300)),
                                            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.green.shade600, width: 2)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
                                        child: ElevatedButton(
                                          onPressed: _isRunning ? null : () { setState(() => _isMenuTerbuka = false); _startAutoRefresh(); },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
                                              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                          child: const Text("▶ RUN!", style: TextStyle(fontWeight: FontWeight.w900)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 48,
                                        child: ElevatedButton(
                                          onPressed: _isRunning ? _stopAutoRefresh : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade500, foregroundColor: Colors.white,
                                            elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                          ),
                                          child: const Icon(Icons.stop_rounded, size: 26),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        backgroundColor: _isRunning ? Colors.green.shade500 : Colors.blue.shade700,
        onPressed: () { setState(() { _isMenuTerbuka = !_isMenuTerbuka; }); },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(_isMenuTerbuka ? Icons.close : Icons.tune_rounded, key: ValueKey(_isMenuTerbuka), color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAddressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: _canGoBack ? _goBack : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
            color: Colors.blueGrey.shade700,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: _canGoForward ? _goForward : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
            color: Colors.blueGrey.shade700,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
            color: Colors.blueGrey.shade700,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                hintText: "Cari atau masukkan URL",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              onSubmitted: (value) => _goToUrl(value),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _goToUrl(_urlController.text),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.blue.shade700,
            ),
            child: const Text("Go", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
