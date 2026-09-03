import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  final _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;
  final _pinController = TextEditingController();
  
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalOrders': 0,
    'totalDeals': 0,
    'pendingPayouts': 0,
  };
  
  bool _isLoading = false;

  void _verifyPin() {
    // MVP-only PIN check
    if (_pinController.text == '8899') {
      setState(() {
        _isAuthenticated = true;
      });
      _fetchStats();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin PIN')));
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _supabase.from('profiles').select('id').count(CountOption.exact);
      final orders = await _supabase.from('orders').select('id').count(CountOption.exact);
      final payouts = await _supabase.from('payouts').select('id').eq('status', 'pending').count(CountOption.exact);
      final deals = await _supabase.from('deal_transactions').select('id').count(CountOption.exact);

      setState(() {
        _stats = {
          'totalUsers': profiles.count ?? 0,
          'totalOrders': orders.count ?? 0,
          'pendingPayouts': payouts.count ?? 0,
          'totalDeals': deals.count ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xff121212),
        appBar: AppBar(
          backgroundColor: const Color(0xff1e1e1e),
          title: const Text('Admin Portal', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, color: Color(0xffFF5722), size: 64),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Enter Admin PIN',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF5722),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _verifyPin,
                  child: const Text('Access Portal', style: TextStyle(color: Colors.white)),
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
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Platform Monitoring', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Statistics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Users', _stats['totalUsers'].toString(), Icons.people),
                      const SizedBox(width: 16),
                      _buildStatCard('Orders', _stats['totalOrders'].toString(), Icons.shopping_cart),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Deals Used', _stats['totalDeals'].toString(), Icons.local_offer),
                      const SizedBox(width: 16),
                      _buildStatCard('Pending Payouts', _stats['pendingPayouts'].toString(), Icons.payments),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff1e1e1e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xffFF5722), size: 32),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
