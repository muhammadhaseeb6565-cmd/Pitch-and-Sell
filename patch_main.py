import re

with open('mobile_app/lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;

  try {
    // SUPABASE INITIALIZATION
    await Supabase.initialize(
      url: 'https://tqntacunedilwtofqycw.supabase.co',
      anonKey: 'sb_publishable_9RpsACXX7JkIAQ_egsLJcA_5IWRfUcZ',
    );
    
    await NotificationService.init();

    // FIREBASE INITIALIZATION 
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  } catch (e) {
    debugPrint("App Init failed: $e");
    initError = e.toString();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: initError != null 
          ? MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Initialization Error:\\n\\n', 
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
              ),
            )
          : const PitchAndSellApp(),
    ),
  );
}
'''

content = re.sub(r'void main\(\) async \{.*runApp\([\s\S]*?const PitchAndSellApp\(\),\n    \),\n  \);\n\}', replacement.strip(), content, flags=re.DOTALL)

with open('mobile_app/lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
