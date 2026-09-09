import 'package:flutter/foundation.dart';
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

  // Notification Creation Helper
  static Future<void> createNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || recipientUserId.isEmpty || recipientUserId == user.id) return;
      await _supabase.from('notifications').insert({
        'user_id': recipientUserId,
        'title': title,
        'body': body,
        'type': type,
        'metadata': metadata ?? {},
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error inserting notification: $e');
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

      // Batch fetch saved and liked products for the authenticated user
      final user = _supabase.auth.currentUser;
      final Set<String> userSavedProductIds = {};
      final Set<String> userLikedProductIds = {};

      if (user != null) {
        try {
          final savedRes = await _supabase.from('saved_videos').select('product_id').eq('user_id', user.id);
          for (final s in savedRes) {
            final pid = s['product_id'] as String?;
            if (pid != null) userSavedProductIds.add(pid);
          }
        } catch (_) {}

        try {
          final likedRes = await _supabase.from('likes').select('product_id').eq('user_id', user.id);
          for (final l in likedRes) {
            final pid = l['product_id'] as String?;
            if (pid != null) userLikedProductIds.add(pid);
          }
        } catch (_) {}
      }

      final productsList = data.map((item) {
        // Calculate average rating
        final reviews = item['reviews'] as List<dynamic>? ?? [];
        double avgRating = 0;
        if (reviews.isNotEmpty) {
          final total = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num));
          avgRating = total / reviews.length;
        }

        final isSaved = userSavedProductIds.contains(item['id']);
        final isLiked = userLikedProductIds.contains(item['id']);

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
          'isSaved': isSaved,
          'isLiked': isLiked,
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

  // Delete product (seller only)
  static Future<http.Response> deleteProduct(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);

      // 1. Fetch the product to get video_url and verify seller_id
      final product = await _supabase
          .from('products')
          .select('id, seller_id, video_url')
          .eq('id', productId)
          .maybeSingle();

      if (product == null) {
        return http.Response(jsonEncode({'error': 'Product not found'}), 404);
      }

      if (product['seller_id'] != user.id) {
        return http.Response(jsonEncode({'error': 'You can only delete your own pitch videos.'}), 403);
      }

      final String? videoUrl = product['video_url'] as String?;

      // 2. Pre-clean dependent rows in child tables so deletion never fails due to FK constraints
      try { await _supabase.from('likes').delete().eq('product_id', productId); } catch (_) {}
      try { await _supabase.from('saved_videos').delete().eq('product_id', productId); } catch (_) {}
      try { await _supabase.from('comments').delete().eq('product_id', productId); } catch (_) {}
      try { await _supabase.from('reviews').delete().eq('product_id', productId); } catch (_) {}
      try { await _supabase.from('promotions').delete().eq('product_id', productId); } catch (_) {}
      try { await _supabase.from('offers').delete().eq('product_id', productId); } catch (_) {}

      // Handle orders: if orders exist, unlink or delete them so FK constraint won't block
      try {
        await _supabase.from('orders').delete().eq('product_id', productId);
      } catch (_) {
        try {
          await _supabase.from('orders').update({'product_id': null}).eq('product_id', productId);
        } catch (_) {}
      }

      // 3. Delete the product row
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('seller_id', user.id);

      // 4. Remove video from Supabase Storage bucket if it was uploaded to 'videos'
      if (videoUrl != null && videoUrl.isNotEmpty) {
        try {
          final uri = Uri.tryParse(videoUrl);
          if (uri != null && uri.pathSegments.isNotEmpty) {
            final fileName = uri.pathSegments.last;
            if (fileName.isNotEmpty && fileName.contains('.')) {
              await _supabase.storage.from('videos').remove([fileName]);
              debugPrint('Removed video file from storage: $fileName');
            }
          }
        } catch (e) {
          debugPrint('Storage video removal warning: $e');
        }
      }

      return http.Response(jsonEncode({'success': true, 'message': 'Pitch video deleted successfully'}), 200);
    } catch (e) {
      debugPrint('Delete product error: $e');
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Get seller's own uploaded products / pitches
  static Future<http.Response> getMyProducts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response(jsonEncode({'products': []}), 200);

      final data = await _supabase
          .from('products')
          .select('*, profiles:seller_id(*), reviews(rating)')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      // Batch fetch like counts
      final allLikes = await _supabase.from('likes').select('product_id');
      final likesMap = <String, int>{};
      for (final l in allLikes) {
        final pid = l['product_id'] as String;
        likesMap[pid] = (likesMap[pid] ?? 0) + 1;
      }

      final productsList = data.map((item) {
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
          'category': item['category'] ?? 'General',
          'stock': item['stock'] ?? 0,
          'sizes': item['sizes'] ?? [],
          'colors': item['colors'] ?? [],
          'avgRating': avgRating,
          'reviewCount': reviews.length,
          'business': {'name': item['profiles']?['business_name'] ?? item['profiles']?['name'] ?? 'My Store'},
          'video': {
            'url': item['video_url'],
            'likesCount': likesMap[item['id']] ?? 0,
            'allowDownload': item['allow_download'] ?? false,
          }
        };
      }).toList();

      return http.Response(jsonEncode({'products': productsList}), 200);
    } catch (e) {
      debugPrint('getMyProducts error: $e');
      return http.Response(jsonEncode({'error': e.toString(), 'products': []}), 500);
    }
  }

  // Likes
  static Future<http.Response> toggleLike(String videoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      // Ensure profile row exists to prevent FK violation
      try {
        final profile = await _supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();
        if (profile == null) {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? '',
            'name': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Customer',
            'role': 'customer',
          });
        }
      } catch (_) {}

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

        // Notify seller about the like
        try {
          final prod = await _supabase.from('products').select('name, seller_id').eq('id', videoId).maybeSingle();
          if (prod != null && prod['seller_id'] != null && prod['seller_id'] != user.id) {
            final myProf = await _supabase.from('profiles').select('name, business_name').eq('id', user.id).maybeSingle();
            final userName = myProf?['name'] ?? myProf?['business_name'] ?? 'A customer';
            final prodName = prod['name'] ?? 'Product';
            await createNotification(
              recipientUserId: prod['seller_id'],
              title: 'New Like ❤️',
              body: '$userName liked your pitch for "$prodName"!',
              type: 'like',
              metadata: {'product_id': videoId, 'product_name': prodName},
            );
          }
        } catch (notifErr) {
          debugPrint('Error sending like notification: $notifErr');
        }

        return http.Response(jsonEncode({'liked': true}), 200);
      }
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  static Future<http.Response> likeVideo(String videoId) => toggleLike(videoId);

  // Customer Mode: Get Liked Videos
  static Future<http.Response> getLikedVideos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response(jsonEncode({'liked': []}), 401);
      
      final res = await _supabase
          .from('likes')
          .select('product_id, created_at, products(*, profiles:seller_id(*))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> products = [];
      for (final r in (res as List)) {
        if (r['products'] != null && r['products'] is Map) {
          final prod = Map<String, dynamic>.from(r['products'] as Map);
          prod['liked_at'] = r['created_at'];
          if (prod['video'] == null) {
            prod['video'] = {
              'url': prod['video_url'],
              'allowDownload': prod['allow_download'] ?? false,
              'likesCount': 0,
            };
          }
          if (prod['business'] == null) {
            prod['business'] = {
              'name': prod['profiles']?['business_name'] ?? prod['profiles']?['name'] ?? 'Seller',
            };
          }
          prod['isLiked'] = true;
          products.add(prod);
        }
      }
      return http.Response(jsonEncode({'liked': products}), 200);
    } catch (e) {
      debugPrint('Error getting liked videos: $e');
      return http.Response(jsonEncode({'liked': [], 'error': e.toString()}), 500);
    }
  }

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
      if (user == null) {
        return http.Response(jsonEncode({'error': 'Unauthorized. Please sign in to save videos.'}), 401);
      }
      if (videoId.isEmpty) {
        return http.Response(jsonEncode({'error': 'Invalid product ID'}), 400);
      }
      
      // Ensure user profile exists in public.profiles to satisfy FK
      try {
        final profile = await _supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();
        if (profile == null) {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? '',
            'name': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Customer',
            'role': 'customer',
          });
        }
      } catch (profileErr) {
        debugPrint('Profile check/upsert: $profileErr');
      }

      final existing = await _supabase
          .from('saved_videos')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', videoId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('saved_videos')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', videoId);
        return http.Response(jsonEncode({'saved': false, 'message': 'Removed from saved videos'}), 200);
      } else {
        await _supabase.from('saved_videos').insert({
          'user_id': user.id,
          'product_id': videoId,
        });

        // Notify seller about saved pitch video
        try {
          final prod = await _supabase.from('products').select('name, seller_id').eq('id', videoId).maybeSingle();
          if (prod != null && prod['seller_id'] != null && prod['seller_id'] != user.id) {
            final myProf = await _supabase.from('profiles').select('name, business_name').eq('id', user.id).maybeSingle();
            final userName = myProf?['name'] ?? myProf?['business_name'] ?? 'A customer';
            final prodName = prod['name'] ?? 'Product';
            await createNotification(
              recipientUserId: prod['seller_id'],
              title: 'Video Saved 📌',
              body: '$userName saved your pitch for "$prodName" for later!',
              type: 'save',
              metadata: {'product_id': videoId, 'product_name': prodName},
            );
          }
        } catch (notifErr) {
          debugPrint('Error sending save notification: $notifErr');
        }

        return http.Response(jsonEncode({'saved': true, 'message': 'Video saved for later!'}), 200);
      }
    } catch (e) {
      debugPrint('Error in toggleSaveVideo: $e');
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<bool> isVideoSaved(String videoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || videoId.isEmpty) return false;
      final existing = await _supabase
          .from('saved_videos')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', videoId)
          .maybeSingle();
      return existing != null;
    } catch (e) {
      debugPrint('Error checking isVideoSaved: $e');
      return false;
    }
  }

  static Future<http.Response> getSavedVideos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return http.Response(jsonEncode({'saved': [], 'error': 'Unauthorized'}), 401);
      }
      
      final res = await _supabase
          .from('saved_videos')
          .select('product_id, created_at, products(*, profiles:seller_id(*))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> products = [];
      for (final r in (res as List)) {
        if (r['products'] != null && r['products'] is Map) {
          final prod = Map<String, dynamic>.from(r['products'] as Map);
          prod['saved_at'] = r['created_at'];
          if (prod['video'] == null) {
            prod['video'] = {
              'url': prod['video_url'],
              'allowDownload': prod['allow_download'] ?? false,
              'likesCount': 0,
            };
          }
          if (prod['business'] == null) {
            prod['business'] = {
              'name': prod['profiles']?['business_name'] ?? prod['profiles']?['name'] ?? 'Seller',
            };
          }
          prod['isSaved'] = true;
          products.add(prod);
        }
      }
      return http.Response(jsonEncode({'saved': products}), 200);
    } catch (e) {
      debugPrint('Error getting saved videos: $e');
      return http.Response(jsonEncode({'saved': [], 'error': e.toString()}), 500);
    }
  }

  // Orders API
  static Future<http.Response> createOrder(
    String productId, 
    int quantity, 
    String paymentMethod, {
    String? size, 
    String? color,
    String? buyerName,
    String? buyerPhone,
    String? buyerAltPhone,
    String? deliveryAddress,
    String? city,
    String? deliveryInstructions,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);

      // Ensure buyer has a row in public.profiles table to prevent foreign key violations (orders_buyer_id_fkey)
      try {
        final existingProfile = await _supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();
        if (existingProfile == null) {
          final meta = user.userMetadata ?? {};
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? '',
            'name': (buyerName != null && buyerName.isNotEmpty)
                ? buyerName
                : (meta['full_name'] ?? meta['name'] ?? user.email?.split('@').first ?? 'Customer'),
            'phone': buyerPhone ?? user.phone ?? meta['phone'],
            'role': 'customer',
            'is_business': false,
            'address': deliveryAddress,
          });
        }
      } catch (profileErr) {
        debugPrint('Warning ensuring buyer profile: $profileErr');
      }
      
      final product = await _supabase.from('products').select('seller_id, price').eq('id', productId).single();

      // Also ensure seller exists in public.profiles if orphaned
      try {
        final sellerId = product['seller_id'] as String;
        final existingSeller = await _supabase.from('profiles').select('id').eq('id', sellerId).maybeSingle();
        if (existingSeller == null) {
          await _supabase.from('profiles').upsert({
            'id': sellerId,
            'name': 'Seller',
            'role': 'seller',
            'is_business': true,
          });
        }
      } catch (_) {}
      
      final res = await _supabase.from('orders').insert({
        'buyer_id': user.id,
        'seller_id': product['seller_id'],
        'product_id': productId,
        'quantity': quantity,
        'total_price': (product['price'] as num) * quantity,
        'payment_method': paymentMethod,
        'payment_status': paymentMethod.toUpperCase().contains('COD') ? 'pending' : 'paid',
        'status': 'pending',
        'selected_size': size,
        'selected_color': color,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'buyer_alt_phone': buyerAltPhone,
        'delivery_address': deliveryAddress,
        'city': city,
        'delivery_instructions': deliveryInstructions,
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
        'paymentStatus': o['payment_status'],
        'unitPrice': o['products']?['price'],
        'selectedSize': o['selected_size'],
        'selectedColor': o['selected_color'],
        'buyerName': o['buyer_name'],
        'buyerPhone': o['buyer_phone'],
        'buyerAltPhone': o['buyer_alt_phone'],
        'deliveryAddress': o['delivery_address'],
        'city': o['city'],
        'deliveryInstructions': o['delivery_instructions'],
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
      
      if (language.toString().toLowerCase().contains('urdu')) {
        hook = 'Rukiye! 🔥 Yeh video zaroor dekhein!';
        problem = 'Kya aap behtareen quality ki cheez dhoond rahay hain?';
        solution = '$productName ab dastiyab hai! $sellingPoint';
        offer = 'Abhi order karein sirf limited stock mein!';
        cta = 'Neechay diye gaye Buy button par click karein aur apna order book karein! 💰';
      } else if (tone == 'Professional') {
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

  static Future<http.Response> promoteProduct(
    String productId,
    String plan, {
    double amount = 100.0,
    int durationDays = 3,
    String paymentMethod = 'EasyPaisa',
    String? transactionId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      final res = await _supabase.from('promotions').insert({
        'seller_id': user.id,
        'product_id': productId,
        'plan_name': plan,
        'amount': amount,
        'duration_days': durationDays,
        'payment_method': paymentMethod,
        'transaction_id': transactionId ?? '',
        'status': 'pending', // Pending Admin Verification
        'created_at': DateTime.now().toIso8601String(),
      }).select();
      
      return http.Response(jsonEncode({
        'promotion': res.first,
        'message': 'Promotion plan submitted! Admin will verify payment and activate your billboard shortly.',
      }), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Get active billboard promotions (only admin-approved and unexpired)
  static Future<http.Response> getPromotions() async {
    try {
      final res = await _supabase
          .from('promotions')
          .select('*, products(*)')
          .eq('status', 'active');
      
      final now = DateTime.now();
      final activeList = (res as List<dynamic>).where((p) {
        final expiresAt = p['expires_at'];
        if (expiresAt == null) return true;
        final expDate = DateTime.tryParse(expiresAt.toString());
        return expDate == null || expDate.isAfter(now);
      }).toList();

      return http.Response(jsonEncode({'promotions': activeList}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString(), 'promotions': []}), 500);
    }
  }

  // Admin: Get all promotions for verification
  static Future<http.Response> getAllPromotionsForAdmin({String? statusFilter}) async {
    try {
      dynamic query = _supabase
          .from('promotions')
          .select('*, products(name, price, video_url), profiles(name, business_name, email, phone)');
      
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
        query = query.eq('status', statusFilter.toLowerCase());
      }

      final res = await query.order('created_at', ascending: false);
      return http.Response(jsonEncode({'promotions': res}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString(), 'promotions': []}), 500);
    }
  }

  // Admin: Verify/Approve or Reject promotion plan
  static Future<http.Response> verifyPromotionPlan(
    String promotionId,
    bool approve, {
    String? adminNotes,
    int durationDays = 3,
  }) async {
    try {
      final now = DateTime.now();
      final Map<String, dynamic> updates = {
        'status': approve ? 'active' : 'rejected',
        'admin_notes': adminNotes,
        'updated_at': now.toIso8601String(),
      };

      if (approve) {
        updates['started_at'] = now.toIso8601String();
        updates['expires_at'] = now.add(Duration(days: durationDays)).toIso8601String();
      }

      await _supabase.from('promotions').update(updates).eq('id', promotionId);
      return http.Response(jsonEncode({
        'success': true,
        'status': approve ? 'active' : 'rejected',
        'message': approve ? 'Promotion activated on Billboard!' : 'Promotion request rejected.',
      }), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  
  // Get follower/following counts and profile stats for a user
  static Future<http.Response> getProfileStats(String userId) async {
    try {
      final products = await _supabase.from('products').select('id').eq('seller_id', userId);
      final orders = await _supabase.from('orders').select('id').eq('seller_id', userId);
      final reviews = await _supabase.from('reviews').select('rating').inFilter('product_id', products.map((p) => p['id'] as String).toList());
      
      double avgRating = 0;
      if (reviews.isNotEmpty) {
        avgRating = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num)) / reviews.length;
      }

      int followersCount = 0;
      int followingCount = 0;
      try {
        final followersRes = await _supabase.from('follows').select('id').eq('seller_id', userId);
        followersCount = followersRes.length;
        final followingRes = await _supabase.from('follows').select('id').eq('follower_id', userId);
        followingCount = followingRes.length;
      } catch (_) {}
      
      return http.Response(jsonEncode({
        'totalProducts': products.length,
        'totalOrders': orders.length,
        'avgRating': avgRating,
        'reviewCount': reviews.length,
        'followersCount': followersCount,
        'followingCount': followingCount,
      }), 200);
    } catch (e) {
      return http.Response(jsonEncode({'totalProducts': 0, 'totalOrders': 0, 'avgRating': 0, 'reviewCount': 0, 'followersCount': 0, 'followingCount': 0}), 200);
    }
  }

  // Follow / Unfollow System
  static Future<http.Response> toggleFollow(String sellerId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      if (user.id == sellerId) {
        return http.Response(jsonEncode({'error': 'You cannot follow yourself'}), 400);
      }

      // Ensure profile row exists to prevent FK violation
      try {
        final profile = await _supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();
        if (profile == null) {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? '',
            'name': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Customer',
            'role': 'customer',
          });
        }
      } catch (_) {}

      final existing = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', user.id)
            .eq('seller_id', sellerId);
        return http.Response(jsonEncode({'isFollowing': false, 'message': 'Unfollowed'}), 200);
      } else {
        await _supabase.from('follows').insert({
          'follower_id': user.id,
          'seller_id': sellerId,
        });

        // Notify seller about new follower
        try {
          final myProf = await _supabase.from('profiles').select('name, business_name').eq('id', user.id).maybeSingle();
          final userName = myProf?['name'] ?? myProf?['business_name'] ?? 'A customer';
          await createNotification(
            recipientUserId: sellerId,
            title: 'New Follower 🎉',
            body: '$userName started following your store!',
            type: 'follow',
            metadata: {'follower_id': user.id, 'follower_name': userName},
          );
        } catch (notifErr) {
          debugPrint('Error sending follow notification: $notifErr');
        }

        return http.Response(jsonEncode({'isFollowing': true, 'message': 'Following'}), 200);
      }
    } catch (e) {
      debugPrint('Error in toggleFollow: $e');
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<bool> isFollowing(String sellerId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || sellerId.isEmpty) return false;

      final existing = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('seller_id', sellerId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getFollowerCount(String sellerId) async {
    try {
      final res = await _supabase
          .from('follows')
          .select('id')
          .eq('seller_id', sellerId);
      return res.length;
    } catch (e) {
      return 0;
    }
  }

  // Customer Mode: Get list of followed sellers
  static Future<http.Response> getFollowingSellers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response(jsonEncode({'sellers': []}), 401);

      final res = await _supabase
          .from('follows')
          .select('seller_id, created_at, profiles:seller_id(*)')
          .eq('follower_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> sellers = [];
      for (final r in (res as List)) {
        if (r['profiles'] != null && r['profiles'] is Map) {
          final seller = Map<String, dynamic>.from(r['profiles'] as Map);
          seller['followed_at'] = r['created_at'];
          sellers.add(seller);
        }
      }
      return http.Response(jsonEncode({'sellers': sellers}), 200);
    } catch (e) {
      debugPrint('Error getting following sellers: $e');
      return http.Response(jsonEncode({'sellers': [], 'error': e.toString()}), 500);
    }
  }

  // Get real notifications from database & orders
  static Future<http.Response> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);
      
      List<Map<String, dynamic>> notifications = [];
      
      // 1. Fetch from notifications table in Supabase
      try {
        final notifRows = await _supabase
            .from('notifications')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(30);

        for (final n in notifRows) {
          String icon;
          switch (n['type']) {
            case 'follow': icon = '👤'; break;
            case 'like': icon = '❤️'; break;
            case 'save': icon = '📌'; break;
            case 'order': icon = '📦'; break;
            case 'offer': icon = '🏷️'; break;
            case 'promotion': icon = '📢'; break;
            default: icon = '🔔';
          }
          notifications.add({
            'id': n['id'],
            'title': n['title'] ?? 'Notification',
            'message': n['body'] ?? '',
            'body': n['body'] ?? '',
            'icon': icon,
            'type': n['type'] ?? 'general',
            'metadata': n['metadata'] ?? {},
            'is_read': n['is_read'] ?? false,
            'created_at': n['created_at'],
            'date': n['created_at'],
          });
        }
      } catch (dbErr) {
        debugPrint('Error querying notifications table: $dbErr');
      }

      // 2. Fetch order updates as buyer
      try {
        final buyerOrders = await _supabase
            .from('orders')
            .select('id, status, created_at, products(name)')
            .eq('buyer_id', user.id)
            .order('created_at', ascending: false)
            .limit(10);
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
          notifications.add({
            'title': 'Order Update',
            'message': message,
            'body': message,
            'icon': icon,
            'date': o['created_at'],
            'created_at': o['created_at'],
            'type': 'order'
          });
        }
      } catch (_) {}
      
      // 3. Fetch order updates as seller
      try {
        final sellerOrders = await _supabase
            .from('orders')
            .select('id, status, created_at, products(name)')
            .eq('seller_id', user.id)
            .order('created_at', ascending: false)
            .limit(10);
        for (final o in sellerOrders) {
          final productName = o['products']?['name'] ?? 'Product';
          if (o['status'] == 'pending') {
            notifications.add({
              'title': 'New Order Received! 🎉',
              'message': 'New order received for $productName!',
              'body': 'New order received for $productName!',
              'icon': '🛒',
              'date': o['created_at'],
              'created_at': o['created_at'],
              'type': 'order'
            });
          }
        }
      } catch (_) {}

      // Deduplicate and sort by date descending
      notifications.sort((a, b) {
        final dateA = (a['date'] ?? a['created_at'] ?? '') as String;
        final dateB = (b['date'] ?? b['created_at'] ?? '') as String;
        return dateB.compareTo(dateA);
      });
      
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

  // Update Preferred Categories
  static Future<http.Response> updatePreferredCategories(List<String> categories) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return http.Response('Unauthorized', 401);

      await _supabase.from('profiles').update({
        'preferred_categories': categories,
      }).eq('id', user.id);

      return http.Response(jsonEncode({'preferred_categories': categories}), 200);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Get Preferred Categories
  static Future<List<String>> getPreferredCategories() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final data = await _supabase.from('profiles').select('preferred_categories').eq('id', user.id).maybeSingle();
      if (data != null && data['preferred_categories'] != null) {
        return List<String>.from(data['preferred_categories']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Dummy methods to satisfy imports if needed
  static Future<void> setToken(String token) async {}
  static Future<void> clearToken() async {}
}
