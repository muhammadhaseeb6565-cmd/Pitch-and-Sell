import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class PitchAndSellApp extends StatelessWidget {
  const PitchAndSellApp({super.key});

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
