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
import '../features/feed/widgets/video_player_item.dart';
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

