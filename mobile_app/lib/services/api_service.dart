import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    return 'https://pitch-and-sell-backend.onrender.com/api';
  }
  static String? _token;
  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    _token = await _storage.read(key: 'auth_token');
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Real Auth API with ID Token verification
  static Future<http.Response> googleSignInReal(String? idToken, String email, String? name, String? avatarUrl) async {
    return http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: _headers,
      body: jsonEncode({
        'idToken': idToken,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
      }),
    );
  }

  static Future<http.Response> getMe() async {
    return http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
  }

  // Business API
  static Future<http.Response> createBusiness(Map<String, dynamic> data) async {
    return http.post(
      Uri.parse('$baseUrl/business'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> updateProfile(Map<String, dynamic> data) async {
    return http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> getBusiness() async {
    return http.get(
      Uri.parse('$baseUrl/business'),
      headers: _headers,
    );
  }

  // Products & Feed API
  static Future<http.Response> getFeed({String? category, String? search}) async {
    String url = '$baseUrl/products/feed';
    final queryParams = <String>[];
    if (category != null) queryParams.add('category=$category');
    if (search != null) queryParams.add('search=$search');
    if (queryParams.isNotEmpty) {
      url += '?' + queryParams.join('&');
    }
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future<http.Response> toggleLike(String videoId) async {
    return http.post(
      Uri.parse('$baseUrl/products/video/$videoId/like'),
      headers: _headers,
    );
  }

  // Orders API
  static Future<http.Response> createOrder(String productId, int quantity, String paymentMethod) async {
    return http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'paymentMethod': paymentMethod,
      }),
    );
  }

  static Future<http.Response> getOrders(String mode) async {
    return http.get(
      Uri.parse('$baseUrl/orders?mode=$mode'),
      headers: _headers,
    );
  }

  static Future<http.Response> updateOrderStatus(String orderId, String status) async {
    return http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
  }

  // Ledger & Payouts API
  static Future<http.Response> getLedger() async {
    return http.get(
      Uri.parse('$baseUrl/orders/ledger'),
      headers: _headers,
    );
  }

  static Future<http.Response> requestPayout(double amount, String method, String details) async {
    return http.post(
      Uri.parse('$baseUrl/orders/payout'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'method': method,
        'details': details,
      }),
    );
  }

  // Wholesale Offer API
  static Future<http.Response> createOffer(Map<String, dynamic> offerData) async {
    return http.post(
      Uri.parse('$baseUrl/orders/offer'),
      headers: _headers,
      body: jsonEncode(offerData),
    );
  }

  static Future<http.Response> acceptOffer(String offerId) async {
    return http.post(
      Uri.parse('$baseUrl/orders/offer/$offerId/accept'),
      headers: _headers,
    );
  }

  // AI Script Generation API
  static Future<http.Response> generatePitchScript(Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('$baseUrl/ai/generate-pitch'),
      headers: _headers,
      body: jsonEncode(body),
    );
  }

  // Cancel Order API
  static Future<http.Response> cancelOrder(String orderId) async {
    return http.post(
      Uri.parse('$baseUrl/orders/$orderId/cancel'),
      headers: _headers,
    );
  }

  // Upload Product API
  static Future<http.Response> uploadProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required bool allowDownload,
    String? videoPath,
    String? videoUrl,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
    
    // Add headers
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Add form fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['category'] = category;
    request.fields['stock'] = stock.toString();
    request.fields['allowDownload'] = allowDownload.toString();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      request.fields['videoUrl'] = videoUrl;
    }

    // Add video file
    if (videoPath != null && videoPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('video', videoPath));
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // Update Business Profile API
  static Future<http.Response> updateBusiness(Map<String, dynamic> data) async {
    return http.put(
      Uri.parse('$baseUrl/business'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  // Promote/Boost Product API
  static Future<http.Response> promoteProduct(String productId, String plan) async {
    return await http.post(
      Uri.parse('$baseUrl/products/$productId/promote'),
      headers: _headers,
      body: jsonEncode({'plan': plan}),
    );
  }

  static Future<http.Response> getComments(String videoId) async {
    return await http.get(
      Uri.parse('$baseUrl/products/video/$videoId/comments'),
      headers: _headers,
    );
  }

  static Future<http.Response> addComment(String videoId, String text) async {
    return await http.post(
      Uri.parse('$baseUrl/products/video/$videoId/comments'),
      headers: _headers,
      body: jsonEncode({'text': text}),
    );
  }

  // Like Video API
  static Future<http.Response> likeVideo(String videoId) async {
    return http.post(
      Uri.parse('$baseUrl/products/like/$videoId'),
      headers: _headers,
    );
  }
}
