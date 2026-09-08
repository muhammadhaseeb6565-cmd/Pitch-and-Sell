import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'live_stream_screen.dart';
import 'explore_screen.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import '../features/feed/widgets/video_player_item.dart';
import 'my_orders_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'category_preferences_screen.dart';

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
  bool _showBillboard = true;

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
        final list = (data['products'] as List<dynamic>?) ?? [];
        if (list.isNotEmpty) {
          setState(() {
            _products = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching feed: $e');
    }

    // High quality sample experience videos for demonstration and interactive testing
    setState(() {
      _products = [
        {
          'id': 'exp-demo-001',
          'name': 'Wireless Active Noise-Cancelling Headphones',
          'description': 'Studio sound with 40mm drivers, active noise cancellation, 40-hour battery life, and ultra-fast charging. Cash on delivery available across Pakistan!',
          'price': 4990.0,
          'seller_id': 'exp-seller-001',
          'sizes': ['Standard'],
          'colors': ['Midnight Black', 'Platinum Silver'],
          'avgRating': 4.9,
          'reviewCount': 38,
          'business': {'name': 'SoundMaster Store'},
          'video': {
            'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            'likesCount': 420,
            'allowDownload': true,
          }
        },
        {
          'id': 'exp-demo-002',
          'name': 'Ultra HD AMOLED Smart Watch Pro',
          'description': 'Retina AMOLED curved display, calling via Bluetooth, blood oxygen & fitness tracking, IP68 waterproof rating.',
          'price': 3750.0,
          'seller_id': 'exp-seller-002',
          'sizes': ['45mm'],
          'colors': ['Space Grey', 'Rose Gold'],
          'avgRating': 4.8,
          'reviewCount': 52,
          'business': {'name': 'GadgetHub Pakistan'},
          'video': {
            'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
            'likesCount': 635,
            'allowDownload': true,
          }
        },
      ];
      _isLoading = false;
    });
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

          // Sticky Overlay Header: Search, Orders, Cart, Notifications, Category, Stories, Billboard
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Logo & Brand + 4 Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Brand Logo & Name
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LiveStreamScreen()),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFF5722),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffFF5722).withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PITCH & SELL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    shadows: [
                                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right: 4 Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeaderIconButton(
                                icon: Icons.search,
                                tooltip: 'Search',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ExploreScreen()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIconButton(
                                icon: Icons.receipt_long_outlined,
                                tooltip: 'My Orders',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Consumer<CartProvider>(
                                builder: (context, cart, _) {
                                  return _buildHeaderIconButton(
                                    icon: Icons.shopping_cart_outlined,
                                    tooltip: 'Cart',
                                    badgeCount: cart.items.length,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CartScreen()),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIconButton(
                                icon: Icons.notifications_none_outlined,
                                tooltip: 'Notifications',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Horizontal Row: Add Story + Category Filter Bar
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Add Story Button
                            GestureDetector(
                              onTap: () {
                                // Add story
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xffFF5722),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, size: 12, color: Colors.white),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      authProvider.user?['name'] != null && authProvider.user!['name'].toString().trim().isNotEmpty
                                          ? authProvider.user!['name'].toString().trim().split(' ').first
                                          : 'Story',
                                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dynamic User-Selected Categories Bar
                            ...(() {
                              final preferred = authProvider.preferredCategories;
                              final visibleCategories = preferred.isNotEmpty 
                                  ? ['All', ...preferred]
                                  : ['All', 'Clothing', 'Foods', 'Electronics', 'Beauty', 'Footwear'];

                              return visibleCategories.map((cat) {
                                final isSelected = _selectedCategory == cat;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    _fetchFeed();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xffFF5722) : Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(17),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xffFF5722) : Colors.white.withOpacity(0.18),
                                        width: 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xffFF5722).withOpacity(0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });
                            }()),
                            // Preferences shortcut button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CategoryPreferencesScreen(isFirstTime: false)),
                                ).then((_) => _fetchFeed());
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune, size: 13, color: Colors.white70),
                                    SizedBox(width: 4),
                                    Text(
                                      'Filter',
                                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Billboard - visible only on the first feed video and if not dismissed
                      if (_currentIndex == 0 && _showBillboard) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ExploreScreen()),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF6B35).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "Featured Pitches • Tap to explore trending deals",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() => _showBillboard = false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            if (badgeCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xffFF5722),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Center(
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Single Video Feed Item
