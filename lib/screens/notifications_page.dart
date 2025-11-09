import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Notifications",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => NotificationService.clearNotifications(),
            tooltip: "Clear all",
          )
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: NotificationService.notifier,
        builder: (context, _notifications, _) {
          if (_notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet!",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final noti = _notifications[index];
              final time = DateFormat('dd/MM/yyyy HH:mm')
                  .format(DateTime.parse(noti['time']));
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active,
                      color: Colors.blueAccent),
                  title: Text(noti['title'],
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(
                    "${noti['body']}\n$time",
                    style: GoogleFonts.poppins(
                        color: Colors.grey[600], fontSize: 13),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
