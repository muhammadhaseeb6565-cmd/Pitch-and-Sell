import 'package:video_compress/video_compress.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final _supabase = Supabase.instance.client;

  // Real Auth API with ID Token verification (Supabase handles this now via auth_provider, returning dummy 200)
  static Future<http.Response> googleSignInReal(String? idToken, String email, String? name, String? avatarUrl) async {
    return http.Response('{}', 200);
  }

  static Future<http.Response> getMe() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      final data = await _supabase.from('profiles').select('*').eq('id', user.id).maybeSingle();
      return http.Response(jsonEncode(data ?? {}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Products & Feed API
  static Future<http.Response> getFeed({String? category, String? search}) async {
    try {
      var query = _supabase.from('products').select('*, profiles:seller_id(*), reviews(rating)');
      if (category != null && category != 'All') query = query.eq('category', category);
      if (search != null && search.isNotEmpty) query = query.ilike('name', '%$search%');
      
      final data = await query.order('created_at', ascending: false);
      
      // Batch fetch like counts
      final allLikes = await _supabase.from('likes').select('product_id');
      final likesMap = <String, int>{};
      for (final l in allLikes) {
        final pid = l['product_id'] as String;
        likesMap[pid] = (likesMap[pid] ?? 0) + 1;
      }

      final productsList = data.map((item) {
        
        // Calculate average rating
        final reviews = item['reviews'] as List<dynamic>? ?? [];
        double avgRating = 0;
        if (reviews.isNotEmpty) {
          final total = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num));
          avgRating = total / reviews.length;
        }

        return {
          'id': item['id'],
          'name': item['name'],
          'description': item['description'] ?? '',
          'price': item['price'],
          'seller_id': item['seller_id'],
          'sizes': item['sizes'] ?? [],
          'colors': item['colors'] ?? [],
          'avgRating': avgRating,
          'reviewCount': reviews.length,
          'business': {'name': item['profiles']?['business_name'] ?? item['profiles']?['name'] ?? 'Seller'},
          'video': {
            'url': item['video_url'],
            'likesCount': likesMap[item['id']] ?? 0,
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
    List<String>? sizes,
    List<String>? colors,
    String? videoPath,
    String? videoUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);

      String finalUrl = videoUrl ?? '';
      
      // Upload to Supabase Storage if file is provided
      if (videoPath != null && videoPath.isNotEmpty) {
        // Compress Video
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          videoPath,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
        
        final file = File(mediaInfo?.file?.path ?? videoPath);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id}.mp4';
        
        await _supabase.storage.from('videos').upload(fileName, file);
        finalUrl = _supabase.storage.from('videos').getPublicUrl(fileName);
        
        // Free up space by deleting the temporary compressed file
        await VideoCompress.deleteAllCache();
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
        'sizes': sizes ?? [],
        'colors': colors ?? [],
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
      
      // Check if already liked
      final existing = await _supabase
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', videoId)
          .maybeSingle();
      
      if (existing != null) {
        // Unlike - delete
        await _supabase.from('likes').delete()
            .eq('user_id', user.id)
            .eq('product_id', videoId);
        return http.Response(jsonEncode({'liked': false}), 200);
      } else {
        // Like - insert
        await _supabase.from('likes').insert({'user_id': user.id, 'product_id': videoId});
        return http.Response(jsonEncode({'liked': true}), 200);
      }
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
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
      return http.Response(jsonEncode({'comments': mapped}), 200);
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

  static Future<http.Response> toggleSaveVideo(String videoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final existing = await _supabase.from('saved_videos').select('id').eq('user_id', user.id).eq('product_id', videoId).maybeSingle();
      if (existing != null) {
        await _supabase.from('saved_videos').delete().eq('user_id', user.id).eq('product_id', videoId);
        return http.Response(jsonEncode({'saved': false}), 200);
      } else {
        await _supabase.from('saved_videos').insert({'user_id': user.id, 'product_id': videoId});
        return http.Response(jsonEncode({'saved': true}), 200);
      }
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> getSavedVideos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final res = await _supabase.from('saved_videos').select('products(*)').eq('user_id', user.id);
      final products = res.map((r) => r['products']).toList();
      return http.Response(jsonEncode({'saved': products}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Orders API
  static Future<http.Response> createOrder(String productId, int quantity, String paymentMethod, {String? size, String? color}) async {
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
        'status': 'pending',
        'selected_size': size,
        'selected_color': color,
      }).select();
      return http.Response(jsonEncode(res.first), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Reviews API
  static Future<http.Response> addReview(String productId, double rating, String comment) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      await _supabase.from('reviews').insert({
        'buyer_id': user.id,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      });
      return http.Response('{}', 200);
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
        'productId': o['product_id'],
        'status': o['status'],
        'totalAmount': o['total_price'],
        'createdAt': o['created_at'],
        'trackingNumber': o['tracking_number'],
        'courierName': o['courier_name'],
        'shippedAt': o['shipped_at'],
        'quantity': o['quantity'],
        'paymentMethod': o['payment_method'],
        'unitPrice': o['products']?['price'],
        'selectedSize': o['selected_size'],
        'selectedColor': o['selected_color'],
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

  static Future<http.Response> updateOrderStatus(String orderId, String status, {String? trackingNumber, String? courierName}) async {
    try {
      final Map<String, dynamic> updates = {'status': status};
      if (status == 'shipped' || trackingNumber != null) {
        if (trackingNumber != null) updates['tracking_number'] = trackingNumber;
        if (courierName != null) updates['courier_name'] = courierName;
        updates['shipped_at'] = DateTime.now().toIso8601String();
      }
      await _supabase.from('orders').update(updates).eq('id', orderId);
      return http.Response('{}', 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  static Future<http.Response> cancelOrder(String orderId) => updateOrderStatus(orderId, 'cancelled');

  // Business Profile
  static Future<http.Response> createBusiness(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      await _supabase.from('profiles').update({
        'is_business': true,
        'business_name': data['businessName'],
        'business_description': data['description'],
        'role': 'seller',
      }).eq('id', user.id);
      return http.Response('{}', 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  static Future<http.Response> updateBusiness(Map<String, dynamic> data) => createBusiness(data);

  // Profile
  static Future<http.Response> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      await _supabase.from('profiles').update({
        'name': data['name'],
        'avatar': data['avatarUrl'], // we fixed this in UI but sending as avatarUrl
      }).eq('id', user.id);
      return http.Response('{}', 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Dashboard / Ledger (real Supabase data)
  static Future<http.Response> getLedger() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final orders = await _supabase.from('orders').select('id, total_price, platform_fee, status, created_at').eq('seller_id', user.id).order('created_at', ascending: false);
      
      double totalEarnings = 0;
      double pendingPayouts = 0;
      double totalFees = 0;
      List<Map<String, dynamic>> entries = [];

      for (final o in orders) {
        final amount = (o['total_price'] as num?)?.toDouble() ?? 0;
        final fee = (o['platform_fee'] as num?)?.toDouble() ?? 0;
        final netAmount = amount - fee;

        if (o['status'] == 'completed' || o['status'] == 'delivered' || o['status'] == 'paid') {
          totalEarnings += netAmount;
          totalFees += fee;
        }
        if (o['status'] == 'pending' || o['status'] == 'processing') {
          pendingPayouts += netAmount;
        }
        
        entries.add({
          'title': 'Sale Earning (Order ${o['id'].toString().substring(0,6)})',
          'amount': netAmount,
          'status': o['status'],
          'isCredit': true,
          'date': o['created_at'],
        });
      }

      try {
        final promotions = await _supabase.from('promotions').select('*').eq('seller_id', user.id).order('created_at', ascending: false);
        for (final p in promotions) {
          totalFees += 100;
          entries.add({
            'title': 'Promotion Fee (${p['plan_name']})',
            'amount': -100.0,
            'isCredit': false,
            'date': p['created_at'].toString().split('T')[0],
          });
          totalEarnings -= 100;
        }
      } catch (e) {
        // ignore missing promotions table if it happens
      }

      return http.Response(jsonEncode({
        'summary': {
          'grossSales': totalEarnings + pendingPayouts + totalFees,
          'netEarnings': totalEarnings,
          'pendingPayouts': pendingPayouts,
          'availableForPayout': totalEarnings,
          'totalFees': totalFees,
        },
        'entries': entries,
      }), 200);
    } catch (e) {
      return http.Response(jsonEncode({
        'error': e.toString(),
        'summary': {'grossSales': 0, 'netEarnings': 0, 'pendingPayouts': 0, 'availableForPayout': 0},
        'entries': []
      }), 500);
    }
  }

  static Future<http.Response> requestPayout(double amount, String method, String details) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      await _supabase.from('payouts').insert({
        'user_id': user.id,
        'amount': amount,
        'method': method,
        'details': details,
        'status': 'pending',
      });
      return http.Response(jsonEncode({'message': 'Payout request submitted successfully'}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> createOffer(Map<String, dynamic> offerData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final res = await _supabase.from('offers').insert({
        'buyer_id': user.id,
        'product_id': offerData['productId'],
        'seller_id': offerData['sellerId'],
        'offer_amount': offerData['offerAmount'],
        'status': 'pending',
      }).select();
      
      return http.Response(jsonEncode({'offer': res.first}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  
  static Future<http.Response> acceptOffer(String offerId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      await _supabase.from('offers').update({'status': 'accepted'}).eq('id', offerId);
      return http.Response('{}', 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> generatePitchScript(Map<String, dynamic> body) async {
    try {
      final productName = body['productName'] ?? 'Product';
      final sellingPoint = body['sellingPoint'] ?? '';
      final tone = body['tone'] ?? 'Exciting';
      final language = body['language'] ?? 'English';
      
      String hook, problem, solution, offer, cta;
      
      if (tone == 'Professional') {
        hook = 'Attention! Discover $productName — the product everyone is talking about.';
        problem = 'Finding quality products that deliver on their promises can be challenging.';
        solution = '$productName stands out because $sellingPoint';
        offer = 'Available now at an exclusive price. Limited stock remaining.';
        cta = 'Order now through Pitch & Sell. Tap the cart icon to secure yours today.';
      } else {
        hook = 'STOP SCROLLING! 🔥 You NEED to see this!';
        problem = 'Tired of wasting money on products that don\'t deliver?';
        solution = 'Say hello to $productName! $sellingPoint';
        offer = 'Get it NOW before it sells out! 🚀';
        cta = 'Tap BUY NOW! Link in bio. Don\'t miss out! 💰';
      }
      
      final script = '''
🎬 PITCH SCRIPT: $productName

🔥 HOOK (0-3 sec):
"$hook"

💡 PROBLEM (3-8 sec):
"$problem"

✅ SOLUTION (8-15 sec):
"$solution"

💰 OFFER (15-20 sec):
"$offer"

📲 CALL TO ACTION (20-25 sec):
"$cta"

#PitchAndSell #ShopNow
''';
      
      final tips = [
        'Keep your video under 30 seconds for maximum engagement',
        'Show the product in action within the first 3 seconds',
        'Use natural lighting for a professional look',
        'Add trending music to boost discoverability',
        'End with a clear call-to-action',
      ];
      
      return http.Response(jsonEncode({'script': script, 'tips': tips}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': 'Could not generate script. Try again.'}), 500);
    }
  }

  static Future<http.Response> promoteProduct(String productId, String plan) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final res = await _supabase.from('promotions').insert({
        'seller_id': user.id,
        'product_id': productId,
        'plan_name': plan,
        'status': 'active',
      }).select();
      
      return http.Response(jsonEncode({'promotion': res.first}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> getPromotions() async {
    try {
      final res = await _supabase.from('promotions').select('*, products(*)').eq('status', 'active');
      return http.Response(jsonEncode({'promotions': res}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  
  // Get follower/following counts for a user
  static Future<http.Response> getProfileStats(String userId) async {
    try {
      final products = await _supabase.from('products').select('id').eq('seller_id', userId);
      final orders = await _supabase.from('orders').select('id').eq('seller_id', userId);
      final reviews = await _supabase.from('reviews').select('rating').inFilter('product_id', products.map((p) => p['id'] as String).toList());
      
      double avgRating = 0;
      if (reviews.isNotEmpty) {
        avgRating = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num)) / reviews.length;
      }
      
      return http.Response(jsonEncode({
        'totalProducts': products.length,
        'totalOrders': orders.length,
        'avgRating': avgRating,
        'reviewCount': reviews.length,
      }), 200);
    } catch (e) {
      return http.Response(jsonEncode({'totalProducts': 0, 'totalOrders': 0, 'avgRating': 0, 'reviewCount': 0}), 200);
    }
  }

  // Get real notifications from order activity
  static Future<http.Response> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      List<Map<String, dynamic>> notifications = [];
      
      // Orders as buyer
      final buyerOrders = await _supabase.from('orders').select('id, status, created_at, products(name)').eq('buyer_id', user.id).order('created_at', ascending: false).limit(10);
      for (final o in buyerOrders) {
        final productName = o['products']?['name'] ?? 'Product';
        String message;
        String icon;
        switch (o['status']) {
          case 'pending': message = 'Your order for $productName is pending'; icon = '🕐'; break;
          case 'processing': message = 'Your order for $productName is being processed'; icon = '📦'; break;
          case 'shipped': message = 'Your order for $productName has been shipped!'; icon = '🚚'; break;
          case 'delivered': message = 'Your order for $productName has been delivered!'; icon = '✅'; break;
          case 'cancelled': message = 'Your order for $productName was cancelled'; icon = '❌'; break;
          default: message = 'Order update for $productName'; icon = '📋';
        }
        notifications.add({'message': message, 'icon': icon, 'date': o['created_at'], 'type': 'order'});
      }
      
      // Orders as seller
      final sellerOrders = await _supabase.from('orders').select('id, status, created_at, products(name)').eq('seller_id', user.id).order('created_at', ascending: false).limit(10);
      for (final o in sellerOrders) {
        final productName = o['products']?['name'] ?? 'Product';
        if (o['status'] == 'pending') {
          notifications.add({'message': 'New order received for $productName! 🎉', 'icon': '🛒', 'date': o['created_at'], 'type': 'order'});
        }
      }
      
      // Sort by date descending
      notifications.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      
      return http.Response(jsonEncode({'notifications': notifications}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'notifications': []}), 200);
    }
  }

  // Get explore data - real categories and trending sellers
  static Future<http.Response> getExploreData() async {
    try {
      // Get categories with product counts
      final products = await _supabase.from('products').select('category');
      final categoryCount = <String, int>{};
      for (final p in products) {
        final cat = p['category'] as String? ?? 'Other';
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }
      
      // Get trending sellers (most products)
      final sellers = await _supabase.from('profiles').select('id, name, business_name, avatar').eq('is_business', true).limit(10);
      
      return http.Response(jsonEncode({
        'categories': categoryCount,
        'trendingSellers': sellers,
      }), 200);
    } catch (e) {
      return http.Response(jsonEncode({'categories': {}, 'trendingSellers': []}), 200);
    }
  }

  // Get real promotion stats for dashboard
  static Future<http.Response> getPromotionStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final promos = await _supabase.from('promotions').select('*, products(name)').eq('seller_id', user.id).order('created_at', ascending: false);
      return http.Response(jsonEncode({'promotions': promos}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'promotions': []}), 200);
    }
  }

  // Dummy methods to satisfy imports if needed
  static Future<void> setToken(String token) async {}
  static Future<void> clearToken() async {}
}
