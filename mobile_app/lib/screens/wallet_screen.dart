import 'package:flutter/material.dart';
import '../utils/app_color_scheme.dart';

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
  bool _hasError = false;

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
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Color(0xff1e1e1e)
              : Colors.white,
          title: Text('Request Payout',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          content: Text(
              'Are you sure you want to withdraw PKR ${_balance.toStringAsFixed(0)} to your linked account?',
              style: const TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF5722)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Payout requested successfully!')),
                );
              },
              child: Text('Confirm',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        );
      },
    );
  }

  void _showSendDialog() {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1e1e1e) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send Money', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transfer funds directly to another seller or store wallet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Recipient Phone or User ID',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Amount (PKR)',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
            onPressed: () {
              final amt = double.tryParse(amountController.text.trim()) ?? 0;
              if (amt <= 0 || amt > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid amount or insufficient wallet balance.')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Transfer of ₨ ${amt.toStringAsFixed(0)} initiated successfully!')),
              );
            },
            child: const Text('Send Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1e1e1e) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Money to Wallet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Top up your Pitch & Sell wallet using instant local payment methods:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
              title: const Text('EasyPaisa / JazzCash', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant top-up via mobile account'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please send funds to Pitch & Sell Till: 0300-1234567 and upload receipt in Support.')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xffFF5722), child: Icon(Icons.account_balance, color: Colors.white)),
              title: const Text('Bank Transfer (Raast / IBFT)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Direct 1-Link bank deposit'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank: Meezan Bank | Title: Pitch & Sell | IBAN: PK00MEZN0000123456789012')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQrPayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1e1e1e) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(child: Text('My Store QR Code', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text('Scan to Pay or Transfer Funds', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xffFF5722))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xff1e1e1e)
            : Colors.white,
        title: Text('My Wallet',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load wallet data.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF5722)),
                        child: Text('Retry',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      )
                    ],
                  ),
                )
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
                            Text(
                              'PITCHANDSELL ESCROW BALANCE',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₨ ${_balance.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last Updated: Just Now',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface60,
                                  fontSize: 11),
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
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Request a manual withdrawal of your available funds.',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            TextButton(
                              onPressed: _showWithdrawDialog,
                              child: const Text('Withdraw',
                                  style: TextStyle(
                                      color: Color(0xffFF5722),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Linked Accounts
                      Text('Linked Accounts',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text(
                          'Manage your linked payment accounts in Settings',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 24),

                      // Quick actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickAction(Icons.arrow_upward, 'Send',
                              onTap: _showSendDialog),
                          _buildQuickAction(Icons.arrow_downward, 'Add Money',
                              onTap: _showAddMoneyDialog),
                          _buildQuickAction(Icons.wallet, 'Withdraw',
                              onTap: _showWithdrawDialog),
                          _buildQuickAction(Icons.qr_code_scanner, 'QR Pay',
                              onTap: _showQrPayDialog),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Transaction History
                      Text('Transaction History',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _transactions.isEmpty
                          ? const Text('No transactions found.',
                              style: TextStyle(color: Colors.grey))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transactions.length,
                              itemBuilder: (context, idx) {
                                final tx = _transactions[idx];
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Color(0xff1e1e1e)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(tx['title'] ?? 'Transaction',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text(tx['date'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                      Text(
                                        '${(tx['isCredit'] == true) ? '+' : ''}₨ ${(tx['amount'] as num?)?.abs() ?? 0}',
                                        style: TextStyle(
                                          color: (tx['isCredit'] == true)
                                              ? Colors.green
                                              : Colors.redAccent,
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


  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
              child: Icon(icon, color: const Color(0xffFF5722)),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
