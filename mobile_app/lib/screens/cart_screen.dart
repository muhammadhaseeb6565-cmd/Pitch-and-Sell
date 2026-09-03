import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';
import '../main.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;

    const deliveryFee = 200.0;
    final subtotal = cart.subtotal;
    final convenienceFee = subtotal > 5000 ? subtotal * 0.02 : 0.0;
    final total = subtotal > 0 ? (subtotal + deliveryFee + convenienceFee) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Shopping Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5722)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Shopping', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff1e1e1e),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
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
                                  Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('₨ ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      cart.updateQuantity(item.id, item.quantity - 1);
                                    } else {
                                      cart.removeItem(item.id);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    cart.updateQuantity(item.id, item.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xff1e1e1e),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                          Text('₨ ${subtotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                          const Text('₨ 200', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      if (convenienceFee > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Buyer convenience fee (2%)', style: TextStyle(color: Colors.grey)),
                            Text('₨ ${convenienceFee.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('₨ ${total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF5722),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  product: {
                                    'name': items.length == 1 ? items.first.name : '${items.length} items in Cart',
                                    'price': subtotal,
                                    'items': items.map((i) => {
                                      'id': i.id, 
                                      'quantity': i.quantity,
                                      'size': i.size,
                                      'color': i.color
                                    }).toList(),
                                  },
                                ),
                              ),
                            ).then((result) {
                              // Clear the cart on successful order
                              if (result == true) {
                                cart.clear();
                              }
                            });
                          },
                          child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
