import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  final String? productId;
  final String? sellerId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatTitle,
    this.productId,
    this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SocketService.joinChat(widget.chatId);
    
    // Register receive listener
    SocketService.onReceiveMessage((data) {
      if (mounted) {
        setState(() {
          // Check if message already exists to avoid duplicates (since we optimistic update)
          bool exists = _messages.any((m) => m['content'] == data['content'] && m['senderId'] == data['senderId']);
          if (!exists) {
            _messages.add({
              'senderId': data['senderId'],
              'content': data['content'],
              'timestamp': data['createdAt'] ?? DateTime.now().toIso8601String(),
            });
            _scrollToBottom();
          }
        });
      }
    });

    _fetchOldMessages();
  }

  Future<void> _fetchOldMessages() async {
    try {
      final res = await SocketService.fetchOldMessages(widget.chatId);
          
      if (mounted) {
        setState(() {
          _messages.clear();
          for (var row in res) {
            _messages.add({
              'senderId': row['sender_id'],
              'content': row['content'],
              'timestamp': row['created_at'],
            });
          }
        });
        _scrollToBottom();
        
        // Mark as read
        final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        await SocketService.markAsRead(widget.chatId, user['id']);
      }
      }
    } catch (e) {
      debugPrint('Error fetching old messages: $e');

    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?['id'] ?? 'buyer-id';

    SocketService.sendMessage(widget.chatId, myId, text);
    
    setState(() {
      _messages.add({
        'senderId': myId,
        'content': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCreateOfferSheet() {
    final qtyController = TextEditingController(text: '10');
    final priceController = TextEditingController(text: '1500');
    final deliveryController = TextEditingController(text: '200');
    String paymentMethod = 'COD';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Structured Wholesale Offer',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Unit Price (PKR)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: deliveryController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Delivery Fee (PKR)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Mode:', style: TextStyle(color: Colors.white70)),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xff1e1e1e),
                    value: paymentMethod,
                    style: const TextStyle(color: Colors.white),
                    items: ['COD', 'PAY_NOW'].map((method) {
                      return DropdownMenuItem(value: method, child: Text(method));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => paymentMethod = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // Call backend api
                      try {
                        final authProv = Provider.of<AuthProvider>(context, listen: false);
                        final myId = authProv.user?['id'];
                        final response = await ApiService.createOffer({
                          'chatId': widget.chatId,
                          'productId': widget.productId!, 
                          'sellerId': widget.sellerId ?? '',
                          'quantity': int.parse(qtyController.text),
                          'unitPrice': double.parse(priceController.text),
                          'deliveryFee': double.parse(deliveryController.text),
                          'paymentMethod': paymentMethod,
                        });
                        if (response.statusCode == 201 && context.mounted) {
                          Navigator.pop(context);
                          final data = jsonDecode(response.body);
                          // Inject offer bubble directly
                          setState(() {
                            _messages.add({
                              'senderId': myId,
                              'type': 'offer',
                              'offer': data['offer'],
                            });
                        });
                        _scrollToBottom();
                      }
                    } catch (e) {
                      debugPrint('Offer error: $e');
                    }
                  },
                  child: const Text('Send Offer Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final myId = authProvider.user?['id'] ?? 'buyer-id';

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: Text(widget.chatTitle, style: const TextStyle(color: Colors.white)),
        actions: [
          if (widget.productId != null)
            IconButton(
              icon: const Icon(Icons.description_outlined, color: Color(0xffFF5722)),
              onPressed: _showCreateOfferSheet,
              tooltip: 'Send Structured Offer',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['type'] == 'offer') {
                  return OfferBubbleCard(
                    offer: msg['offer'],
                    isSender: msg['senderId'] == myId,
                  );
                }

                final isMe = msg['senderId'] == myId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xffFF5722) : const Color(0xff222222),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Chat input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            color: const Color(0xff1e1e1e),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xff121212),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xffFF5722)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Special Card Bubble representing Wholesale Negotiation Offers
class OfferBubbleCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final bool isSender;

  const OfferBubbleCard({
    super.key,
    required this.offer,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    final status = offer['status'] ?? 'PENDING';
    final isPending = status == 'PENDING';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff2c2c2c),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFF5722), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment, color: Color(0xffFF5722), size: 20),
                  SizedBox(width: 8),
                  Text('Wholesale Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isPending ? Colors.amber : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Text('Quantity: ${offer['quantity']}', style: const TextStyle(color: Colors.white70)),
          Text('Unit Price: PKR ${offer['unitPrice']}', style: const TextStyle(color: Colors.white70)),
          Text('Delivery Fee: PKR ${offer['deliveryFee']}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            'Total Amount: PKR ${offer['totalAmount']}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (isPending && !isSender) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      try {
                        final response = await ApiService.acceptOffer(offer['id']);
                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Offer accepted! Order created.')),
                          );
                        }
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    onPressed: () async {
                      try {
                        await Supabase.instance.client.from('offers').update({'status': 'declined'}).eq('id', offer['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer declined.')));
                        }
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: const Text('Decline', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}


