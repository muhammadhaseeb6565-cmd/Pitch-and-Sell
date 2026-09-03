import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _deals = [];

  @override
  void initState() {
    super.initState();
    _fetchDeals();
  }

  Future<void> _fetchDeals() async {
    try {
      final res = await _supabase.from('deals').select('*').eq('status', 'active');
      
      _deals = res;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claimDeal(String dealId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      // Record transaction, Emulgic gets PKR 5 fee
      await _supabase.from('deal_transactions').insert({
        'user_id': user.id,
        'deal_id': dealId,
        'platform_fee': 5
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xff1e1e1e),
            title: const Text('Deal Claimed!', style: TextStyle(color: Colors.white)),
            content: const Text('Show this screen at the outlet or use the applied discount code at checkout.', style: TextStyle(color: Colors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Color(0xffFF5722))),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not claim deal')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Card Deals & Offers', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _deals.isEmpty
              ? const Center(child: Text('No deals available right now. Check back later!', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _deals.length,
              itemBuilder: (context, index) {
                final deal = _deals[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e1e1e),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(deal['business_name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xffFF5722).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(deal['bank_or_card'], style: const TextStyle(color: Color(0xffFF5722), fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(deal['offer_title'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(deal['validity'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722), minimumSize: const Size(80, 32)),
                            onPressed: () => _claimDeal(deal['id']),
                            child: const Text('Claim Deal', style: TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
