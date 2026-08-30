import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocketService {
  static final _supabase = Supabase.instance.client;
  static RealtimeChannel? _channel;
  static Function(dynamic)? _onMessageCallback;

  static void connect(String userId) {
    // Supabase handles persistent connection automatically
  }

  static void joinChat(String chatId) {
    disconnect(); // leave previous channel if any
    
    _channel = _supabase.channel('public:messages:chat_id=eq.$chatId');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) {
        if (_onMessageCallback != null) {
          // Send it in the format the UI expects: { 'senderId': '...', 'content': '...' }
          final record = payload.newRecord;
          _onMessageCallback!({
            'senderId': record['sender_id'],
            'content': record['content'],
            'createdAt': record['created_at'],
          });
        }
      },
    ).subscribe();
  }

  static void sendMessage(String chatId, String senderId, String content) async {
    try {
      // In Supabase, inserting into the table automatically broadcasts via Realtime
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (e) {
      debugPrint('Supabase send message error: $e');
    }
  }

  static void onReceiveMessage(Function(dynamic) callback) {
    _onMessageCallback = callback;
  }

  static Future<List<dynamic>> fetchOldMessages(String chatId) async {
    try {
      final res = await _supabase
          .from('messages')
          .select('sender_id, content, created_at')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);
      return res;
    } catch (e) {
      debugPrint('Error fetching old messages: $e');
      return [];
    }
  }

  static Future<void> markAsRead(String chatId, String currentUserId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', currentUserId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  static void disconnect() {
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }
  }
}

