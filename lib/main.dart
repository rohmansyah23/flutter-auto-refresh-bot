import 'dart:async';
import 'dart:collection'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('lastUrl') ?? 'https://duckduckgo.com';
  WakelockPlus.enable(); 
  runApp(MyApp(initialUrl: savedUrl));
}

class MyApp extends StatelessWidget {
  final String initialUrl;
  const MyApp({super.key, required this.initialUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: false,
        ),
      ),
      home: AutoRefreshPage(initialUrl: initialUrl),
    );
  }
}

class AutoRefreshPage extends StatefulWidget {
  final String initialUrl;
  const AutoRefreshPage({super.key, required this.initialUrl});

  @override
  State<AutoRefreshPage> createState() => _AutoRefreshPageState();
}

class _AutoRefreshPageState extends State<AutoRefreshPage> {
  InAppWebViewController? webViewController;
  Timer? timer;

  final TextEditingController _intervalController = TextEditingController(text: "1,5");
  final TextEditingController _widthController = TextEditingController(text: "1200");
  final TextEditingController _urlController = TextEditingController();
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isLoading = false;

  bool _isRunning = false;
  bool _isDesktopMode = false;
  int _zoomValue = 100;
  bool _isMenuTerbuka = false;
  void Function(VoidCallback)? _refreshSheet;

  int _rotationIndex = 0;
  final List<DeviceOrientation> _orientasiRotasiTipe = [
    DeviceOrientation.portraitUp,     
    DeviceOrientation.landscapeLeft,  
    DeviceOrientation.portraitDown,   
    DeviceOrientation.landscapeRight  
  ];
  final List<IconData> _iconOri = [
    Icons.screen_lock_portrait,
    Icons.screen_lock_landscape,
    Icons.screen_lock_portrait,
    Icons.screen_lock_landscape,
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
    safeBrowsingEnabled: false,
  );

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl;
  }

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
    _refreshSheet?.call(() {});
    var webSettings = await webViewController?.getSettings();
    if (webSettings != null) {
      webSettings.userAgent = _isDesktopMode ? pureDesktopUserAgent : pureMobileUserAgent;
      webSettings.preferredContentMode = _isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE;
      await webViewController?.setSettings(settings: webSettings);
    }
    webViewController?.reload();
    _applyLayoutSistemDanZoomDinamis();
  }

  void _goToUrl(String input) {
    if (input.isEmpty) return;
    final trimmed = input.trim();
    final isLikelyUrl = trimmed.contains('.') &&
        !trimmed.contains(' ') &&
        (trimmed.startsWith('http://') ||
         trimmed.startsWith('https://') ||
         RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}').hasMatch(trimmed));
    if (isLikelyUrl) {
      String url = trimmed;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    } else {
      final query = Uri.encodeQueryComponent(trimmed);
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://duckduckgo.com/?q=$query&kp=-2')),
      );
    }
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

  void _setOrientation(int index) {
    setState(() { _rotationIndex = index; });
    _refreshSheet?.call(() {});
    SystemChrome.setPreferredOrientations(DeviceOrientation.values).then((_) {
      SystemChrome.setPreferredOrientations([_orientasiRotasiTipe[index]]);
    });
    Future.delayed(const Duration(milliseconds: 350), () => _applyLayoutSistemDanZoomDinamis());
  }

  void _changeZoomLevel(int pertambahanValue) {
    setState(() {
      _zoomValue += pertambahanValue;
      if (_zoomValue < 20) _zoomValue = 20;
      if (_zoomValue > 300) _zoomValue = 300;
    });
    _refreshSheet?.call(() {});
    _applyLayoutSistemDanZoomDinamis();
  }

  void _showSettingsSheet() {
    if (_isMenuTerbuka) return;
    setState(() => _isMenuTerbuka = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          _refreshSheet = setSheetState;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildSettingsPanel(),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _refreshSheet = null;
      if (mounted) setState(() => _isMenuTerbuka = false);
    });
  }

  Widget _buildSettingsPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _buildOrientationSection(),
        const SizedBox(height: 16),
        _buildDesktopSection(),
        const SizedBox(height: 16),
        _buildZoomSection(),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        _buildAutoRefreshSection(),
      ],
    );
  }

  Widget _buildOrientationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Orientasi",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Center(
          child: ToggleButtons(
            isSelected: List.generate(4, (i) => _rotationIndex == i),
            onPressed: (i) => _setOrientation(i),
            borderRadius: BorderRadius.circular(8),
            borderWidth: 1.5,
            borderColor: Colors.grey.shade400,
            selectedBorderColor: Colors.blue.shade400,
            fillColor: Colors.blue.shade100,
            color: Colors.grey.shade700,
            selectedColor: Colors.blue.shade900,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            children: List.generate(4, (i) => Icon(_iconOri[i], size: 22)),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            visualDensity: VisualDensity.compact,
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue.withValues(alpha: 0.3),
            title: const Text(
              "PC / Tablet View",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            value: _isDesktopMode,
            onChanged: (v) => _toggleDesktopMode(v),
          ),
          if (_isDesktopMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Text("Lebar:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Misal 800",
                          contentPadding: EdgeInsets.zero,
                          suffixText: "Px",
                          suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onSubmitted: (_) { FocusScope.of(context).unfocus(); _applyLayoutSistemDanZoomDinamis(); },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Zoom",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.remove, size: 18),
                color: Colors.black87,
                onPressed: () => _changeZoomLevel(-10),
              ),
              SizedBox(
                width: 45,
                child: Text(
                  "$_zoomValue%",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.add, size: 18),
                color: Colors.black87,
                onPressed: () => _changeZoomLevel(10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoRefreshSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Auto Refresh",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 10),
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
                  labelText: "Interval (detik)",
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                  filled: true,
                  fillColor: _isRunning ? Colors.grey.shade200 : Colors.green.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green.shade300),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: _isRunning
                    ? null
                    : () {
                        _startAutoRefresh();
                        Navigator.maybePop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("RUN", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 48,
              child: ElevatedButton(
                onPressed: _isRunning
                    ? () {
                        _stopAutoRefresh();
                        Navigator.maybePop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.stop_rounded, size: 26),
              ),
            ),
          ],
        ),
      ],
    );
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
    return WillPopScope(
      onWillPop: () async {
        if (webViewController == null) return true;
        final canGoBack = await webViewController!.canGoBack();
        if (canGoBack) {
          await webViewController!.goBack();
          _canGoBack = await webViewController!.canGoBack();
          _canGoForward = await webViewController!.canGoForward();
          setState(() {});
          return false;
        }
        return true;
      },
      child: Scaffold(
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
                    initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                    initialSettings: settings,
                    
                    initialUserScripts: UnmodifiableListView<UserScript>([
                      UserScript(
                         source: scriptDewaAntiBerkedipDanAmanBagiWeb, 
                         injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START 
                      ),
                    ]),

                    onWebViewCreated: (controller) => webViewController = controller,
                    onLoadStart: (controller, url) async {
                      setState(() => _isLoading = true);
                    },
                    onReceivedError: (controller, request, error) async {
                      if (error.type == WebResourceErrorType.TIMEOUT ||
                          error.type == WebResourceErrorType.CANNOT_CONNECT_TO_HOST ||
                          error.type == WebResourceErrorType.HOST_LOOKUP ||
                          error.type == WebResourceErrorType.SERVER_UNREACHABLE) {
                        final url = request.url.toString();
                        if (url.isNotEmpty) {
                          final query = Uri.encodeQueryComponent(Uri.tryParse(url)!.host);
                          await controller.loadUrl(
                            urlRequest: URLRequest(url: WebUri('https://duckduckgo.com/?q=$query&kp=-2')),
                          );
                        }
                      }
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      if (!navigationAction.isForMainFrame) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      final uri = navigationAction.request.url;
                      if (uri != null && uri.path.contains('/search')) {
                        if (uri.host.contains('google.com') && uri.queryParameters['safe'] != 'off') {
                          final newUri = uri.replace(queryParameters: {
                            ...uri.queryParameters,
                            'safe': 'off',
                          });
                          await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(newUri)));
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (uri.host.contains('duckduckgo.com') && uri.queryParameters['kp'] != '-2') {
                          final newUri = uri.replace(queryParameters: {
                            ...uri.queryParameters,
                            'kp': '-2',
                          });
                          await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(newUri)));
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      _applyLayoutSistemDanZoomDinamis();
                      setState(() => _isLoading = false);
                    },
                    onUpdateVisitedHistory: (controller, url, isReload) async {
                      _canGoBack = await controller.canGoBack();
                      _canGoForward = await controller.canGoForward();
                      final urlStr = url.toString();
                      _urlController.text = urlStr;
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString('lastUrl', urlStr);
                      setState(() {});
                    },
                    onCreateWindow: (controller, createWindowAction) async {
                      final popupUrl = createWindowAction.request.url.toString();
                      final isGoogleAuth = popupUrl.contains('accounts.google.com') ||
                          popupUrl.contains('google.com/signin') ||
                          popupUrl.contains('googleapis.com/oauth') ||
                          popupUrl.contains('google.com/o/oauth2');
                      if (!isGoogleAuth) return false;
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

                  ], // Stack children close
                ), // Stack close
              ), // Expanded close
            ], // Column children close
          ), // Column close
        ), // SafeArea close
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        backgroundColor: _isRunning ? Colors.green.shade500 : Colors.blue.shade700,
        onPressed: () {
          if (_isMenuTerbuka) {
            Navigator.maybePop(context);
          } else {
            _showSettingsSheet();
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(_isMenuTerbuka ? Icons.close : Icons.tune_rounded, key: ValueKey(_isMenuTerbuka), color: Colors.white),
        ),
      ),
      ),
    );
  }

  Widget _buildAddressBar() {
    return Material(
      elevation: 2,
      shadowColor: Colors.black12,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: _canGoBack ? _goBack : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34),
              color: Colors.grey.shade700,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: _canGoForward ? _goForward : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34),
              color: Colors.grey.shade700,
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _refresh,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34),
                color: Colors.grey.shade700,
              ),
            const SizedBox(width: 2),
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
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                          onPressed: () {
                            _urlController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) => _goToUrl(value),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => _goToUrl(_urlController.text),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.blue.shade700,
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text("Go", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
