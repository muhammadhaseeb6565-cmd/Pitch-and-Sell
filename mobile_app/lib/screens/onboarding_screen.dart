import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Pitch Your Business. Get Discovered.',
      'desc': 'Showcase your items through premium short-form videos to customers all across Pakistan.',
      'emoji': '🚀',
    },
    {
      'title': 'Upload Pitches in Minutes',
      'desc': 'Publish demo videos, details, pricing, and stock status immediately to the public feed.',
      'emoji': '📹',
    },
    {
      'title': 'Earn with Low Commission',
      'desc': 'Keep up to 96% of your qualifying sales revenue directly into your linked mobile wallets.',
      'emoji': '💰',
    },
    {
      'title': 'Are You a Buyer or Seller?',
      'desc': 'Choose your primary platform role to tailor your discoverability experience. You can change this anytime!',
      'emoji': '✨',
    },
  ];

  String _selectedRole = 'Customer (Buyer)';

  void _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {}

    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = _selectedRole.contains('Shop') ? 'seller' : 'customer';

    if (auth.isAuthenticated && auth.user != null) {
      try {
        await auth.setAccountRole(role);
      } catch (e) {
        debugPrint('Failed to save role: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isAuthenticated
            ? const MainNavigationScreen()
            : WelcomeScreen(initialMode: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide['emoji']!,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (idx == _slides.length - 1) ...[
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xff1e1e1e),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: DropdownButton<String>(
                              dropdownColor: const Color(0xff1e1e1e),
                              value: _selectedRole,
                              underline: const SizedBox(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              items: ['Customer (Buyer)', 'Shop (Seller)'].map((r) {
                                return DropdownMenuItem(value: r, child: Text(r));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRole = val);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (idx) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == idx ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == idx ? const Color(0xffFF5722) : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
