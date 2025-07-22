import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_word_app/screens/daily_repeat.dart';
import 'package:flutter_word_app/screens/homescreen.dart';
import 'package:flutter_word_app/screens/practicescreen.dart';
import 'package:flutter_word_app/services/isar_service.dart';
import 'package:flutter_word_app/services/notification_service.dart';
import 'package:flutter_word_app/services/ttsservice.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

final ttsServiceProvider = ChangeNotifierProvider<TtsService>((ref) {
  final service = TtsService();
  service.init();
  return service;
});

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Arka planda mesaj alındı: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  requestNotificationPermission();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //await initializeDateFormatting('tr', "null");
  // Initialize Isar database
  final isarService = IsarService();
  try {
    await isarService.init();
  } catch (e) {
    debugPrint('BİR HATA VAR YEGEN ONU DERRHAL ÇÖZ!!!: $e');
  }
  runApp(ProviderScope(child: MyApp(isarservice: isarService)));

  Future.delayed(Duration(seconds: 2), () {
    FlutterNativeSplash.remove();
  });
}

void requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  final IsarService isarservice;
  const MyApp({super.key, required this.isarservice});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [const Locale('tr')],
      title: 'Word Master',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFFFF6584),
          surface: const Color(0xFF1E2139),
          background: const Color(0xFF121421),
        ),
        scaffoldBackgroundColor: const Color(0xFF121421),
        cardColor: const Color(0xFF1E2139),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(
            0xFF1E2139,
          ), // Bottom bar arka plan rengi
          selectedItemColor: const Color(
            0xFF6C63FF,
          ), // Seçili sekme rengi (mor)
          unselectedItemColor: Colors.grey[400], // Seçili olmayan sekme rengi
          showSelectedLabels: true, // Sadece aktif sekme ismi gözüksün
          showUnselectedLabels: false, // Pasif sekme isimleri gizlensin
          type: BottomNavigationBarType.fixed, // Renk dalgalanmasını önler
        ),
      ),
      home: MainWrapper(isarservice: isarservice),
    );
  }
}

class MainWrapper extends StatefulWidget {
  final IsarService isarservice;
  const MainWrapper({Key? key, required this.isarservice}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  String? token;
  int _currentIndex = 0;
  late PageController _pageController;

  // GlobalKey'ler her sayfa için, refresh için lazım
  final GlobalKey<RepeatPageState> _repeatKey = GlobalKey<RepeatPageState>();
  final GlobalKey<PracticeScreenState> _practiceKey =
      GlobalKey<PracticeScreenState>();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  List<Widget> _getScreens() {
    return [
      RepeatPage(
        key: _repeatKey,
        isarService: widget.isarservice,
      ), // Günlük Tekrar
      PracticeScreen(key: _practiceKey, isarService: widget.isarservice),
      HomeScreen(key: _homeKey, isarService: widget.isarservice),
      // AddPage(isarService: widget.isarservice),
    ];
  }

  @override
  void initState() {
    super.initState();
    _setupFCM();
    _subscribeUserToTopic();
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _subscribeUserToTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic("flutter_users");
    print("🟢 Kullanıcı flutter_users topic’ine abone oldu");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Sayfa değişince ilgili sayfanın refresh fonksiyonunu tetikle
    switch (index) {
      case 0:
        _repeatKey.currentState?.refreshData();
        break;
      case 1:
        _practiceKey.currentState?.refreshData();
        break;
      case 2:
        _homeKey.currentState?.refreshData();
        break;
    }
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Kullanıcıdan izin iste
    await messaging.requestPermission();

    // Cihaz token'ı al
    token = await messaging.getToken();
    print("🎯 FCM TOKEN: $token");

    // Uygulama açıkken mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🟢 Foreground mesajı: ${message.notification?.title}');
      print('İçerik: ${message.notification?.body}');
    });

    // Bildirime tıklanarak uygulama açıldığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔵 Uygulama bildirime tıklanarak açıldı');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _getScreens(),
        physics:
            const NeverScrollableScrollPhysics(), // daha yumuşak scroll efekti
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.jumpToPage(index);
          setState(() => _currentIndex = index);
        },
        showSelectedLabels: true,
        showUnselectedLabels: false,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Tekrar'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Çalış'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Kütüphane'),
          //  BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Ekle'),
        ],
      ),
    );
  }
}

class WordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> word;
  final Function(String)? onTagChanged;

  const WordDetailScreen({super.key, required this.word, this.onTagChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Kelime Detayı')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word['word'],
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: word['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: word['color'].withOpacity(0.5)),
              ),
              child: Text(
                word['tag'],
                style: GoogleFonts.poppins(
                  color: word['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Anlam:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(word['meaning'], style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 30),
            if (onTagChanged != null) ...[
              Text(
                'Etiketi Güncelle:',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTagButton('Temel', Colors.red, context),
                  const SizedBox(width: 10),
                  _buildTagButton('Orta', Colors.orange, context),
                  const SizedBox(width: 10),
                  _buildTagButton('İyi', Colors.green, context),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagButton(String tag, Color color, BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color),
        ),
      ),
      onPressed: () async {
        await onTagChanged?.call(tag); // etiketi güncelle
        Navigator.pop(context, true); // sayfayı kapat ve true gönder
      },
      child: Text(tag),
    );
  }
}
