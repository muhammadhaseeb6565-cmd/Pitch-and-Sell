import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;
  final _pinController = TextEditingController();
  TabController? _tabController;

  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalOrders': 0,
    'totalDeals': 0,
    'pendingPayouts': 0,
    'pendingPromos': 0,
  };

  bool _isLoadingStats = false;
  bool _isLoadingPromotions = false;
  List<dynamic> _promotions = [];
  String _selectedStatusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    // MVP-only PIN check
    if (_pinController.text == '8899') {
      setState(() {
        _isAuthenticated = true;
      });
      _fetchStats();
      _fetchPromotions();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid Admin PIN')));
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final profiles = await _supabase
          .from('profiles')
          .select('id')
          .count(CountOption.exact);
      final orders =
          await _supabase.from('orders').select('id').count(CountOption.exact);
      final payouts = await _supabase
          .from('payouts')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);
      final deals = await _supabase
          .from('deal_transactions')
          .select('id')
          .count(CountOption.exact);

      int pendingPromoCount = 0;
      try {
        final promos = await _supabase
            .from('promotions')
            .select('id')
            .eq('status', 'pending')
            .count(CountOption.exact);
        pendingPromoCount = promos.count;
      } catch (_) {}

      setState(() {
        _stats = {
          'totalUsers': profiles.count,
          'totalOrders': orders.count,
          'pendingPayouts': payouts.count,
          'totalDeals': deals.count,
          'pendingPromos': pendingPromoCount,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchPromotions() async {
    setState(() => _isLoadingPromotions = true);
    try {
      final res = await ApiService.getAllPromotionsForAdmin(
          statusFilter: _selectedStatusFilter);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _promotions = (data['promotions'] as List<dynamic>?) ?? [];
          _isLoadingPromotions = false;
        });
      } else {
        setState(() => _isLoadingPromotions = false);
      }
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
      if (mounted) {
        setState(() => _isLoadingPromotions = false);
      }
    }
  }

  Future<void> _handlePromotionDecision(String promoId, bool approve) async {
    try {
      final res = await ApiService.verifyPromotionPlan(promoId, approve);
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Promotion approved & activated on Billboard! 🎉'
                : 'Promotion request rejected.'),
            backgroundColor: approve ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchPromotions();
        _fetchStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update promotion status.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xff121212),
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Color(0xff1e1e1e)
              : Colors.white,
          title: Text('Admin Portal',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Color(0xffFF5722), size: 64),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Enter Admin PIN',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF5722),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _verifyPin,
                  child: Text('Access Portal',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xff1e1e1e)
            : Colors.white,
        title: Text('Admin Operations',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchStats();
              _fetchPromotions();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xffFF5722),
          labelColor: const Color(0xffFF5722),
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(
                icon: Icon(Icons.insights, size: 18), text: 'Platform Stats'),
            Tab(
              icon: const Icon(Icons.campaign, size: 18),
              text: _stats['pendingPromos'] > 0
                  ? 'Billboard (${_stats['pendingPromos']})'
                  : 'Billboard Requests',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Platform Stats
          _buildStatsTab(),

          // Tab 2: Billboard Promotion Requests
          _buildBillboardRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xffFF5722)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Statistics',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                  'Users', _stats['totalUsers'].toString(), Icons.people),
              const SizedBox(width: 16),
              _buildStatCard('Orders', _stats['totalOrders'].toString(),
                  Icons.shopping_cart),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Deals Used', _stats['totalDeals'].toString(),
                  Icons.local_offer),
              const SizedBox(width: 16),
              _buildStatCard('Pending Payouts',
                  _stats['pendingPayouts'].toString(), Icons.payments),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Pending Promos',
                  _stats['pendingPromos'].toString(), Icons.campaign,
                  highlight: _stats['pendingPromos'] > 0),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillboardRequestsTab() {
    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text('Filter:',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Active', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
              const SizedBox(width: 8),
              _buildFilterChip('All', 'All'),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoadingPromotions
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xffFF5722)))
              : _promotions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 54, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_selectedStatusFilter.toLowerCase()} promotion requests',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPromotions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _promotions.length,
                        itemBuilder: (context, index) {
                          final promo = _promotions[index];
                          return _buildPromotionCard(promo);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected =
        _selectedStatusFilter.toLowerCase() == value.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatusFilter = value);
        _fetchPromotions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffFF5722) : const Color(0xff222222),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? const Color(0xffFF5722) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCard(dynamic promo) {
    final product = promo['products'] ?? {};
    final profile = promo['profiles'] ?? {};
    final status = (promo['status'] ?? 'pending').toString().toLowerCase();
    final isPending = status == 'pending';
    final amount = promo['amount'] ?? 100;
    final paymentMethod = promo['payment_method'] ?? 'EasyPaisa';
    final transactionId = promo['transaction_id'] ?? 'N/A';
    final durationDays = promo['duration_days'] ?? 3;

    Color statusColor = Colors.orange;
    if (status == 'active') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xff1e1e1e)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xffFF5722).withOpacity(0.4)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xffFF5722).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.campaign,
                        color: Color(0xffFF5722), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plan: ${promo['plan_name'] ?? 'BILLBOARD'}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 18),

          // Product & Seller Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Product: ${product['name'] ?? 'Unknown'} (₨ ${product['price'] ?? '0'})',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Seller: ${profile['business_name'] ?? profile['name'] ?? 'Unknown'} (${profile['phone'] ?? profile['email'] ?? 'No contact'})',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface70,
                      fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Payment Details Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff252525),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Method: $paymentMethod',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 11.5)),
                    Text('Fee: ₨ $amount',
                        style: const TextStyle(
                            color: Color(0xffFF5722),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TID / Ref: $transactionId',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('Duration: $durationDays Days',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface54,
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Actions if pending
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () =>
                        _handlePromotionDecision(promo['id'].toString(), false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon:
                        const Icon(Icons.check, size: 16, color: Colors.white),
                    label: Text('Approve & Activate',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface)),
                    onPressed: () =>
                        _handlePromotionDecision(promo['id'].toString(), true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Color(0xff1e1e1e)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? const Color(0xffFF5722) : Colors.white12,
            width: highlight ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xffFF5722), size: 32),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface70,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
