import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // =========================================================================
  // FIREBASE INITIALIZATION 
  // =========================================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Push Notifications (FCM)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  } catch (e) {
    print("Firebase init failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const PitchAndSellApp(),
    ),
  );
}

class PitchAndSellApp extends StatefulWidget {
  const PitchAndSellApp({super.key});

  @override
  State<PitchAndSellApp> createState() => _PitchAndSellAppState();
}

class _PitchAndSellAppState extends State<PitchAndSellApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Check initial link if app was closed
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print("Error reading initial deep link: $e");
    }

    // Listen to deep links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print("Deep link stream error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    // Example: https://pitch-and-sell-backend.onrender.com/product/123
    print("Received Deep Link: $uri");
    // Routing logic can be passed down to Navigator via a GlobalKey
    // But for now, we just print and verify it works!
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Pitch and Sell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: authProvider.isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: const Color(0xffFF5722), // Emulgic Orange main accent
        scaffoldBackgroundColor: authProvider.isDarkMode ? const Color(0xff121212) : const Color(0xfff5f5f5),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
