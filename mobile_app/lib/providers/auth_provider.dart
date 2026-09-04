import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/socket_service.dart';

enum UserMode { customer, seller }

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  UserMode _currentMode = UserMode.customer;
  bool _isLoading = false;
  bool _isDarkMode = true;

  SupabaseClient get _supabase => Supabase.instance.client;

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  UserMode get currentMode => _currentMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;

    Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  bool get hasBusinessProfile =>
      _user != null &&
      (_user!['is_business'] == true ||
          _user!['role'] == 'seller' ||
          _user!['role'] == 'shop' ||
          _user!['businessProfile'] != null);

  String? get businessStatus => hasBusinessProfile ? (_user!['businessProfile']?['status'] ?? 'verified') : null;

  // Sign In with Email
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user != null) {
        await _setUserFromSupabase(res.user!);
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign Up with Email & explicit Account Type (Customer vs Shop)
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role, // 'seller' or 'customer'
    String? shopName,
    String? shopDescription,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final fullName = '$firstName $lastName'.trim();
      final isSeller = role == 'seller' || role == 'shop';
      final effectiveRole = isSeller ? 'seller' : 'customer';

      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': effectiveRole,
          'is_business': isSeller,
          'business_name': isSeller ? (shopName ?? fullName) : null,
          'business_description': isSeller ? shopDescription : null,
        },
        emailRedirectTo: 'io.supabase.pitchandsell://login-callback/',
      );

      if (res.user != null) {
        // Guarantee user row in public.profiles table
        try {
          await _supabase.from('profiles').upsert({
            'id': res.user!.id,
            'name': fullName,
            'email': email.trim(),
            'phone': phone,
            'role': effectiveRole,
            'is_business': isSeller,
            'business_name': isSeller ? (shopName ?? fullName) : null,
            'business_description': isSeller ? shopDescription : null,
          });
        } catch (e) {
          debugPrint('Error inserting into profiles: $e');
        }

        if (res.session == null) {
          throw Exception("Please check your email to confirm your account!");
        }
        await _setUserFromSupabase(res.user!);
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Update Account Role post-signup or Google OAuth
  Future<void> setAccountRole(String role, {String? shopName, String? shopDescription}) async {
    if (_user == null) return;
    final isSeller = role == 'seller' || role == 'shop';
    final effectiveRole = isSeller ? 'seller' : 'customer';
    try {
      await _supabase.from('profiles').update({
        'role': effectiveRole,
        'is_business': isSeller,
        'business_name': isSeller ? (shopName ?? _user!['name']) : null,
        'business_description': isSeller ? shopDescription : null,
      }).eq('id', _user!['id']);

      _user!['role'] = effectiveRole;
      _user!['is_business'] = isSeller;
      if (isSeller) {
        _user!['businessProfile'] = {
          'id': _user!['id'],
          'name': shopName ?? _user!['name'] ?? 'Shop',
          'description': shopDescription ?? '',
          'status': 'verified',
          'is_business': true,
        };
        _currentMode = UserMode.seller;
      } else {
        _user!['businessProfile'] = null;
        _currentMode = UserMode.customer;
      }
      await _saveSessionLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating role: $e');
      rethrow;
    }
  }

  // Google Sign In
  Future<bool> loginGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '771454392765-jb01guktvorvh6pcktr5s2ntcann92f6.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception("Google Sign-In failed: Missing ID Token. Check SHA-1 configuration.");
      }
      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      if (res.user != null) {
        await _setUserFromSupabase(res.user!);
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Check session on app start - strictly verify session with Supabase
  Future<void> checkSession() async {
    try {
      final Session? session = _supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        final User? su = _supabase.auth.currentUser;
        if (su != null) {
          await _setUserFromSupabase(su);
          await _saveSessionLocally();
          notifyListeners();
          return;
        }
      }
      // Try refresh
      try {
        final AuthResponse res = await _supabase.auth.refreshSession();
        if (res.user != null) {
          await _setUserFromSupabase(res.user!);
          await _saveSessionLocally();
          notifyListeners();
          return;
        }
      } catch (_) {}

      // If no valid active session in Supabase, user is NOT authenticated!
      _user = null;
      _isAuthenticated = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Session check error: $e');
      _user = null;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try { await _supabase.auth.signOut(); } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (_) {}
    try { SocketService.disconnect(); } catch (_) {}
    _user = null;
    _isAuthenticated = false;
    _currentMode = UserMode.customer;
    notifyListeners();
  }

  // Internal helpers
  Future<void> _setUserFromSupabase(User supabaseUser) async {
    final meta = supabaseUser.userMetadata ?? {};

    // Fetch profile from public.profiles table
    Map<String, dynamic>? profileData;
    try {
      profileData = await _supabase.from('profiles').select('*').eq('id', supabaseUser.id).maybeSingle();
    } catch (e) {
      debugPrint('Error fetching profile from Supabase: $e');
    }

    final String rawRole = (profileData?['role'] ?? meta['role'] ?? 'customer').toString().toLowerCase();
    final bool isBusiness = profileData?['is_business'] == true ||
        rawRole == 'seller' ||
        rawRole == 'shop' ||
        meta['is_business'] == true;

    final String? businessName = profileData?['business_name'] ?? meta['business_name'];
    final String? businessDesc = profileData?['business_description'] ?? meta['business_description'];

    Map<String, dynamic>? bProfile;
    if (isBusiness) {
      bProfile = {
        'id': supabaseUser.id,
        'name': businessName ?? profileData?['name'] ?? meta['full_name'] ?? 'Shop',
        'description': businessDesc ?? '',
        'status': 'verified',
        'is_business': true,
      };
    }

    _user = {
      'id': supabaseUser.id,
      'email': supabaseUser.email,
      'name': profileData?['name'] ?? meta['full_name'] ?? meta['name'] ?? (supabaseUser.email?.split('@').first ?? 'User'),
      'avatar': profileData?['avatar'] ?? meta['avatar_url'] ?? meta['picture'],
      'phone': supabaseUser.phone ?? meta['phone'] ?? profileData?['phone'],
      'role': isBusiness ? 'seller' : 'customer',
      'is_business': isBusiness,
      'businessProfile': bProfile,
    };
    _isAuthenticated = true;
    _currentMode = isBusiness ? UserMode.seller : UserMode.customer;
    try { SocketService.connect(_user!['id']); } catch (_) {}
  }

  Future<void> _saveSessionLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) await prefs.setString('user_data', jsonEncode(_user));
    } catch (_) {}
  }

  Future<void> updateUserLocalField(String key, dynamic value) async {
    if (_user != null) {
      _user![key] = value;
      await _saveSessionLocally();
      notifyListeners();
    }
  }

  Future<void> reloadUserProfile() async {
    final su = _supabase.auth.currentUser;
    if (su != null) {
      _setUserFromSupabase(su);
      await _saveSessionLocally();
      notifyListeners();
    }
  }

  void toggleUserMode() {
    _currentMode = _currentMode == UserMode.customer ? UserMode.seller : UserMode.customer;
    notifyListeners();
  }
}
