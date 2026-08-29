import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import '../main.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    try {
      final myId = Supabase.instance.client.auth.currentUser?.id;
      if (myId == null) return;
      
      final res = await Supabase.instance.client
          .from('messages')
          .select('chat_id, content, created_at')
          .or('chat_id.ilike.%$myId%')
          .order('created_at', ascending: false);

      final Map<String, dynamic> uniqueChats = {};
      for (var msg in res) {
        if (!uniqueChats.containsKey(msg['chat_id'])) {
          uniqueChats[msg['chat_id']] = {
            'id': msg['chat_id'],
            'title': 'Chat: ' + msg['chat_id'].toString().split('_').last.substring(0, 8) + '...',
            'lastMessage': msg['content'],
            'time': 'Recent',
            'unread': false,
          };
        }
      }

      if (mounted) {
        setState(() {
          _chats = uniqueChats.values.toList().cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        elevation: 0,
        title: const Text('Inbox Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _chats.isEmpty
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
