import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../screens/checkout_screen.dart';
import '../../../screens/seller_profile_screen.dart';
import 'dart:convert';

class FeedDialogService {
static void showOrderCheckoutSheet(BuildContext context, Map<String, dynamic> productData) {
    int qty = 1;
    final List<dynamic> rawColors = productData['colors'] ?? [];
    final List<dynamic> rawSizes = productData['sizes'] ?? [];
    
    final colors = rawColors.isNotEmpty ? rawColors.cast<String>() : ['Default'];
    final sizes = rawSizes.isNotEmpty ? rawSizes.cast<String>() : ['Standard'];

    String selectedColor = colors.first;
    String selectedSize = sizes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final price = double.tryParse(productData['price'].toString()) ?? 1200.0;
            final oldPrice = productData['oldPrice'] != null 
                ? double.tryParse(productData['oldPrice'].toString()) 
                : null;

            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            productData['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Price info
                  Row(
                    children: [
                      Text(
                        '₨ ${price.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xffFF5722), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      if (oldPrice != null) ...[
                        Text(
                          '₨ ${oldPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('DISCOUNT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector (1-24)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity (1–24):', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                            onPressed: () {
                              if (qty > 1) setModalState(() => qty--);
                            },
                          ),
                          Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            onPressed: () {
                              if (qty < 24) setModalState(() => qty++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Color Swatches Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Colour Variant:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Row(
                        children: colors.map((c) {
                          final isSelected = selectedColor == c;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = c),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xffFF5722) : const Color(0xff121212),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(c, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                                    const SizedBox(height: 12),
                  // Size Swatches Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Size Variant:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Row(
                        children: sizes.map((s) {
                          final isSelected = selectedSize == s;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedSize = s),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xffFF5722) : const Color(0xff121212),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(s, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  // Mini Seller Profile info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
                        child: const Icon(Icons.store, color: Color(0xffFF5722)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productData['business']['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Verified Business Seller · KYC Verified', style: TextStyle(color: Colors.green, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffFF5722),
                              side: const BorderSide(color: Color(0xffFF5722)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final cart = Provider.of<CartProvider>(context, listen: false);
                              cart.addItem(
                                id: productData['id'],
                                name: productData['name'],
                                price: price,
                                image: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200',
                                quantity: qty,
                                size: selectedSize == 'Standard' ? null : selectedSize,
                                color: selectedColor == 'Default' ? null : selectedColor,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added $qty ${productData['name']} to Cart!'),
                                  backgroundColor: const Color(0xffFF5722),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFF5722),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // close sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(product: {
                                    'id': productData['id'],
                                    'name': productData['name'],
                                    'price': price,
                                    'quantity': qty,
                                    'size': selectedSize == 'Standard' ? null : selectedSize,
                                    'color': selectedColor == 'Default' ? null : selectedColor,
                                  }),
                                ),
                              );
                            },
                            child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  static void showCommentsSheet(BuildContext context, Map<String, dynamic> productData) async {
    final videoId = productData['video']?['id'];
    if (videoId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final commentController = TextEditingController();
        List comments = [];
        bool loading = true;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            if (loading) {
              ApiService.getComments(videoId).then((res) {
                if (res.statusCode == 200 && context.mounted) {
                  setStateSheet(() {
                    comments = jsonDecode(res.body)['comments'] ?? [];
                    loading = false;
                  });
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const Text('Reviews', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                          : comments.isEmpty
                              ? const Center(child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: comments.length,
                                  itemBuilder: (ctx, i) {
                                    final c = comments[i];
                                    return ListTile(
                                      leading: const CircleAvatar(backgroundColor: Colors.grey),
                                      title: Text(c['user']?['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(c['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    );
                                  },
                                ),
                    ),
                    const Divider(color: Colors.white24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a review...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xffFF5722)),
                          onPressed: () async {
                            if (commentController.text.trim().isEmpty) return;
                            final txt = commentController.text.trim();
                            commentController.clear();
                            final res = await ApiService.addComment(videoId, txt);
                            if (res.statusCode == 200) {
                              setStateSheet(() {
                                loading = true; // refresh
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
