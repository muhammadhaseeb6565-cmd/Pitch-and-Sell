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

class IPhone16ProWrapper extends StatelessWidget {
  final Widget child;
  const IPhone16ProWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff090909), // Dark backdrop for desktop
      child: Center(
        child: Container(
          width: 402, // iPhone 16 Pro Width
          height: 874, // iPhone 16 Pro Height
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44), // iPhone 16 Pro rounded corners
            border: Border.all(color: const Color(0xff1f1f1f), width: 8), // Simulated Bezel
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
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
      builder: (context, child) {
        return IPhone16ProWrapper(child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
