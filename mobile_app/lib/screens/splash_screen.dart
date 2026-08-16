import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Text(
                  'PITCHNSELL',
                  style: TextStyle(
                    color: const Color(0xffFF5722),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: const Color(0xffFF5722).withOpacity(0.6),
                        blurRadius: _glowAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Pitch It. Sell It. Grow It.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xffFF5722),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
