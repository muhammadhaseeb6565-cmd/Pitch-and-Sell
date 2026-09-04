import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final String initialMode;
  const WelcomeScreen({super.key, this.initialMode = 'customer'});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInEmailCtrl = TextEditingController();
  final _signInPassCtrl = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFirstCtrl = TextEditingController();
  final _signUpLastCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPhoneCtrl = TextEditingController();
  final _signUpPassCtrl = TextEditingController();
  final _signUpConfirmPassCtrl = TextEditingController();
  final _signUpShopNameCtrl = TextEditingController();
  final _signUpShopDescCtrl = TextEditingController();
  final _signUpFormKey = GlobalKey<FormState>();
  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  String? _profileImagePath;
  String _selectedMode = 'customer';
  String _signInSelectedMode = 'customer';

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailCtrl.dispose(); _signInPassCtrl.dispose();
    _signUpFirstCtrl.dispose(); _signUpLastCtrl.dispose();
    _signUpEmailCtrl.dispose(); _signUpPhoneCtrl.dispose();
    _signUpPassCtrl.dispose(); _signUpConfirmPassCtrl.dispose();
    _signUpShopNameCtrl.dispose(); _signUpShopDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null && mounted) setState(() => _profileImagePath = file.path);
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xff2e7d32),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xffc62828),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _goToMain() {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
  }

  Future<void> _handleSignIn(AuthProvider auth) async {
    if (!_signInFormKey.currentState!.validate()) return;
    try {
      final success = await auth.signInWithEmail(_signInEmailCtrl.text.trim(), _signInPassCtrl.text);
      if (success && mounted) {
        // Apply the selected role from the sign-in form
        final currentRole = auth.user?['role']?.toString().toLowerCase();
        if (currentRole != _signInSelectedMode) {
          await auth.setAccountRole(_signInSelectedMode);
        }
        _showSuccess('Welcome back! Signed in successfully 🎉');
        await Future.delayed(const Duration(milliseconds: 600));
        _goToMain();
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (msg.contains('Invalid login') || msg.contains('invalid_credentials')) {
        _showError('Incorrect email or password. Please try again.');
      } else if (msg.contains('Email not confirmed')) {
        _showError('Please verify your email first. Check your inbox.');
      } else {
        _showError(msg);
      }
    }
  }

  Future<void> _handleSignUp(AuthProvider auth) async {
    if (!_signUpFormKey.currentState!.validate()) return;
    if (_selectedMode == 'seller' && _signUpShopNameCtrl.text.trim().isEmpty) {
      _showError('Please enter your Shop / Store Name.');
      return;
    }
    if (!_acceptTerms) {
      _showError('Please accept the Terms & Privacy Policy to continue.');
      return;
    }
    try {
      final success = await auth.signUpWithEmail(
        email: _signUpEmailCtrl.text.trim(),
        password: _signUpPassCtrl.text,
        firstName: _signUpFirstCtrl.text.trim(),
        lastName: _signUpLastCtrl.text.trim(),
        phone: _signUpPhoneCtrl.text.trim(),
        role: _selectedMode,
        shopName: _selectedMode == 'seller' ? _signUpShopNameCtrl.text.trim() : null,
        shopDescription: _selectedMode == 'seller' ? _signUpShopDescCtrl.text.trim() : null,
      );
      if (success && mounted) {
        _showSuccess('Account created! Welcome to Pitch & Sell!');
        await Future.delayed(const Duration(milliseconds: 600));
        _goToMain();
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        _showError('Email already registered. Try signing in instead.');
      } else if (msg.contains('check your email') || msg.contains('confirm')) {
        _showSuccess('Account created! Please verify your email to continue.');
      } else {
        _showError(msg);
      }
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    try {
      final success = await auth.loginGoogle();
      if (success && mounted) {
        final user = auth.user;
        final currentRole = user?['role']?.toString().toLowerCase();
        if (currentRole == null || currentRole == 'user') {
          _showGoogleRoleSelectionDialog(auth);
          return;
        }
        _showSuccess('Signed in with Google successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        _goToMain();
      }
    } catch (e) {
      _showError('Google Sign-In failed. Please use email & password.');
    }
  }

  void _showGoogleRoleSelectionDialog(AuthProvider auth) {
    String selectedRole = 'customer';
    final shopNameCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xff1e1e1e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Select Account Type',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you joining Pitch & Sell as a Customer or a Shop?',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedRole = 'customer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedRole == 'customer' ? const Color(0xffFF5722).withOpacity(0.15) : const Color(0xff2a2a2a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedRole == 'customer' ? const Color(0xffFF5722) : Colors.white12,
                                width: selectedRole == 'customer' ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.shopping_bag_outlined, color: selectedRole == 'customer' ? const Color(0xffFF5722) : Colors.grey, size: 24),
                                const SizedBox(height: 6),
                                Text('Customer', style: TextStyle(color: selectedRole == 'customer' ? const Color(0xffFF5722) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const Text('Browse & Buy', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedRole = 'seller'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedRole == 'seller' ? const Color(0xffFF5722).withOpacity(0.15) : const Color(0xff2a2a2a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedRole == 'seller' ? const Color(0xffFF5722) : Colors.white12,
                                width: selectedRole == 'seller' ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.storefront_outlined, color: selectedRole == 'seller' ? const Color(0xffFF5722) : Colors.grey, size: 24),
                                const SizedBox(height: 6),
                                Text('Shop / Seller', style: TextStyle(color: selectedRole == 'seller' ? const Color(0xffFF5722) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const Text('Pitch & Sell', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedRole == 'seller') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: shopNameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Shop / Store Name *',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xff2a2a2a),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.store, color: Color(0xffFF5722), size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (selectedRole == 'seller' && shopNameCtrl.text.trim().isEmpty) {
                    _showError('Please enter your Shop Name');
                    return;
                  }
                  Navigator.pop(dialogCtx);
                  try {
                    await auth.setAccountRole(
                      selectedRole,
                      shopName: selectedRole == 'seller' ? shopNameCtrl.text.trim() : null,
                    );
                    _showSuccess('Welcome to Pitch & Sell!');
                    _goToMain();
                  } catch (e) {
                    _showError('Failed to set role. Please try again.');
                  }
                },
                child: const Text('Continue', style: TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _signInEmailCtrl.text.trim();
    if (email.isEmpty) { _showError('Enter your email address above first.'); return; }
    try {
      await Provider.of<AuthProvider>(context, listen: false).resetPassword(email);
      _showSuccess('Password reset link sent to $email!');
    } catch (e) {
      _showError('Could not send reset email. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoading = auth.isLoading;
    return Scaffold(
      backgroundColor: const Color(0xff0f0f0f),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(children: [
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xffFF5722).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffFF5722).withOpacity(0.3)),
                ),
                child: const Icon(Icons.smart_toy_outlined, size: 28, color: Color(0xffFF5722)),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PITCH & SELL', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                Text('Pitch It. Sell It. Grow It.', style: TextStyle(color: Color(0xffFF5722), fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 36),
            Container(
              decoration: BoxDecoration(color: const Color(0xff1a1a1a), borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: const Color(0xffFF5722), borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabController.index == 0 ? _buildSignInForm(auth, isLoading) : _buildSignUpForm(auth, isLoading),
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(child: Divider(color: Colors.white12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1)),
              ),
              const Expanded(child: Divider(color: Colors.white12)),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : () => _handleGoogleSignIn(auth),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: const Center(child: Text('G', style: TextStyle(color: Color(0xffDB4437), fontWeight: FontWeight.w900, fontSize: 14))),
                  ),
                  const SizedBox(width: 12),
                  const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildSignInForm(AuthProvider auth, bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(key: const ValueKey('signin'), crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Sign in to your account', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),

        // Account Type Selection for Sign In
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffFF5722).withOpacity(0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.how_to_reg_rounded, color: Color(0xffFF5722), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'SIGN IN AS',
                    style: TextStyle(color: Color(0xffFF5722), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _signInModeCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Customer',
                    subtitle: 'Browse & Buy',
                    value: 'customer',
                  ),
                  const SizedBox(width: 12),
                  _signInModeCard(
                    icon: Icons.storefront_outlined,
                    label: 'Shop / Seller',
                    subtitle: 'Pitch & Sell',
                    value: 'seller',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _field(controller: _signInEmailCtrl, label: 'Email Address', icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) { if (v == null || v.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Enter a valid email'; return null; }),
        const SizedBox(height: 16),
        _field(controller: _signInPassCtrl, label: 'Password', icon: Icons.lock_outlined,
          obscure: _obscureSignIn, toggleObscure: () => setState(() => _obscureSignIn = !_obscureSignIn),
          validator: (v) { if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Minimum 6 characters'; return null; }),
        Align(alignment: Alignment.centerRight,
          child: TextButton(onPressed: isLoading ? null : _handleForgotPassword,
            child: const Text('Forgot Password?', style: TextStyle(color: Color(0xffFF5722), fontSize: 12)))),
        const SizedBox(height: 8),
        _btn(
          label: _signInSelectedMode == 'seller' ? 'Sign In as Seller' : 'Sign In as Customer',
          icon: _signInSelectedMode == 'seller' ? Icons.storefront_rounded : Icons.login_rounded,
          isLoading: isLoading,
          onPressed: () => _handleSignIn(auth),
        ),
      ]),
    );
  }

  Widget _buildSignUpForm(AuthProvider auth, bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: Column(key: const ValueKey('signup'), crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Create an Account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Select your account type to get started', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),

        // 1. MANDATORY ACCOUNT TYPE SELECTION (TOP OF FORM)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffFF5722).withOpacity(0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.how_to_reg_rounded, color: Color(0xffFF5722), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'STEP 1: SELECT YOUR ACCOUNT TYPE *',
                    style: TextStyle(color: Color(0xffFF5722), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _modeCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Customer',
                    subtitle: 'Browse & Buy',
                    value: 'customer',
                  ),
                  const SizedBox(width: 12),
                  _modeCard(
                    icon: Icons.storefront_outlined,
                    label: 'Shop / Seller',
                    subtitle: 'Pitch & Sell',
                    value: 'seller',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. CONDITIONAL SHOP INFORMATION (If Shop selected)
        if (_selectedMode == 'seller') ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xff1e1e1e),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffFF5722).withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.store, color: Color(0xffFF5722), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'SHOP / STORE DETAILS',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _signUpShopNameCtrl,
                  label: 'Shop / Business Name *',
                  icon: Icons.store_mall_directory_outlined,
                  validator: (v) {
                    if (_selectedMode == 'seller' && (v == null || v.trim().isEmpty)) {
                      return 'Shop Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _signUpShopDescCtrl,
                  label: 'What does your shop sell? (e.g. Shoes, Watches)',
                  icon: Icons.category_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. PERSONAL & LOGIN DETAILS
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xff1e1e1e),
                  backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                  child: _profileImagePath == null ? const Icon(Icons.person, color: Colors.grey, size: 36) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Color(0xffFF5722), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _field(
            controller: _signUpFirstCtrl,
            label: _selectedMode == 'seller' ? 'Owner First Name' : 'First Name',
            icon: Icons.person_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          )),
          const SizedBox(width: 12),
          Expanded(child: _field(
            controller: _signUpLastCtrl,
            label: _selectedMode == 'seller' ? 'Owner Last Name' : 'Last Name',
            icon: Icons.person_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          )),
        ]),
        const SizedBox(height: 14),
        _field(
          controller: _signUpEmailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _field(
          controller: _signUpPhoneCtrl,
          label: 'Phone Number (e.g. 03001234567)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Phone is required';
            if (v.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _field(
          controller: _signUpPassCtrl,
          label: 'Password',
          icon: Icons.lock_outlined,
          obscure: _obscureSignUp,
          toggleObscure: () => setState(() => _obscureSignUp = !_obscureSignUp),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must include uppercase letter';
            if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include a number';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _field(
          controller: _signUpConfirmPassCtrl,
          label: 'Confirm Password',
          icon: Icons.lock_outlined,
          obscure: _obscureConfirm,
          toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm password';
            if (v != _signUpPassCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _acceptTerms ? const Color(0xffFF5722) : Colors.transparent,
                border: Border.all(color: _acceptTerms ? const Color(0xffFF5722) : Colors.white30, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _acceptTerms ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('I agree to the Terms of Service & Privacy Policy',
              style: TextStyle(color: Colors.grey, fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 22),
        _btn(
          label: _selectedMode == 'seller' ? 'Register My Shop' : 'Create Customer Account',
          icon: _selectedMode == 'seller' ? Icons.storefront_rounded : Icons.person_add_rounded,
          isLoading: isLoading,
          onPressed: () => _handleSignUp(auth),
        ),
      ]),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon,
    bool obscure = false, VoidCallback? toggleObscure, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator, autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: toggleObscure != null ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
          onPressed: toggleObscure) : null,
        filled: true, fillColor: const Color(0xff1a1a1a),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffFF5722), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _modeCard({required IconData icon, required String label, required String subtitle, required String value}) {
    final sel = _selectedMode == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xffFF5722).withOpacity(0.12) : const Color(0xff1a1a1a),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? const Color(0xffFF5722) : Colors.white10, width: sel ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? const Color(0xffFF5722) : Colors.grey, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: sel ? const Color(0xffFF5722) : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    ));
  }

  Widget _signInModeCard({required IconData icon, required String label, required String subtitle, required String value}) {
    final sel = _signInSelectedMode == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _signInSelectedMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xffFF5722).withOpacity(0.12) : const Color(0xff1a1a1a),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? const Color(0xffFF5722) : Colors.white10, width: sel ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? const Color(0xffFF5722) : Colors.grey, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: sel ? const Color(0xffFF5722) : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    ));
  }

  Widget _btn({required String label, required IconData icon, required bool isLoading, required VoidCallback onPressed}) {
    return SizedBox(width: double.infinity, height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffFF5722), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 20), const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
      ));
  }
}

