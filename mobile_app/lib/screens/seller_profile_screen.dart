import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import '../features/feed/widgets/video_player_item.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String businessName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.businessName,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  int _completedOrders = 0;
  int _followersCount = 0;
  bool _isFollowing = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await ApiService.isFollowing(widget.sellerId);
      final count = await ApiService.getFollowerCount(widget.sellerId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _followersCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to follow sellers.')));
      return;
    }
    if (user.id == widget.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot follow your own shop.')));
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      final res = await ApiService.toggleFollow(widget.sellerId);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final following = data['isFollowing'] == true;
        if (mounted) {
          setState(() {
            _isFollowing = following;
            _followersCount += following ? 1 : -1;
            if (_followersCount < 0) _followersCount = 0;
            _isActionLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(following ? 'Following ${widget.businessName}' : 'Unfollowed ${widget.businessName}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) setState(() => _isActionLoading = false);
      }
    } catch (e) {
      debugPrint('Follow error: $e');
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _confirmDeleteProduct(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1e1e1e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Pitch Video?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$productName"? This will permanently remove it from your store and the feed.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Deleting pitch video...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );

      try {
        final res = await ApiService.deleteProduct(productId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (res.statusCode == 200) {
          setState(() {
            _products.removeWhere((p) => p['id'] == productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Pitch video deleted successfully! 🗑️'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _fetchSellerProducts();
        } else {
          String errMsg = 'Failed to delete video';
          try {
            final data = jsonDecode(res.body);
            if (data['error'] != null) errMsg = data['error'];
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errMsg)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('Delete error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openPitchVideoModal(dynamic rawProduct) {
    final product = {
      'id': rawProduct['id'],
      'name': rawProduct['name'] ?? '',
      'description': rawProduct['description'] ?? '',
      'price': rawProduct['price'] ?? 0,
      'seller_id': rawProduct['seller_id'] ?? widget.sellerId,
      'sizes': rawProduct['sizes'] ?? [],
      'colors': rawProduct['colors'] ?? [],
      'business': {'name': widget.businessName},
      'video': {
        'url': rawProduct['video_url'],
        'likesCount': 0,
        'allowDownload': rawProduct['allow_download'] ?? false,
      }
    };

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == widget.sellerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(ctx),
          ),
          title: Text(
            rawProduct['name'] ?? 'Pitch Video',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                tooltip: 'Delete Video',
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _confirmDeleteProduct(rawProduct['id'], rawProduct['name'] ?? 'Product');
                },
              ),
          ],
        ),
        body: SafeArea(
          child: VideoPlayerItem(
            productData: product,
            isVisible: true,
            isFocused: true,
            onChatPressed: (chatId, title) {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(chatId: chatId, chatTitle: title),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _fetchSellerProducts() async {
    try {
      final res = await Supabase.instance.client
          .from('products')
          .select('*, profiles:seller_id(*)')
          .eq('seller_id', widget.sellerId)
          .order('created_at', ascending: false);
          
      // Fetch completed orders count for badges
      int count = 0;
      try {
        final ordersRes = await Supabase.instance.client
            .from('orders')
            .select('id')
            .eq('seller_id', widget.sellerId)
            .eq('status', 'completed');
        count = ordersRes.length;
      } catch (e) {
        debugPrint('Error counting orders: $e');
      }
      
      if (mounted) {
        setState(() {
          _products = res;
          _completedOrders = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to chat.')));
      return;
    }

    try {
      // Check if chat exists
      final existingChat = await Supabase.instance.client
          .from('chats')
          .select('id')
          .or('and(user1_id.eq.${user.id},user2_id.eq.${widget.sellerId}),and(user1_id.eq.${widget.sellerId},user2_id.eq.${user.id})')
          .maybeSingle();

      String chatId;
      if (existingChat != null) {
        chatId = existingChat['id'];
      } else {
        final newChat = await Supabase.instance.client.from('chats').insert({
          'user1_id': user.id,
          'user2_id': widget.sellerId,
        }).select('id').single();
        chatId = newChat['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              chatTitle: widget.businessName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start chat.')));
      }
    }
  }

  Widget _buildTierBadge() {
    if (_completedOrders >= 500) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.blue, size: 18),
          SizedBox(width: 4),
          Text('Top Rated Seller', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      );
    } else if (_completedOrders >= 400) {
      return _badgeUI('Diamond Seller 💎', Colors.cyanAccent);
    } else if (_completedOrders >= 200) {
      return _badgeUI('Platinum Seller', Colors.tealAccent);
    } else if (_completedOrders >= 50) {
      return _badgeUI('Gold Seller 🏆', Colors.amber);
    } else if (_completedOrders >= 10) {
      return _badgeUI('Silver Seller 🥈', Colors.grey[400]!);
    } else if (_completedOrders >= 5) {
      return _badgeUI('Bronze Seller 🥉', Colors.brown[300]!);
    }
    return const Text('New Seller 🌱', style: TextStyle(color: Colors.grey, fontSize: 13));
  }

  Widget _badgeUI(String text, Color color) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
       decoration: BoxDecoration(
         color: color.withOpacity(0.15),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: color.withOpacity(0.5)),
       ),
       child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1e1e1e) : Colors.white,
        elevation: 0,
        title: Text(widget.businessName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xff1e1e1e),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xffFF5722).withOpacity(0.15),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xffFF5722), size: 38),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_followersCount Followers',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white38)),
                    const SizedBox(width: 8),
                    _buildTierBadge(),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Follow / Following Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isFollowing ? Colors.white38 : const Color(0xffFF5722),
                              width: 1.5,
                            ),
                            backgroundColor: _isFollowing ? Colors.white10 : const Color(0xffFF5722).withOpacity(0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isActionLoading ? null : _toggleFollow,
                          icon: _isActionLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffFF5722)),
                                )
                              : Icon(
                                  _isFollowing ? Icons.check : Icons.person_add_alt_1_rounded,
                                  color: _isFollowing ? Colors.white70 : const Color(0xffFF5722),
                                  size: 18,
                                ),
                          label: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: _isFollowing ? Colors.white70 : const Color(0xffFF5722),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Chat with Seller Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF5722),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _startChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                          label: const Text(
                            'Chat',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Products', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                : _products.isEmpty
                    ? const Center(child: Text('No products available.', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final user = Supabase.instance.client.auth.currentUser;
                          final isOwner = user != null && user.id == widget.sellerId;

                          return GestureDetector(
                            onTap: () => _openPitchVideoModal(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff1e1e1e),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Color(0xff2d2d2d), Color(0xff181818)],
                                            ),
                                            image: (product['thumbnailUrl'] != null && (product['thumbnailUrl'] as String).isNotEmpty)
                                                ? DecorationImage(
                                                    image: NetworkImage(product['thumbnailUrl']),
                                                    fit: BoxFit.cover,
                                                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                                                  )
                                                : null,
                                          ),
                                          child: const Center(
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.black45,
                                              child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 30),
                                            ),
                                          ),
                                        if (isOwner)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => _confirmDeleteProduct(product['id'], product['name'] ?? 'Product'),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.75),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
                                                  ),
                                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PKR ${product['price'] ?? 0}',
                                          style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
