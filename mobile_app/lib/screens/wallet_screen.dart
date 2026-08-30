import 'package:flutter/material.dart';

import 'dart:convert';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await ApiService.getLedger();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _balance = (data['summary']['availableForPayout'] as num).toDouble();
          _transactions = data['entries'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('My Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFF5722), Color(0xffE64A19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffFF5722).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PITCHANDSELL ESCROW BALANCE',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₨ ${_balance.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Updated: Just Now',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Early Withdrawal Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Next automated payout due: 20 Aug.\nEarly manual withdrawal is available now.',
                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manual payout initiated!')),
                      );
                    },
                    child: const Text('Withdraw', style: TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Linked Accounts
            const Text('Linked Accounts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildLinkedAccountTile('JazzCash', '0300****512', Colors.orange),
            _buildLinkedAccountTile('Easypaisa', '0345****889', Colors.green),
            _buildLinkedAccountTile('HBL Bank', 'HBL-0042****110', Colors.teal),
            const SizedBox(height: 24),

            // Quick actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.arrow_upward, 'Send'),
                _buildQuickAction(Icons.arrow_downward, 'Add Money'),
                _buildQuickAction(Icons.wallet, 'Withdraw'),
                _buildQuickAction(Icons.qr_code_scanner, 'QR Pay'),
              ],
            ),
            const SizedBox(height: 32),

            // Transaction History
            const Text('Transaction History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _transactions.isEmpty ? const Text('No transactions found.', style: TextStyle(color: Colors.grey)) : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              itemBuilder: (context, idx) {
                final tx = _transactions[idx];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
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
                          Text(tx['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(tx['date'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Text(
                        '${tx['isCredit'] ? '+' : ''}₨ ${(tx['amount'] as num).abs()}',
                        style: TextStyle(
                          color: tx['isCredit'] ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedAccountTile(String name, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1e1e1e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xffFF5722)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

