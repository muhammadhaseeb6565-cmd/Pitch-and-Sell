import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

import 'features/feed/providers/feed_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Firebase Background Messaging Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;

  try {
    // SUPABASE INITIALIZATION
    await Supabase.initialize(
      url: 'https://tqntacunedilwtofqycw.supabase.co',
      anonKey: 'sb_publishable_9RpsACXX7JkIAQ_egsLJcA_5IWRfUcZ',
    );
    
    NotificationService.init();

    // FIREBASE INITIALIZATION 
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.requestPermission();
  } catch (e) {
    debugPrint("App Init failed: $e");
    initError = e.toString();
  }

if (initError != null) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Initialization Error:\n\n$initError', 
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
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
      debugPrint("Error reading initial deep link: $e");
    }

    // Listen to deep links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link stream error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    // Handle product deep links: /product/{id}
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'product') {
      // Navigate to feed/product detail
      // Could push to a product detail screen in future
      debugPrint('Product deep link: ${uri.pathSegments.last}');
    }
    // Handle auth callback from Supabase
    if (uri.scheme == 'io.supabase.pitchandsell') {
      debugPrint('Auth callback received');
    }
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
      navigatorKey: navigatorKey,
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



