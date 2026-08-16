import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';
import 'dashboard_screen.dart';
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

  final List<Map<String, dynamic>> _wishlist = [
    {'id': 'w1', 'name': 'Premium Wireless Buds', 'price': 3500, 'img': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200'},
    {'id': 'w2', 'name': 'Ergonomic Desk Stand', 'price': 1800, 'img': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchMyVideos();
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
      print('Error fetching user profile videos: $e');
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
                        print(e);
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
    final avatarController = TextEditingController(text: auth.user?['avatarUrl']);

    // Business profile controllers if active
    final hasBusiness = auth.hasBusinessProfile;
    final businessProfile = auth.user?['businessProfile'] ?? {};
    final bNameController = TextEditingController(text: businessProfile['name']);
    final bCategoryController = TextEditingController(text: businessProfile['category']);
    final bDescController = TextEditingController(text: businessProfile['description']);
    final bPhoneController = TextEditingController(text: businessProfile['phone']);
    final bEmailController = TextEditingController(text: businessProfile['email']);
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
                            _buildField(avatarController, 'Profile Picture (URL)'),
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
                              _buildField(bEmailController, 'Contact Email'),
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
                          // 1. Update personal details
                          final personalResponse = await ApiService.updateProfile({
                            'name': nameController.text,
                            'avatarUrl': avatarController.text,
                          });

                          // 2. Update business details if exist
                          if (hasBusiness) {
                            await ApiService.updateBusiness({
                              'name': bNameController.text,
                              'category': bCategoryController.text,
                              'description': bDescController.text,
                              'phone': bPhoneController.text,
                              'email': bEmailController.text,
                              'city': bCityController.text,
                              'address': bAddressController.text,
                            });
                          }

                          if (personalResponse.statusCode == 200 && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile setup & changes saved successfully!')),
                            );
                            await auth.reloadUserProfile();
                            _fetchMyVideos();
                          }
                        } catch (e) {
                          print(e);
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
                    backgroundImage: user['avatarUrl'] != null && user['avatarUrl'].toString().isNotEmpty
                        ? NetworkImage(user['avatarUrl'])
                        : null,
                    child: user['avatarUrl'] != null && user['avatarUrl'].toString().isNotEmpty
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
                      _buildProfileBadge('Pro Seller', Colors.orange),
                      const SizedBox(width: 6),
                      _buildProfileBadge('Verified', Colors.green),
                      const SizedBox(width: 6),
                      _buildProfileBadge('KYC ✓', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('150', 'Following'),
                      _buildStatColumn('1.2K', 'Followers'),
                      _buildStatColumn('${_myProducts.length}', 'Pitches'),
                      _buildStatColumn('4.8 ★', 'Rating'),
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
                                      image: const DecorationImage(
                                        image: NetworkImage('https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200'),
                                        fit: BoxFit.cover,
                                        opacity: 0.35,
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
                    Expanded(child: _buildKpiCard('Revenue', '₨ 18.5K', Icons.attach_money, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard('Conversion', '4.2%', Icons.trending_up, Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('Total Orders', '124', Icons.shopping_bag, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard('Pitches Views', '12.4K', Icons.visibility, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 24),

                // Conversion Funnel Spec
                const Text('Conversion Funnel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFunnelRow('Pitches Views', 12400, 1.0),
                _buildFunnelRow('Video Clicks', 3200, 0.25),
                _buildFunnelRow('Add to Cart', 412, 0.08),
                _buildFunnelRow('Completed Purchased', 124, 0.04),

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
          _wishlist.isEmpty
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
                                    image: DecorationImage(
                                      image: NetworkImage(item['img']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _wishlist.removeAt(idx);
                                      });
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
                onTap: () {},
              ),
              ListTile(
                title: const Text('Terms of Agreement', style: TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                onTap: () {},
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
