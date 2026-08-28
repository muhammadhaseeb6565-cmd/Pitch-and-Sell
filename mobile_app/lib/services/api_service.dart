import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final _supabase = Supabase.instance.client;

  // Real Auth API with ID Token verification (Supabase handles this now via auth_provider, returning dummy 200)
  static Future<http.Response> googleSignInReal(String? idToken, String email, String? name, String? avatarUrl) async {
    return http.Response('{}', 200);
  }

  static Future<http.Response> getMe() async {
    return http.Response('{}', 200);
  }

  // Products & Feed API
  static Future<http.Response> getFeed({String? category, String? search}) async {
    try {
      var query = _supabase.from('products').select('*, profiles:seller_id(*)');
      if (category != null && category != 'All') query = query.eq('category', category);
      if (search != null && search.isNotEmpty) query = query.ilike('name', '%$search%');
      
      final data = await query.order('created_at', ascending: false);
      final productsList = data.map((item) {
        return {
          'id': item['id'],
          'name': item['name'],
          'description': item['description'] ?? '',
          'price': item['price'],
          'business': {'name': item['profiles']?['business_name'] ?? item['profiles']?['name'] ?? 'Seller'},
          'video': {
            'url': item['video_url'],
            'likesCount': 0,
            'allowDownload': item['allow_download'] ?? false,
          }
        };
      }).toList();
      return http.Response(jsonEncode({'products': productsList}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
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
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);

      String finalUrl = videoUrl ?? '';
      
      // Upload to Supabase Storage if file is provided
      if (videoPath != null && videoPath.isNotEmpty) {
        final file = File(videoPath);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id}.mp4';
        await _supabase.storage.from('videos').upload(fileName, file);
        finalUrl = _supabase.storage.from('videos').getPublicUrl(fileName);
      }

      final res = await _supabase.from('products').insert({
        'seller_id': user.id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
        'allow_download': allowDownload,
        'video_url': finalUrl,
      }).select();

      return http.Response(jsonEncode({'product': res.first}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Likes
  static Future<http.Response> toggleLike(String videoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      await _supabase.from('likes').insert({'user_id': user.id, 'product_id': videoId});
      return http.Response('{}', 200);
    } catch (e) {
      return http.Response('{}', 200); // ignore duplicates
    }
  }
  static Future<http.Response> likeVideo(String videoId) => toggleLike(videoId);

  // Comments
  static Future<http.Response> getComments(String videoId) async {
    try {
      final data = await _supabase.from('comments').select('*, profiles:user_id(*)').eq('product_id', videoId).order('created_at', ascending: false);
      final mapped = data.map((c) => {
        'id': c['id'],
        'text': c['text'],
        'user': {
          'name': c['profiles']?['name'] ?? 'User',
          'avatarUrl': c['profiles']?['avatar'],
        },
        'createdAt': c['created_at'],
      }).toList();
      return http.Response(jsonEncode(mapped), 200);
    } catch (e) {
      return http.Response('[]', 500);
    }
  }

  static Future<http.Response> addComment(String videoId, String text) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      await _supabase.from('comments').insert({'user_id': user.id, 'product_id': videoId, 'text': text});
      return http.Response('{}', 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Orders API
  static Future<http.Response> createOrder(String productId, int quantity, String paymentMethod) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final product = await _supabase.from('products').select('seller_id, price').eq('id', productId).single();
      
      final res = await _supabase.from('orders').insert({
        'buyer_id': user.id,
        'seller_id': product['seller_id'],
        'product_id': productId,
        'quantity': quantity,
        'total_price': (product['price'] as num) * quantity,
        'payment_method': paymentMethod,
        'status': 'pending'
      }).select();
      return http.Response(jsonEncode(res.first), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> getOrders(String mode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      final column = mode == 'seller' ? 'seller_id' : 'buyer_id';
      final data = await _supabase.from('orders').select('*, products(*)').eq(column, user.id).order('created_at', ascending: false);
      
      final mapped = data.map((o) => {
        'id': o['id'],
        'status': o['status'],
        'totalAmount': o['total_price'],
        'createdAt': o['created_at'],
        'product': {
          'name': o['products']?['name'] ?? 'Product',
          'video': {'url': o['products']?['video_url']},
        }
      }).toList();
      return http.Response(jsonEncode({'orders': mapped}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> updateOrderStatus(String orderId, String status) async {
    await _supabase.from('orders').update({'status': status}).eq('id', orderId);
    return http.Response('{}', 200);
  }
  static Future<http.Response> cancelOrder(String orderId) => updateOrderStatus(orderId, 'cancelled');

  // Business Profile
  static Future<http.Response> createBusiness(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    await _supabase.from('profiles').update({
      'is_business': true,
      'business_name': data['businessName'],
      'business_description': data['description'],
      'role': 'seller',
    }).eq('id', user!.id);
    return http.Response('{}', 200);
  }
  static Future<http.Response> updateBusiness(Map<String, dynamic> data) => createBusiness(data);

  // Profile
  static Future<http.Response> updateProfile(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    await _supabase.from('profiles').update({
      'name': data['name'],
      'avatar': data['avatarUrl'], // we fixed this in UI but sending as avatarUrl
    }).eq('id', user!.id);
    return http.Response('{}', 200);
  }

  // Dashboard / Ledger Mocks (Need complex joins for real data, returning mock 200 for now to keep UI alive)
  static Future<http.Response> getLedger() async {
    return http.Response(jsonEncode({'balance': 0, 'pendingPayouts': 0}), 200);
  }
  static Future<http.Response> requestPayout(double amount, String method, String details) async {
    return http.Response('{}', 200);
  }
  static Future<http.Response> createOffer(Map<String, dynamic> offerData) async {
    return http.Response('{}', 200);
  }
  static Future<http.Response> acceptOffer(String offerId) async {
    return http.Response('{}', 200);
  }
  static Future<http.Response> generatePitchScript(Map<String, dynamic> body) async {
    return http.Response(jsonEncode({'script': 'Supabase AI Script generation coming soon.'}), 200);
  }
  static Future<http.Response> promoteProduct(String productId, String plan) async {
    return http.Response('{}', 200);
  }
  
  // Dummy methods to satisfy imports if needed
  static Future<void> init() async {}
  static Future<void> setToken(String token) async {}
  static Future<void> clearToken() async {}
}