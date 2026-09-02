import re
with open('mobile_app/lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''
  if (initError != null) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Initialization Error:\\n\\n\', 
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
'''
content = re.sub(r'  runApp\([\s\S]*?\n\}\n', replacement.strip() + '\n', content)
with open('mobile_app/lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
