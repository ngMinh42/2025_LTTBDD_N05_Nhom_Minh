import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationService {
  static ValueNotifier<List<Map<String, dynamic>>> notifier = ValueNotifier([]);

  static Future<void> initialize() async {
    final notis = await getNotifications();
    notifier.value = notis;
  }

  static Future<void> showAppNotification({
    required String title,
    required String body,
  }) async {
    await _saveNotificationToLocal(title, body);
    final notis = await getNotifications();
    notifier.value = notis;
  }

  static Future<void> _saveNotificationToLocal(
    String title,
    String body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('notifications') ?? [];
    final list = rawList.map((e) => jsonDecode(e)).toList();

    list.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
    });

    await prefs.setStringList(
      'notifications',
      list.map((e) => jsonEncode(e)).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('notifications') ?? [];
    return rawList
        .map((e) => jsonDecode(e))
        .toList()
        .cast<Map<String, dynamic>>();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    notifier.value = [];
  }
}
