import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  
  final _signUpFirstNameController = TextEditingController();
  final _signUpLastNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedRole = 'Both';
  bool _acceptTerms = true;
  String? _profileImagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpFirstNameController.dispose();
    _signUpLastNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _handleMockLogin(AuthProvider auth) async {
    final emailText = _signInEmailController.text.trim();
    if (emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an email address', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }
    final name = emailText.split('@')[0];
    
    final success = await auth.loginMockGoogle(
      emailText,
      name,
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
    );
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _handleMockSignUp(AuthProvider auth) async {
    final emailText = _signUpEmailController.text.trim();
    if (emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an email address', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }
    final name = '${_signUpFirstNameController.text.trim()} ${_signUpLastNameController.text.trim()}'.trim();
    final displayName = name.isNotEmpty ? name : emailText.split('@')[0];

    final success = await auth.loginMockGoogle(
      emailText,
      displayName,
      _profileImagePath ?? 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
    );
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xffFF5722).withOpacity(0.15),
                    child: const Icon(Icons.smart_toy_outlined, size: 28, color: Color(0xffFF5722)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PITCH & SELL',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      Text(
                        'Pitch It. Sell It. Grow It.',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tab Selector
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xffFF5722),
                labelColor: const Color(0xffFF5722),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
              const SizedBox(height: 24),

              // Tabs Body Area
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _tabController.index == 0
                    ? // Sign In Form View
                      Column(
                        key: const ValueKey('signin'),
                        children: [
                          TextField(
                            controller: _signInEmailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _signInPasswordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.grey),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password reset link sent to your email address!')),
                                );
                              },
                              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xffFF5722), fontSize: 12)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
                              onPressed: () => _handleMockLogin(authProvider),
                              child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    : // Sign Up Form View
                      Column(
                        key: const ValueKey('signup'),
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white12,
                              backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                              child: _profileImagePath == null
                                  ? const Icon(Icons.add_a_photo, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _signUpFirstNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'First Name', labelStyle: TextStyle(color: Colors.grey)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _signUpLastNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'Last Name', labelStyle: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _signUpEmailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.grey)),
                          ),
                          TextField(
                            controller: _signUpPhoneController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Colors.grey)),
                          ),
                          TextField(
                            controller: _signUpPasswordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('I am a:', style: TextStyle(color: Colors.grey)),
                              DropdownButton<String>(
                                dropdownColor: const Color(0xff1e1e1e),
                                value: _selectedRole,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                items: ['Buyer', 'Seller', 'Both'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('I accept the Terms & Privacy Policy', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            value: _acceptTerms,
                            activeColor: const Color(0xffFF5722),
                            onChanged: (val) {
                              if (val != null) setState(() => _acceptTerms = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
                              onPressed: _acceptTerms ? () => _handleMockSignUp(authProvider) : null,
                              child: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR CONNECT WITH', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 24),

              // OAuth Social Connects
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () => authProvider.loginGoogle(),
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xffFF5722)),
                        label: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () {
                          // Facebook login not yet implemented in V1 MVP
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facebook login coming soon')));
                        },
                        icon: const Icon(Icons.facebook, size: 20, color: Colors.blue),
                        label: const Text('Facebook', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
