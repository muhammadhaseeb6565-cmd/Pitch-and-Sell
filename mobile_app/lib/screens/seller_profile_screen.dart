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
      
      if (mounted) {
        setState(() {
          _products = res;
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
                const SizedBox(height: 8),
                const Text(
                  'Verified Business Seller',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
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
                          return Container(
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
                                      image: const DecorationImage(
                                        image: NetworkImage('https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200'),
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
