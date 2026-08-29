import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
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
  final _signUpFormKey = GlobalKey<FormState>();
  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  String? _profileImagePath;
  String _selectedMode = 'customer';

  @override
  void initState() {
    super.initState();
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
        _showSuccess('Welcome back! Signed in successfully ✓');
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
    if (!_acceptTerms) { _showError('Please accept the Terms & Privacy Policy to continue.'); return; }
    try {
      final success = await auth.signUpWithEmail(
        _signUpEmailCtrl.text.trim(), _signUpPassCtrl.text,
        _signUpFirstCtrl.text.trim(), _signUpLastCtrl.text.trim(),
        _signUpPhoneCtrl.text.trim(), _selectedMode,
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
        _showSuccess('Signed in with Google successfully ✓');
        await Future.delayed(const Duration(milliseconds: 500));
        _goToMain();
      }
    } catch (e) {
      _showError('Google Sign-In failed. Please use email & password.');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _signInEmailCtrl.text.trim();
    if (email.isEmpty) { _showError('Enter your email address above first.'); return; }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
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
        const SizedBox(height: 24),
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
        _btn(label: 'Sign In', icon: Icons.login_rounded, isLoading: isLoading, onPressed: () => _handleSignIn(auth)),
      ]),
    );
  }

  Widget _buildSignUpForm(AuthProvider auth, bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: Column(key: const ValueKey('signup'), crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Create an account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Join Pitch & Sell today', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        Center(child: GestureDetector(onTap: _pickImage, child: Stack(children: [
          CircleAvatar(radius: 42, backgroundColor: const Color(0xff1e1e1e),
            backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
            child: _profileImagePath == null ? const Icon(Icons.person, color: Colors.grey, size: 40) : null),
          Positioned(bottom: 0, right: 0, child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xffFF5722), shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14))),
        ]))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _field(controller: _signUpFirstCtrl, label: 'First Name', icon: Icons.person_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: _field(controller: _signUpLastCtrl, label: 'Last Name', icon: Icons.person_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
        ]),
        const SizedBox(height: 16),
        _field(controller: _signUpEmailCtrl, label: 'Email Address', icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) { if (v == null || v.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Enter a valid email'; return null; }),
        const SizedBox(height: 16),
        _field(controller: _signUpPhoneCtrl, label: 'Phone (e.g. 03001234567)', icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) { if (v == null || v.isEmpty) return 'Phone is required';
            if (v.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a valid phone number'; return null; }),
        const SizedBox(height: 16),
        _field(controller: _signUpPassCtrl, label: 'Password', icon: Icons.lock_outlined,
          obscure: _obscureSignUp, toggleObscure: () => setState(() => _obscureSignUp = !_obscureSignUp),
          validator: (v) { if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must include uppercase letter';
            if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include a number'; return null; }),
        const SizedBox(height: 16),
        _field(controller: _signUpConfirmPassCtrl, label: 'Confirm Password', icon: Icons.lock_outlined,
          obscure: _obscureConfirm, toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          validator: (v) { if (v == null || v.isEmpty) return 'Please confirm password';
            if (v != _signUpPassCtrl.text) return 'Passwords do not match'; return null; }),
        const SizedBox(height: 20),
        const Text('I want to use Pitch & Sell as:', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          _modeCard(icon: Icons.shopping_bag_outlined, label: 'Customer', subtitle: 'Browse & buy', value: 'customer'),
          const SizedBox(width: 12),
          _modeCard(icon: Icons.storefront_outlined, label: 'Shop', subtitle: 'Pitch & sell', value: 'seller'),
        ]),
        const SizedBox(height: 20),
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
        const SizedBox(height: 24),
        _btn(label: 'Create Account', icon: Icons.person_add_rounded, isLoading: isLoading, onPressed: () => _handleSignUp(auth)),
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
