import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static RealtimeChannel? _ordersChannel;
  static RealtimeChannel? _messagesChannel;

  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Request permissions for Android 13+
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _initialized = true;
    _listenToRealtime();
  }

  static void _listenToRealtime() {
    final client = Supabase.instance.client;
    
    // Auth state listener to re-subscribe if user changes
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _subscribeToChannels();
      } else {
        _ordersChannel?.unsubscribe();
        _messagesChannel?.unsubscribe();
      }
    });
  }

  static void _subscribeToChannels() {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      _ordersChannel?.unsubscribe();
    _ordersChannel = client.channel('public:orders').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'seller_id', value: userId),
      callback: (payload) {
        _showNotification('New Order Received! 🎉', 'Someone just bought your product. Check your dashboard.');
      },
    )..subscribe();

    _messagesChannel?.unsubscribe();
    _messagesChannel = client.channel('public:messages').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        final row = payload.newRecord;
        if (row['sender_id'] == userId) return; // Ignore our own messages
        
        // Ensure we are part of this chat
        final chatRes = await client.from('chats').select('user1_id, user2_id').eq('id', row['chat_id']).maybeSingle();
        if (chatRes != null && (chatRes['user1_id'] == userId || chatRes['user2_id'] == userId)) {
          _showNotification('New Message', row['content'] ?? 'You have a new message.');
        }
      },
    )..subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pitch_and_sell_main',
      'Pitch and Sell Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
    );
  }
}
