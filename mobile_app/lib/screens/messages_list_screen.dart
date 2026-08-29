import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch chats where the user is either user1 or user2
      final response = await _supabase
          .from('chats')
          .select('id, user1_id, user2_id, created_at')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> loadedChats = [];
      for (var chat in response) {
        String otherUserId = chat['user1_id'] == user.id ? chat['user2_id'] : chat['user1_id'];
        
        // Fetch the other user's profile
        var profileRes;
        try {
          profileRes = await _supabase.from('profiles').select('name, business_name, is_business').eq('id', otherUserId).maybeSingle();
        } catch (_) {}

        String title = 'User';
        if (profileRes != null) {
          title = (profileRes['is_business'] == true && profileRes['business_name'] != null) 
              ? profileRes['business_name'] 
              : profileRes['name'] ?? 'User';
        }

        // Fetch the last message
        var lastMessageRes;
        try {
          lastMessageRes = await _supabase
              .from('messages')
              .select('content, created_at, is_read, sender_id')
              .eq('chat_id', chat['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
        } catch (_) {}

        String lastMessage = 'Start chatting';
        bool unread = false;
        String time = chat['created_at'].toString().substring(0, 10); // fallback

        if (lastMessageRes != null) {
          lastMessage = lastMessageRes['content'];
          unread = (lastMessageRes['is_read'] == false && lastMessageRes['sender_id'] != user.id);
          
          final date = DateTime.parse(lastMessageRes['created_at']).toLocal();
          final now = DateTime.now();
          if (date.year == now.year && date.month == now.month && date.day == now.day) {
            time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          } else {
            time = "${date.month}/${date.day}";
          }
        }

        loadedChats.add({
          'id': chat['id'],
          'title': title,
          'lastMessage': lastMessage,
          'time': time,
          'unread': unread,
        });
      }

      setState(() {
        _chats = loadedChats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching chats: $e');
      setState(() => _isLoading = false);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchChats,
          )
        ],
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
                        child: const Icon(Icons.person, color: Color(0xffFF5722)),
                      ),
                      title: Text(
                        chat['title'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        chat['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: chat['unread'] ? Colors.white : Colors.grey, fontWeight: chat['unread'] ? FontWeight.bold : FontWeight.normal),
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
                        ).then((_) => _fetchChats()); // refresh on return
                      },
                    );
                  },
                ),
    );
  }
}
