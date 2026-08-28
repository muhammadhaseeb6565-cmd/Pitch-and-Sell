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

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  bool get hasBusinessProfile => _user != null && _user!['businessProfile'] != null;
  String? get businessStatus => hasBusinessProfile ? _user!['businessProfile']['status'] : null;

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
        _setUserFromSupabase(res.user!);
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      debugPrint('Supabase Sign-In Error: ${e.message}');
    } catch (e) {
      debugPrint('Sign-In Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign Up with Email
  Future<bool> signUpWithEmail(String email, String password, String firstName, String lastName, String phone, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final fullName = '$firstName $lastName'.trim();
      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName, 'phone': phone, 'role': role},
      );
      if (res.user != null) {
        _setUserFromSupabase(res.user!);
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      debugPrint('Supabase Sign-Up Error: ${e.message}');
    } catch (e) {
      debugPrint('Sign-Up Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
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
        debugPrint('Google idToken is null');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      if (res.user != null) {
        _setUserFromSupabase(res.user!);
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      debugPrint('Supabase Google Error: ${e.message}');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Check session on app start
  Future<void> checkSession() async {
    try {
      final Session? session = _supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        final User? su = _supabase.auth.currentUser;
        if (su != null) {
          _setUserFromSupabase(su);
          await _saveSessionLocally();
          notifyListeners();
          return;
        }
      }
      // Try refresh
      try {
        final AuthResponse res = await _supabase.auth.refreshSession();
        if (res.user != null) {
          _setUserFromSupabase(res.user!);
          await _saveSessionLocally();
          notifyListeners();
          return;
        }
      } catch (_) {}
      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = jsonDecode(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Session check error: $e');
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
  void _setUserFromSupabase(User supabaseUser) {
    final meta = supabaseUser.userMetadata ?? {};
    _user = {
      'id': supabaseUser.id,
      'email': supabaseUser.email,
      'name': meta['full_name'] ?? meta['name'] ?? (supabaseUser.email?.split('@').first ?? 'User'),
      'avatar': meta['avatar_url'] ?? meta['picture'],
      'phone': supabaseUser.phone ?? meta['phone'],
      'role': meta['role'] ?? 'user',
      'businessProfile': meta['businessProfile'],
    };
    _isAuthenticated = true;
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