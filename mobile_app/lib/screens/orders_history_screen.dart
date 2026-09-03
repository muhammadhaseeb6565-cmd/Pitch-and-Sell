import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getOrders('customer');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['orders'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Orders fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.indigo;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        elevation: 0,
        title: const Text('My Purchase Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _orders.isEmpty
              ? const Center(
                  child: Text(
                    'No orders placed yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final product = order['product'];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                              Text(
                                order['id'].toString().length >= 8 ? order['id'].toString().substring(0, 8) : order['id'].toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['status'] ?? 'UNKNOWN').withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order['status'] ?? 'UNKNOWN',
                                  style: TextStyle(
                                    color: _getStatusColor(order['status'] ?? 'UNKNOWN'),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          Text(
                            product['name'] ?? 'Unknown Product',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Qty: ${order['quantity'] ?? 1} x PKR ${order['unitPrice'] ?? 0}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                'PKR ${order['totalAmount'] ?? 0}',
                                style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mode: ${order['paymentMethod'] ?? 'N/A'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                'Date: ${order['createdAt'] != null ? order['createdAt'].toString().substring(0, 10) : 'N/A'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          _buildTimeline(order['status'] ?? 'UNKNOWN'),
                          if ((order['status'] ?? 'UNKNOWN') == 'PENDING' || (order['status'] ?? 'UNKNOWN') == 'ACCEPTED' || (order['status'] ?? 'UNKNOWN') == 'PROCESSING') ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _showCancelDialog(order['id']),
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildTimeline(String status) {
    if (status.toUpperCase() == 'CANCELLED' || status.toUpperCase() == 'RETURNED') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              'Order was cancelled / returned.',
              style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final steps = ['Pending', 'Accepted', 'Shipped', 'Delivered'];
    int activeIndex = 0;
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'PENDING') activeIndex = 0;
    if (upperStatus == 'ACCEPTED') activeIndex = 1;
    if (upperStatus == 'PROCESSING' || upperStatus == 'SHIPPED') activeIndex = 2;
    if (upperStatus == 'DELIVERED' || upperStatus == 'COMPLETED') activeIndex = 3;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Timeline:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= activeIndex;
              return Expanded(
                child: Row(
                  children: [
                    // Dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? const Color(0xffFF5722) : Colors.grey.shade800,
                        border: Border.all(
                          color: isCompleted ? const Color(0xffFF5722) : Colors.grey.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                    // Line
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < activeIndex ? const Color(0xffFF5722) : Colors.grey.shade800,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((step) {
              final idx = steps.indexOf(step);
              final isActive = idx <= activeIndex;
              return Text(
                step,
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1e1e1e),
          title: const Text('Cancel Order?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to cancel this order? This action cannot be undone and will restore product stock.', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final response = await ApiService.cancelOrder(orderId);
                  if (response.statusCode == 200 && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order cancelled successfully.')),
                    );
                    _fetchOrders(); // reload
                  }
                } catch (e) {
                  debugPrint('Cancel order failed: $e');
                }
              },
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
