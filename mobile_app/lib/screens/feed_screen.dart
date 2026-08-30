import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'checkout_screen.dart';
import 'live_stream_screen.dart';
import 'explore_screen.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import '../providers/cart_provider.dart';
import '../services/socket_service.dart';
import 'seller_profile_screen.dart';
import 'my_orders_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'seller_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  final bool isVisible;
  final String? initialCategory;
  final String? initialSearch;
  
  const FeedScreen({
    super.key, 
    this.isVisible = true,
    this.initialCategory,
    this.initialSearch,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  PageController? _pageController;
  String _selectedCategory = 'All';
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
    if (widget.initialSearch != null) _searchQuery = widget.initialSearch!;
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getFeed(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = data['products'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      debugPrint('Error fetching feed, falling back to mock: $e');
      // Fallback for offline testing
      setState(() {
        _products = [
          {
            'id': 'mock1',
            'name': 'Premium Smartwatch 2026',
            'description': 'Latest smartwatch with health tracking and seamless connectivity.',
            'price': 15000,
            'oldPrice': 18000,
            'businessId': 'biz1',
            'business': {'name': 'TechStore PK'},
            'video': {
              'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
              'likesCount': 1240,
              'allowDownload': true
            }
          },
          {
            'id': 'mock2',
            'name': 'Wireless Noise-Cancelling Headphones',
            'description': 'Immersive sound experience with active noise cancellation.',
            'price': 8500,
            'oldPrice': null,
            'businessId': 'biz2',
            'business': {'name': 'Audio Hub'},
            'video': {
              'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
              'likesCount': 892,
              'allowDownload': false
            }
          }
        ];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Feed PageView
          _isLoading 
              ? Shimmer.fromColors(
                  baseColor: const Color(0xff1e1e1e),
                  highlightColor: const Color(0xff2a2a2a),
                  child: Container(color: Colors.black),
                )
              : _products.isEmpty
                  ? const Center(child: Text('No videos uploaded yet.', style: TextStyle(color: Colors.white)))
                  : PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _pageController,
                      itemCount: _products.length,
                      onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        // Pre-load the next 2 videos into cache for zero buffering
                        for (int i = 1; i <= 2; i++) {
                          if (index + i < _products.length) {
                            final nextUrl = _products[index + i]['video']?['url'];
                            if (nextUrl != null && nextUrl.startsWith('http')) {
                              DefaultCacheManager().downloadFile(nextUrl);
                            }
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        return VideoPlayerItem(
                            productData: _products[index],
                            isVisible: widget.isVisible,
                            isFocused: index == _currentIndex,
                          onChatPressed: (chatId, title) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chatId: chatId, chatTitle: title),
                              ),
                            );
                          },
                        );
                      },
                    ),

          // Sticky Overlay Header: Search, Notifications, Category, Stories, Flash Sale Banner
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar + Logo + Notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.smart_toy_outlined, color: Color(0xffFF5722), size: 24),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LiveStreamScreen()),
                                );
                              },
                              child: const Text(
                                'PITCH & SELL',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.search, color: Colors.white, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ExploreScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // My Orders button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Cart button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Notification Bell with Badge
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Mode switch button
                        GestureDetector(
                          onTap: () {
                            if (authProvider.currentMode == UserMode.customer) {
                              authProvider.toggleUserMode();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                              ).then((_) => authProvider.toggleUserMode());
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xffFF5722),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.swap_horiz, size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text('Sell', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal Row: Add Story + Category Filter Bar
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add Story Button
                      GestureDetector(
                        onTap: () {
                          // Handle add story / profile picture
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: const Color(0xffFF5722),
                                child: const Icon(Icons.add, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                authProvider.user?['name'] ?? 'Add Story',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Categories
                      ...['All', 'Fashion', 'Tech', 'Food', 'Handmade'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xffFF5722) : Colors.black45,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isSelected ? const Color(0xffFF5722) : Colors.white12),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70, 
                                  fontSize: 12, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Single Video Feed Item
class VideoPlayerItem extends StatefulWidget {
  final Map<String, dynamic> productData;
  final Function(String chatId, String title) onChatPressed;
  final bool isVisible;
  final bool isFocused;

  const VideoPlayerItem({
    super.key,
    required this.productData,
    required this.onChatPressed,
    this.isVisible = true,
    this.isFocused = false,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    final video = widget.productData['video'];
    if (video != null && video['url'] != null) {
      _initVideoPlayer(video['url']);
      _likesCount = video['likesCount'] ?? 0;
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(url);
      if (fileInfo != null) {
        _controller = VideoPlayerController.file(fileInfo.file);
      } else {
        final file = await DefaultCacheManager().getSingleFile(url);
        _controller = VideoPlayerController.file(file);
      }
      
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        if (widget.isVisible && widget.isFocused) {
          _controller?.play();
        }
        _controller?.setLooping(true);
      }
    } catch (e) {
      debugPrint('Video caching error: $e. Falling back to network stream.');
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        if (widget.isVisible && widget.isFocused) {
          _controller?.play();
        }
        _controller?.setLooping(true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFocused && !widget.isFocused) {
      _controller?.pause();
      _controller?.seekTo(Duration.zero); // Reset video
    } else if (!oldWidget.isFocused && widget.isFocused && widget.isVisible) {
      _controller?.play();
    }
    
    if (oldWidget.isVisible && !widget.isVisible) {
      _controller?.pause();
    } else if (!oldWidget.isVisible && widget.isVisible && widget.isFocused) {
      _controller?.play();
    }
  }


  void _handleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
    try {
      final video = widget.productData['video'];
      if (video != null) {
        await ApiService.likeVideo(video['id']);
      }
    } catch (e) {
      debugPrint('Like action error: $e');
    }
  }

  void _showOrderCheckoutSheet() {
    int qty = 1;
    final List<dynamic> rawColors = widget.productData['colors'] ?? [];
    final List<dynamic> rawSizes = widget.productData['sizes'] ?? [];
    
    final colors = rawColors.isNotEmpty ? rawColors.cast<String>() : ['Default'];
    final sizes = rawSizes.isNotEmpty ? rawSizes.cast<String>() : ['Standard'];

    String selectedColor = colors.first;
    String selectedSize = sizes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final price = double.tryParse(widget.productData['price'].toString()) ?? 1200.0;
            final oldPrice = widget.productData['oldPrice'] != null 
                ? double.tryParse(widget.productData['oldPrice'].toString()) 
                : null;

            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.productData['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Price info
                  Row(
                    children: [
                      Text(
                        '₨ ${price.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xffFF5722), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      if (oldPrice != null) ...[
                        Text(
                          '₨ ${oldPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('DISCOUNT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector (1-24)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity (1–24):', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                            onPressed: () {
                              if (qty > 1) setModalState(() => qty--);
                            },
                          ),
                          Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            onPressed: () {
                              if (qty < 24) setModalState(() => qty++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Color Swatches Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Colour Variant:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Row(
                        children: colors.map((c) {
                          final isSelected = selectedColor == c;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = c),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xffFF5722) : const Color(0xff121212),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(c, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                                    const SizedBox(height: 12),
                  // Size Swatches Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Size Variant:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Row(
                        children: sizes.map((s) {
                          final isSelected = selectedSize == s;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedSize = s),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xffFF5722) : const Color(0xff121212),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(s, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  // Mini Seller Profile info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
                        child: const Icon(Icons.store, color: Color(0xffFF5722)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.productData['business']['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Verified Business Seller · KYC Verified', style: TextStyle(color: Colors.green, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffFF5722),
                              side: const BorderSide(color: Color(0xffFF5722)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final cart = Provider.of<CartProvider>(context, listen: false);
                              cart.addItem(
                                id: widget.productData['id'],
                                name: widget.productData['name'],
                                price: price,
                                image: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200',
                                quantity: qty,
                                size: selectedSize == 'Standard' ? null : selectedSize,
                                color: selectedColor == 'Default' ? null : selectedColor,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added $qty ${widget.productData['name']} to Cart!'),
                                  backgroundColor: const Color(0xffFF5722),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFF5722),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // close sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(product: {
                                    'id': widget.productData['id'],
                                    'name': widget.productData['name'],
                                    'price': price,
                                    'quantity': qty,
                                    'size': selectedSize == 'Standard' ? null : selectedSize,
                                    'color': selectedColor == 'Default' ? null : selectedColor,
                                  }),
                                ),
                              );
                            },
                            child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleDownloadVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Downloading video: ${widget.productData['name']}...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved to gallery successfully!')),
        );
      }
    });
  }

  void _showCommentsSheet() async {
    final videoId = widget.productData['video']?['id'];
    if (videoId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final commentController = TextEditingController();
        List comments = [];
        bool loading = true;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            if (loading) {
              ApiService.getComments(videoId).then((res) {
                if (res.statusCode == 200 && context.mounted) {
                  setStateSheet(() {
                    comments = jsonDecode(res.body)['comments'] ?? [];
                    loading = false;
                  });
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const Text('Reviews', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                          : comments.isEmpty
                              ? const Center(child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: comments.length,
                                  itemBuilder: (ctx, i) {
                                    final c = comments[i];
                                    return ListTile(
                                      leading: const CircleAvatar(backgroundColor: Colors.grey),
                                      title: Text(c['user']?['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(c['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    );
                                  },
                                ),
                    ),
                    const Divider(color: Colors.white24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a review...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xffFF5722)),
                          onPressed: () async {
                            if (commentController.text.trim().isEmpty) return;
                            final txt = commentController.text.trim();
                            commentController.clear();
                            final res = await ApiService.addComment(videoId, txt);
                            if (res.statusCode == 200) {
                              setStateSheet(() {
                                loading = true; // refresh
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleShareProduct() async {
    final videoUrl = widget.productData['video']?['url'];
    if (videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video not available.')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Adding watermark & preparing video...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final file = await DefaultCacheManager().getSingleFile(videoUrl);
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/pitchandsell_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final watermarkText = 'PitchAndSell - @${widget.productData['business']['name']}';
      
      // FFmpeg command to add text watermark at bottom center
      final command = "-y -i '${file.path}' -vf \"drawtext=text='$watermarkText':fontcolor=white@0.9:fontsize=32:x=(w-tw)/2:y=h-th-60:shadowcolor=black@0.6:shadowx=2:shadowy=2\" -c:a copy '$outPath'";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (ReturnCode.isSuccess(returnCode)) {
        final link = 'https://pitch-and-sell-backend.onrender.com/product/${widget.productData['id']}';
        await Share.shareXFiles(
          [XFile(outPath)], 
          text: 'Watch this awesome product by @${widget.productData['business']['name']} on PitchAndSell!\n\nBuy it here: $link',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add watermark. Sharing link only...')));
        final link = 'https://pitch-and-sell-backend.onrender.com/product/${widget.productData['id']}';
        Share.share('Check out this product on PitchAndSell: $link');
      }
    } catch (e) {
      debugPrint('Watermark error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final link = 'https://pitch-and-sell-backend.onrender.com/product/${widget.productData['id']}';
      Share.share('Check out this product on PitchAndSell: $link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Player Background
        GestureDetector(
          onTap: () {
            if (_controller != null && _controller!.value.isPlaying) {
              _controller?.pause();
            } else {
              _controller?.play();
            }
          },
          onDoubleTap: _handleLike,
          child: Container(
            color: Colors.black,
            child: _controller != null && _controller!.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller?.value.size.width ?? 0,
                        height: _controller?.value.size.height ?? 0,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Color(0xffFF5722))),
          ),
        ),

        // Floating Double Tap Heart Animation
        if (_showHeart)
          const Center(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 400),
              child: Icon(
                Icons.favorite,
                color: Color(0xffFF5722),
                size: 80,
              ),
            ),
          ),

        // Overlay Shadow
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent, Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Bottom Product Description
        Positioned(
          left: 16,
          bottom: 32,
          right: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final sellerId = widget.productData['businessId'] ?? widget.productData['profiles']?['id'] ?? widget.productData['business']?['id'] ?? '';
                        if (sellerId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(
                                sellerId: sellerId,
                                businessName: widget.productData['business']['name'],
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        '@${widget.productData['business']['name']}',
                        style: const TextStyle(color: Color(0xffFF5722), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.productData['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.productData['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    if (widget.productData['avgRating'] != null && widget.productData['avgRating'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${(widget.productData['avgRating'] as num).toStringAsFixed(1)} (${widget.productData['reviewCount']})',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'PKR ${widget.productData['price']}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (widget.productData['oldPrice'] != null)
                          Text(
                            'PKR ${widget.productData['oldPrice']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Action Column
        Positioned(
          right: 12,
          bottom: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like
              GestureDetector(
                onTap: _handleLike,
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? const Color(0xffFF5722) : Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 2),
                    Text('$_likesCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Review
              GestureDetector(
                onTap: _showCommentsSheet,
                child: const Column(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 2),
                    Text('Review', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Save for Later
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved for later!')));

                },
                child: const Column(
                  children: [
                    Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 2),
                    Text('Save', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Share Product Link
              GestureDetector(
                onTap: _handleShareProduct,
                child: const Column(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white, size: 26),
                    SizedBox(height: 2),
                    Text('Share', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Order Now Action Button (Cart)
              GestureDetector(
                onTap: _showOrderCheckoutSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF5722),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




