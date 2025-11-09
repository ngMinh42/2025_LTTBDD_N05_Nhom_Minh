import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/diary_entry.dart';

class DiaryService {
  static const String _key = 'diary_entries';

  static Future<void> saveEntries(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<List<DiaryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    final entries = jsonList.map((json) => DiaryEntry.fromJson(json)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }
}
