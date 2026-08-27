import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

enum UserMode { customer, seller }

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _isAuthenticated = false;
  UserMode _currentMode = UserMode.customer;
  bool _isLoading = false;
  bool _isDarkMode = true;

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

  String? get businessStatus => hasBusinessProfile 
      ? _user!['businessProfile']['status'] 
      : null;

  Future<bool> loginGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '771454392765-jb01guktvorvh6pcktr5s2ntcann92f6.apps.googleusercontent.com',
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      // Send idToken to the real backend
      final response = await ApiService.googleSignInReal(idToken, googleUser.email, googleUser.displayName, googleUser.photoUrl).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.setToken(data['token']);
        _user = data['user'];
        _isAuthenticated = true;
        
        try {
          SocketService.connect(_user!['id']);
        } catch (_) {}
        
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('Backend rejected Google Sign-In: \${response.body}');
      }
    } catch (e) {
      print('Real Google Auth API Failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _saveSessionLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString('user_data', jsonEncode(_user));
      }
    } catch (e) {
      print('Error saving session locally: $e');
    }
  }

  Future<void> checkSession() async {
    await ApiService.init();
    try {
      final response = await ApiService.getMe().timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        _isAuthenticated = true;
        await _saveSessionLocally();
        SocketService.connect(_user!['id']);
      }
    } catch (e) {
      print('Session check failed via API: $e. Checking local storage...');
      // Fallback to local shared preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('user_data');
        if (userData != null) {
          _user = jsonDecode(userData);
          _isAuthenticated = true;
          // Optionally connect socket if it makes sense offline
        }
      } catch (err) {
        print('Local session restore failed: $err');
      }
    }
    notifyListeners();
  }

  void toggleUserMode() {
    if (_currentMode == UserMode.customer) {
      _currentMode = UserMode.seller;
    } else {
      _currentMode = UserMode.customer;
    }
    notifyListeners();
  }

  Future<void> reloadUserProfile() async {
    try {
      final response = await ApiService.getMe();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        await _saveSessionLocally();
        notifyListeners();
      }
    } catch (e) {
      print('Profile refresh failed: $e');
    }
  }

  // Allow updating user fields like avatar locally without hitting the server
  Future<void> updateUserLocalField(String key, dynamic value) async {
    if (_user != null) {
      _user![key] = value;
      await _saveSessionLocally();
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        await ApiService.setToken(_token!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Email Sign-In Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithEmail(String email, String password, String firstName, String lastName, String phone, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final name = '$firstName $lastName'.trim();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'role': role.toUpperCase() == 'BOTH' ? 'USER' : 'USER'
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        await ApiService.setToken(_token!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Email Sign-Up Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {}
    SocketService.disconnect();
    _user = null;
    _isAuthenticated = false;
    _currentMode = UserMode.customer;
    notifyListeners();
  }
}
