import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../main.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  // Mock chats list matching V1 requirements
  final List<Map<String, dynamic>> _chats = [
    {
      'id': 'mock-chat-room-1',
      'title': 'Alpha Wholesale Electronics',
      'lastMessage': 'Sure, I can send 50 units at PKR 1,500.',
      'time': '10:45 AM',
      'unread': true,
    },
    {
      'id': 'mock-chat-room-2',
      'title': 'Prime Hardware Suppliers',
      'lastMessage': 'Offer Accepted. Shipping starting tomorrow.',
      'time': 'Yesterday',
      'unread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        elevation: 0,
        title: const Text('Inbox Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _chats.isEmpty
          ? const Center(
              child: Text(
                'No conversations started yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _chats.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
                    child: const Icon(Icons.store, color: Color(0xffFF5722)),
                  ),
                  title: Text(
                    chat['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: chat['unread'] ? Colors.white70 : Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(chat['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      if (chat['unread'])
                        const CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xffFF5722),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chat['id'],
                          chatTitle: chat['title'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
