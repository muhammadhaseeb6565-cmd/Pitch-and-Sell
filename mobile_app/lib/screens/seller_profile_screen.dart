import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String businessName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.businessName,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerProducts() async {
    try {
      final res = await Supabase.instance.client
          .from('products')
          .select('*, profiles:seller_id(*)')
          .eq('seller_id', widget.sellerId)
          .order('created_at', ascending: false);
          
      // Fetch completed orders count for badges
      int count = 0;
      try {
        final ordersRes = await Supabase.instance.client
            .from('orders')
            .select('id')
            .eq('seller_id', widget.sellerId)
            .eq('status', 'completed');
        count = ordersRes.length;
      } catch (e) {
        debugPrint('Error counting orders: $e');
      }
      
      if (mounted) {
        setState(() {
          _products = res;
          _completedOrders = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to chat.')));
      return;
    }

    try {
      // Check if chat exists
      final existingChat = await Supabase.instance.client
          .from('chats')
          .select('id')
          .or('and(user1_id.eq.${user.id},user2_id.eq.${widget.sellerId}),and(user1_id.eq.${widget.sellerId},user2_id.eq.${user.id})')
          .maybeSingle();

      String chatId;
      if (existingChat != null) {
        chatId = existingChat['id'];
      } else {
        final newChat = await Supabase.instance.client.from('chats').insert({
          'user1_id': user.id,
          'user2_id': widget.sellerId,
        }).select('id').single();
        chatId = newChat['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              chatTitle: widget.businessName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start chat.')));
    }
  }

  Widget _buildTierBadge() {
    if (_completedOrders >= 500) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.blue, size: 18),
          const SizedBox(width: 4),
          const Text('Top Rated Seller', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      );
    } else if (_completedOrders >= 400) {
      return _badgeUI('Diamond Seller 💎', Colors.cyanAccent);
    } else if (_completedOrders >= 200) {
      return _badgeUI('Platinum Seller', Colors.tealAccent);
    } else if (_completedOrders >= 50) {
      return _badgeUI('Gold Seller 🏆', Colors.amber);
    } else if (_completedOrders >= 10) {
      return _badgeUI('Silver Seller 🥈', Colors.grey[400]!);
    } else if (_completedOrders >= 5) {
      return _badgeUI('Bronze Seller 🥉', Colors.brown[300]!);
    }
    return const Text('New Seller 🌱', style: TextStyle(color: Colors.grey, fontSize: 13));
  }

  Widget _badgeUI(String text, Color color) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
       decoration: BoxDecoration(
         color: color.withOpacity(0.15),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: color.withOpacity(0.5)),
       ),
       child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        elevation: 0,
        title: Text(widget.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xff1e1e1e),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
                  child: const Icon(Icons.store, color: Color(0xffFF5722), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTierBadge(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('Chat with Seller', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Products', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                : _products.isEmpty
                    ? const Center(child: Text('No products available.', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigate to feed focused on this product
                              // Alternatively, to a placeholder product detail
                            },
                            child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff1e1e1e),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      image: DecorationImage(
                                        image: product['thumbnailUrl'] != null 
                                          ? NetworkImage(product['thumbnailUrl']) as ImageProvider
                                          : const AssetImage('assets/images/placeholder.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 40)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PKR ${product['price']}',
                                        style: const TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ));
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
