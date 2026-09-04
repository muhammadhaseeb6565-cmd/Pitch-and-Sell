import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'manage_orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await ApiService.getNotifications();
      if (res.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(res.body)['notifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, idx) {
                    final notif = _notifications[idx];
                    final title = notif['title'] ?? 'Notification';
                    final body = notif['body'] ?? '';
                    final time = notif['created_at'] ?? 'Just now';
                    
                    return GestureDetector(
                      onTap: () {
                        if (notif['type'] == 'order') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
                          );
                        }
                      },
                      child: Container(
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
                              backgroundColor: const Color(0xffFF5722).withOpacity(0.12),
                              child: const Icon(Icons.notifications, color: Color(0xffFF5722), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    time.toString().split('T')[0], // Simplified time parsing
                                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
