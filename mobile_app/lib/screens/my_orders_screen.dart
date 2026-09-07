import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
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
      final res = await ApiService.getOrders('buyer');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _orders = data['orders'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching buyer orders: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showReviewDialog(String productId) {
    double rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xff1e1e1e),
              title: const Text('Leave a Review', style: TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = index + 1.0);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    style: const TextStyle(color: Color(0xff2d2d2d)),
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(color: Colors.grey),
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
                    Navigator.pop(context);
                    await ApiService.addReview(productId, rating, commentController.text.trim());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
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
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff1e1e1e)
        : Colors.white;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Text('My Orders & Tracking',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _orders.isEmpty
              ? const Center(child: Text('You have no orders yet.', style: TextStyle(color: Colors.grey)))
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
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order['id'].toString().substring(0, 8)}',
                                style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: isPending ? Colors.orange : Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Product: ${order['product']['name']}',
                            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Total Paid: PKR ${order['totalAmount']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          // Shipping / ETA Details Box
                          if (order['trackingNumber'] != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.local_shipping, color: Colors.blue, size: 16),
                                      SizedBox(width: 6),
                                      Text('SHIPPING DETAILS',
                                          style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Courier: ${order['courierName']}',
                                    style: TextStyle(color: textColor, fontSize: 14),
                                  ),
                                  Text(
                                    'Estimated Time of Arrival: ${order['trackingNumber']}',
                                    style: const TextStyle(color: Color(0xffFF5722), fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Seller is preparing your order. Estimated arrival time will appear here soon.',
                                      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!isPending && order['product'] != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber,
                                  side: const BorderSide(color: Colors.amber),
                                ),
                                icon: const Icon(Icons.star_border),
                                label: const Text('Leave a Review'),
                                onPressed: () {
                                  _showReviewDialog(order['productId']);
                                },
                              ),
                            )
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
