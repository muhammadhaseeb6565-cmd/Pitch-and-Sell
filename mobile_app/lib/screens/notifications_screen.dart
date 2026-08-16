import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'New Order Received! 🎉',
        'body': 'Seller Dashboard: Order #9812 has been placed for Premium Wireless Buds.',
        'time': '5 mins ago',
        'icon': Icons.shopping_bag,
        'color': const Color(0xffFF5722),
      },
      {
        'title': 'Escrow Payout Released 💸',
        'body': '₨ 3,500 has been transferred to your available balance after 48hr delivery hold.',
        'time': '2 hours ago',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
      },
      {
        'title': 'KYC Verification Approved ✓',
        'body': 'Congratulations! Your business credentials have been verified by PitchnSell team.',
        'time': '1 day ago',
        'icon': Icons.verified,
        'color': Colors.blue,
      },
    ];

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
      body: notifications.isEmpty
          ? const Center(
              child: Text('No notifications yet', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, idx) {
                final notif = notifications[idx];
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
                        backgroundColor: notif['color'].withOpacity(0.12),
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
                              notif['time'],
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
    );
  }
}
