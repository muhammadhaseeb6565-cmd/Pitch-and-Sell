import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getOrders('seller');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _orders = data['orders'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller orders: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showShippingDialog(String orderId) {
    final trackingController = TextEditingController();
    String selectedCourier = 'TCS';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xff1e1e1e),
              title: const Text('Mark as Shipped', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    dropdownColor: const Color(0xff1e1e1e),
                    value: selectedCourier,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: ['TCS', 'Leopards', 'Trax', 'Bykea', 'Other'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCourier = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: trackingController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tracking Number',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
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
                  onPressed: () async {
                    if (trackingController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await ApiService.updateOrderStatus(
                      orderId,
                      'shipped',
                      trackingNumber: trackingController.text.trim(),
                      courierName: selectedCourier,
                    );
                    _fetchOrders();
                  },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Manage Orders', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _orders.isEmpty
              ? const Center(child: Text('No orders found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final isPending = order['status'] == 'pending' || order['status'] == 'processing';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e1e1e),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${order['id'].toString().substring(0, 8)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order['status'].toString().toUpperCase(),
                                  style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Product: ${order['product']['name']}', style: const TextStyle(color: Colors.grey)),
                          Text('Amount: PKR ${order['totalAmount']}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          if (isPending)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
                                onPressed: () => _showShippingDialog(order['id']),
                                child: const Text('Mark as Shipped & Add Tracking', style: TextStyle(color: Colors.white)),
                              ),
                            )
                          else if (order['trackingNumber'] != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.black26,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SHIPPING DETAILS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Courier: ${order['courierName']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  Text('Tracking ID: ${order['trackingNumber']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
