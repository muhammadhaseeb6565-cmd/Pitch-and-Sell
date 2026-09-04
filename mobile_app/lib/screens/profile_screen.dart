import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_screen.dart';
import 'dashboard_screen.dart';
import 'seller_profile_screen.dart';
import 'admin_portal_screen.dart';
import 'package:flutter/services.dart';
import 'checkout_screen.dart';
import 'wallet_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myProducts = [];
  bool _loadingVideos = true;
  String _appLanguage = 'English';
  bool _darkMode = true;
  bool _pushNotifications = true;

  List<dynamic> _wishlist = [];
  bool _loadingWishlist = true;
  
  Map<String, dynamic> _profileStats = {
    'totalProducts': 0,
    'totalOrders': 0,
    'avgRating': 0.0,
    'reviewCount': 0,
  };
  Map<String, dynamic> _ledgerSummary = {
    'grossSales': 0.0,
    'platformFees': 0.0,
    'netEarnings': 0.0,
    'paidOut': 0.0,
    'pendingPayouts': 0.0,
    'availableForPayout': 0.0,
    'conversion': 0.0,
    'totalOrders': 0,
    'totalViews': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchMyVideos();
    _fetchWishlist();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?['id'];
    if (userId != null) {
      try {
        final statsRes = await ApiService.getProfileStats(userId);
        if (statsRes.statusCode == 200) {
          setState(() {
            _profileStats = jsonDecode(statsRes.body);
          });
        }
      } catch (e) {
        debugPrint('Error stats: $e');
      }
    }
    
    try {
      final ledgerRes = await ApiService.getLedger();
      if (ledgerRes.statusCode == 200) {
        setState(() {
          _ledgerSummary = jsonDecode(ledgerRes.body)['summary'] ?? _ledgerSummary;
        });
      }
    } catch (e) {
      debugPrint('Error ledger: $e');
    }
  }

  Future<void> _fetchWishlist() async {
    try {
      final res = await ApiService.getSavedVideos();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _wishlist = data['saved'] ?? [];
          _loadingWishlist = false;
        });
      } else {
        setState(() => _loadingWishlist = false);
      }
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      setState(() => _loadingWishlist = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyVideos() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.getFeed();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allProducts = data['products'] as List;
        final businessId = auth.user?['businessProfile']?['id'];
        setState(() {
          _myProducts = allProducts.where((p) => p['businessId'] == businessId).toList();
          _loadingVideos = false;
        });
      } else {
        setState(() => _loadingVideos = false);
      }
    } catch (e) {
      debugPrint('Error fetching user profile videos: $e');
      setState(() => _loadingVideos = false);
    }
  }

  void _showOnboardingSheet(AuthProvider auth) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Electronics');
    final descController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController(text: auth.user?['email']);
    final cityController = TextEditingController(text: 'Lahore');
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register Business Profile',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                _buildField(nameController, 'Business Name'),
                _buildField(categoryController, 'Category'),
                _buildField(descController, 'Description'),
                _buildField(phoneController, 'Phone Number'),
                _buildField(emailController, 'Contact Email'),
                _buildField(cityController, 'City'),
                _buildField(addressController, 'Address'),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        final response = await ApiService.createBusiness({
                          'name': nameController.text,
                          'category': categoryController.text,
                          'description': descController.text,
                          'phone': phoneController.text,
                          'email': emailController.text,
                          'city': cityController.text,
                          'address': addressController.text,
                        });
                        if (response.statusCode == 201 && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile created. Awaiting Verification.')),
                          );
                          await auth.reloadUserProfile();
                          _fetchMyVideos();
                        }
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: const Text('Submit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPersonalProfileSheet(AuthProvider auth) {
    final nameController = TextEditingController(text: auth.user?['name']);
    String? localImagePath;

    // Business profile controllers if active
    final hasBusiness = auth.hasBusinessProfile;
    final businessProfile = auth.user?['businessProfile'] ?? {};
    final bNameController = TextEditingController(text: businessProfile['name']);
    final bCategoryController = TextEditingController(text: businessProfile['category']);
    final bDescController = TextEditingController(text: businessProfile['description']);
    final bPhoneController = TextEditingController(text: businessProfile['phone']);
    // Removed bEmailController as it is permanent
    final bCityController = TextEditingController(text: businessProfile['city']);
    final bAddressController = TextEditingController(text: businessProfile['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DefaultTabController(
          length: hasBusiness ? 2 : 1,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Setup & Edit Profile',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    indicatorColor: const Color(0xffFF5722),
                    labelColor: const Color(0xffFF5722),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      const Tab(text: 'Personal Account'),
                      if (hasBusiness) const Tab(text: 'Business Details'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: hasBusiness ? 300 : 180,
                    child: TabBarView(
                      children: [
                        // Tab 1: Personal
                        ListView(
                          shrinkWrap: true,
                          children: [
                            _buildField(nameController, 'Full Name'),
                            const SizedBox(height: 12),
                            const Text('Profile Picture', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  setModalState(() {
                                    localImagePath = pickedFile.path;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.image, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        localImagePath ?? 'Tap to select an image from gallery',
                                        style: TextStyle(color: localImagePath != null ? Colors.white : Colors.grey, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Tab 2: Business details if exist
                        if (hasBusiness)
                          ListView(
                            shrinkWrap: true,
                            children: [
                              _buildField(bNameController, 'Business Name'),
                              _buildField(bCategoryController, 'Category'),
                              _buildField(bDescController, 'Description'),
                              _buildField(bPhoneController, 'Phone Number'),
                              _buildField(bCityController, 'City'),
                              _buildField(bAddressController, 'Address'),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF5722),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          // 1. Update personal details locally
                          await auth.updateUserLocalField('name', nameController.text);
                          if (localImagePath != null) {
                            await auth.updateUserLocalField('avatar', localImagePath);
                          }
                          
                          // Mock backend call (fails gracefully if backend offline)
                          try {
                            await ApiService.updateProfile({
                              'name': nameController.text,
                              'avatarUrl': localImagePath ?? auth.user?['avatar'],
                            }).timeout(const Duration(seconds: 2));
                          } catch (_) {}

                          // 2. Update business details if exist
                          if (hasBusiness) {
                            // Update business details locally (Mocked)
                            final newBus = {
                                'name': bNameController.text,
                                'category': bCategoryController.text,
                                'description': bDescController.text,
                                'phone': bPhoneController.text,
                                'city': bCityController.text,
                                'address': bAddressController.text,
                            };
                            await auth.updateUserLocalField('businessProfile', newBus);
                            
                            try {
                              await ApiService.updateBusiness({
                                'name': bNameController.text,
                                'category': bCategoryController.text,
                                'description': bDescController.text,
                                'phone': bPhoneController.text,
                                'city': bCityController.text,
                                'address': bAddressController.text,
                              }).timeout(const Duration(seconds: 2));
                            } catch (_) {}
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated successfully!')),
                            );
                            _fetchMyVideos();
                          }
                        } catch (e) {
                          debugPrint(e.toString());
                        }
                      },
                      child: const Text('Save Setup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) return const SizedBox();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xff1e1e1e) : Colors.white,
        elevation: 0,
        title: Text('My Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xffFF5722)),
            tooltip: 'Setup Profile',
            onPressed: () => _showEditPersonalProfileSheet(auth),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xffFF5722),
          labelColor: const Color(0xffFF5722),
          unselectedLabelColor: Colors.grey,
          isScrollable: false,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 18), text: 'Profile'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.favorite, size: 18), text: 'Wishlist'),
            Tab(icon: Icon(Icons.settings, size: 18), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Profile View
          RefreshIndicator(
            onRefresh: _fetchMyVideos,
            color: const Color(0xffFF5722),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
                    backgroundImage: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                        ? (user['avatar'].toString().startsWith('http')
                            ? NetworkImage(user['avatar']) as ImageProvider
                            : FileImage(File(user['avatar'])))
                        : null,
                    child: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                        ? null
                        : const Icon(Icons.person, size: 46, color: Color(0xffFF5722)),
                  ),
                  const SizedBox(height: 16),
                  Text(user['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),

                  // Profile badges / tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (auth.hasBusinessProfile) _buildProfileBadge('Pro Seller', Colors.orange),
                      if (auth.hasBusinessProfile) const SizedBox(width: 6),
                      if (user['is_verified'] == true) _buildProfileBadge('Verified', Colors.green),
                      if (user['is_verified'] == true) const SizedBox(width: 6),
                      if (user['kyc_status'] == 'approved') _buildProfileBadge('KYC ✓', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('${_profileStats['totalOrders'] ?? 0}', 'Orders'),
                      _buildStatColumn('${_myProducts.length}', 'Pitches'),
                      _buildStatColumn('${(_profileStats['avgRating'] ?? 0.0).toStringAsFixed(1)} ★', 'Rating'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xffFF5722).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffFF5722).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Color(0xffFF5722), size: 20),
                              SizedBox(width: 12),
                              Text(
                                'My PitchnSell Wallet',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'View Balance',
                                style: TextStyle(color: Color(0xffFF5722), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xffFF5722)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  if (auth.hasBusinessProfile) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('My Pitches Grid', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    _loadingVideos
                        ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                        : _myProducts.isEmpty
                            ? const Text('No pitches uploaded.', style: TextStyle(color: Colors.grey))
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: _myProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _myProducts[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xff1e1e1e),
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: product['thumbnailUrl'] != null 
                                            ? NetworkImage(product['thumbnailUrl']) as ImageProvider
                                            : const AssetImage('assets/images/placeholder.png'),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.darken),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28)),
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          right: 4,
                                          child: Text(
                                            product['name'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e1e1e),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Sell your own products on Pitch and Sell!', style: TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
                            onPressed: () => _showOnboardingSheet(auth),
                            child: const Text('Create Business Profile', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tab 2: Dashboard View
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Business Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('Revenue', '₨ ${_ledgerSummary['grossSales'] ?? 0}', Icons.attach_money, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard('Conversion', '${_ledgerSummary['conversion'] ?? 0}%', Icons.trending_up, Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('Total Orders', '${_ledgerSummary['totalOrders'] ?? 0}', Icons.shopping_bag, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard('Pitches Views', '${_ledgerSummary['totalViews'] ?? 0}', Icons.visibility, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 24),

                // Conversion Funnel Spec
                const Text('Conversion Funnel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFunnelRow('Pitches Views', _ledgerSummary['totalViews'] ?? 0, 1.0),
                _buildFunnelRow('Video Clicks', ((_ledgerSummary['totalViews'] ?? 0) * 0.25).toInt(), 0.25),
                _buildFunnelRow('Add to Cart', ((_ledgerSummary['totalViews'] ?? 0) * 0.08).toInt(), 0.08),
                _buildFunnelRow('Completed Purchased', _ledgerSummary['totalOrders'] ?? 0, 0.04),

                const SizedBox(height: 24),
                // Withdraw Action
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
                    onPressed: () {
                      auth.toggleUserMode();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      ).then((_) {
                        auth.toggleUserMode();
                        _fetchMyVideos();
                      });
                    },
                    icon: const Icon(Icons.dashboard, color: Colors.white),
                    label: const Text('Open Full Seller Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Tab 3: Wishlist View
          _loadingWishlist 
            ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
            : _wishlist.isEmpty
              ? const Center(child: Text('Your wishlist is empty.', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _wishlist.length,
                  itemBuilder: (context, idx) {
                    final item = _wishlist[idx];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e1e1e),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      colors: [Colors.black54, Colors.black87],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.video_library, color: Colors.grey, size: 32),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final res = await ApiService.toggleSaveVideo(item['id']);
                                      if (res.statusCode == 200) {
                                        setState(() {
                                          _wishlist.removeAt(idx);
                                        });
                                      }
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('₨ ${item['price']}', style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722), padding: EdgeInsets.zero),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CheckoutScreen(product: item)),
                                );
                              },
                              child: const Text('Quick Buy', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          // Tab 4: Settings View
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Preferences', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Dark Theme Mode', style: TextStyle(color: Colors.grey, fontSize: 13)),
                value: auth.isDarkMode,
                activeColor: const Color(0xffFF5722),
                onChanged: (val) {
                  auth.toggleTheme();
                },
              ),
              SwitchListTile(
                title: const Text('Push Notifications', style: TextStyle(color: Colors.grey, fontSize: 13)),
                value: _pushNotifications,
                activeColor: const Color(0xffFF5722),
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),
              ListTile(
                title: const Text('Language Selector', style: TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: Text(_appLanguage, style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold)),
                onTap: () {
                  setState(() {
                    _appLanguage = _appLanguage == 'English' ? 'اردو (Urdu)' : 'English';
                  });
                },
              ),
              const Divider(color: Colors.white10, height: 32),
              const Text('Support & Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text('Help Center & FAQs', style: TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                onTap: () {
                  showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Coming soon'), content: Text('Help Center is under construction.'), backgroundColor: Color(0xff1e1e1e)));
                },
              ),
              ListTile(
                title: const Text('Terms of Agreement', style: TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                onTap: () {
                  showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Coming soon'), content: Text('Terms of Agreement will be available soon.'), backgroundColor: Color(0xff1e1e1e)));
                },
              ),
              ListTile(
                title: const Text('Admin Portal (Restricted)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: const Icon(Icons.security, size: 16, color: Color(0xffFF5722)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPortalScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await auth.logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildKpiCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e1e1e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 8),
              Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String label, int value, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('$value', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xffFF5722)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}



