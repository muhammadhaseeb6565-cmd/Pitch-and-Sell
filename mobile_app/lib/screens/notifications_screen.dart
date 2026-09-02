import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> notifs = [];

      // Fetch buyer orders for status updates
      final buyerRes = await ApiService.getOrders('buyer');
      if (buyerRes.statusCode == 200) {
        final data = jsonDecode(buyerRes.body);
        for (var order in data['orders']) {
          notifs.add({
            'title': 'Order ''',
            'body': 'Your order for '' is currently ''.',
            'time': DateTime.parse(order['created_at']),
            'icon': Icons.local_shipping,
            'color': Colors.blue,
          });
        }
      }

      // Fetch seller orders for sales alerts
      final sellerRes = await ApiService.getOrders('seller');
      if (sellerRes.statusCode == 200) {
        final data = jsonDecode(sellerRes.body);
        for (var order in data['orders']) {
          notifs.add({
            'title': 'New Sale!',
            'body': 'Someone purchased ''.',
            'time': DateTime.parse(order['created_at']),
            'icon': Icons.shopping_bag,
            'color': const Color(0xffFF5722),
          });
        }
      }

      notifs.sort((a, b) => b['time'].compareTo(a['time']));

      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xff1e1e1e) : Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
          : _notifications.isEmpty
              ? const Center(
                  child: Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  color: const Color(0xffFF5722),
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, idx) {
                      final notif = _notifications[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff1e1e1e) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: (notif['color'] as Color).withOpacity(0.12),
                              child: Icon(notif['icon'], color: notif['color'], size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif['title'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif['body'],
                                    style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeago.format(notif['time']),
                                    style: const TextStyle(color: Colors.white24, fontSize: 9),
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
    );
  }
}


