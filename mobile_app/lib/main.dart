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
import 'screens/checkout_screen.dart';
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
    // Note: Request permissions later in the UI, not in main(), to avoid deadlocks
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
      final productId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : uri.pathSegments.last;
      debugPrint('Navigating to product deep link: $productId');
      _navigateToProduct(productId);
    }
    // Handle auth callback from Supabase
    if (uri.scheme == 'io.supabase.pitchandsell') {
      debugPrint('Auth callback received');
    }
  }

  void _navigateToProduct(String productId) async {
    try {
      final res = await Supabase.instance.client
          .from('products')
          .select('*, profiles:seller_id(*), reviews(rating)')
          .eq('id', productId)
          .maybeSingle();

      if (res != null && navigatorKey.currentState != null) {
        final productData = Map<String, dynamic>.from(res);
        if (productData['video'] == null) {
          productData['video'] = {
            'id': productData['id'],
            'url': productData['video_url'],
            'allowDownload': productData['allow_download'] ?? false,
          };
        }
        if (productData['business'] == null) {
          productData['business'] = {
            'name': productData['profiles']?['business_name'] ?? productData['profiles']?['name'] ?? 'Seller',
          };
        }
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(product: productData),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to deep link product: $e');
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




