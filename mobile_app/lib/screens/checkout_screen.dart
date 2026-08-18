import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'Cash on Delivery (COD)';
  final String _deliveryAddress = 'House 14-A, Block C, Gulberg III, Lahore';

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] ?? 'Product';
    final price = double.tryParse(widget.product['price'].toString()) ?? 1200.0;
    const deliveryFee = 200.0;
    
    // Spec: convenience fee of 2% on orders > 5,000
    final convenienceFee = price > 5000 ? price * 0.02 : 0.0;
    final total = price + deliveryFee + convenienceFee;

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buyer Protection Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Buyer Protection Enabled\nFunds held securely in escrow until delivery is verified.',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Item summary
            const Text('Item Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff1e1e1e),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xffFF5722).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Color(0xffFF5722)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Qty: 1', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('₨ ${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delivery details
            const Text('Delivery Address', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff1e1e1e),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_deliveryAddress, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const Divider(color: Colors.white10, height: 24),
                  const Text('Standard Delivery (2-3 Days) — ₨ 200', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Options
            const Text('Select Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentRadio('Pay Now (Card/Wallet)'),
            _buildPaymentRadio('Cash on Delivery (COD)'),
            const SizedBox(height: 24),

            // Order Cost breakdowns
            const Text('Order Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildBreakdownRow('Subtotal', price),
            _buildBreakdownRow('Delivery Fee', deliveryFee),
            if (convenienceFee > 0)
              _buildBreakdownRow('Buyer convenience fee (2%)', convenienceFee),
            const Divider(color: Colors.white10, height: 24),
            _buildBreakdownRow('Total Amount', total, isBold: true),

            const SizedBox(height: 32),
            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final String method = _selectedPayment.contains('COD') ? 'COD' : 'PAY_NOW';
                  bool success = true;

                  if (widget.product.containsKey('items') && widget.product['items'] != null) {
                    final items = widget.product['items'] as List;
                    for (var item in items) {
                      final response = await ApiService.createOrder(item['id'], item['quantity'], method);
                      if (response.statusCode != 201) success = false;
                    }
                  } else if (widget.product.containsKey('id')) {
                    final qty = widget.product['quantity'] ?? 1;
                    final response = await ApiService.createOrder(widget.product['id'], qty, method);
                    if (response.statusCode != 201) success = false;
                  } else {
                    success = false;
                  }

                  if (success && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xff1e1e1e),
                        title: const Text('Order Placed Successfully!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: const Text(
                          'Your order has been recorded securely in the Emulgic ledger.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // close alert dialog
                              Navigator.pop(context); // close checkout screen
                            },
                            child: const Text('Back to Feed', style: TextStyle(color: Color(0xffFF5722))),
                          ),
                        ],
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to place order. Check network.')));
                  }
                },
                child: Text(
                  'Place Order via $_selectedPayment',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(String method) {
    return RadioListTile<String>(
      title: Text(method, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: method,
      groupValue: _selectedPayment,
      activeColor: const Color(0xffFF5722),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPayment = val);
      },
    );
  }

  Widget _buildBreakdownRow(String label, double val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.grey,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₨ ${val.toStringAsFixed(0)}',
            style: TextStyle(
              color: isBold ? const Color(0xffFF5722) : Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
