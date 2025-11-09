import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import '../widgets/create_task_sheet.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> tasks;
  final Function(Map<String, dynamic>) onAddTask;
  final Function(Map<String, dynamic>) onUpdateTask;
  final Function(Map<String, dynamic>) onDeleteTask;

  const HomePage({
    super.key,
    required this.groups,
    required this.tasks,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedDateIndex = 0;
  late Timer _timer;
  List<Map<String, dynamic>> _notifications = [];
  String username = "User";

  @override
  void initState() {
    super.initState();
    _initData().then((_) {
      debugPrint('🎯 Tất cả data đã load xong, bắt đầu timer');
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            _checkAllTasksForNotifications();
          });
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAllTasksForNotifications();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadUsername();
    await _loadTasksFromPrefs();
    await _loadNotifications();
  }

  Future<void> _saveTasksToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      widget.tasks.map((t) {
        final temp = Map<String, dynamic>.from(t);
        if (temp["dueDate"] is DateTime) {
          temp["dueDate"] = (temp["dueDate"] as DateTime).toIso8601String();
        }

        if (temp["color"] is Color) {
          temp["color"] = (temp["color"] as Color).value;
        }
        return temp;
      }).toList(),
    );
    await prefs.setString("tasks_data", encoded);
    debugPrint('💾 Đã lưu ${widget.tasks.length} tasks');
  }

  Future<void> _loadTasksFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("tasks_data");
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          widget.tasks.clear();
          widget.tasks.addAll(
            decoded.map<Map<String, dynamic>>((t) {
              final map = Map<String, dynamic>.from(t);

              if (map["dueDate"] is String) {
                map["dueDate"] = DateTime.parse(map["dueDate"]);
              }

              if (map["color"] is int) {
                map["color"] = Color(map["color"]);
              }
              return map;
            }).toList(),
          );
        });
        debugPrint('📥 Đã load ${widget.tasks.length} tasks');
      } catch (e) {
        debugPrint('❌ Lỗi load tasks: $e');
      }
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final authService = AuthService();
    final user = await authService.getCurrentUser();
    if (user == null) {
      debugPrint('❌ Không tìm thấy user để lưu notifications');
      return;
    }
    final userId = user['id'];
    debugPrint(
      '💾 Bắt đầu lưu ${_notifications.length} notifications cho user $userId',
    );
    final encoded = jsonEncode(
      _notifications.map((n) {
        final temp = Map<String, dynamic>.from(n);

        temp["time"] = (n["time"] as DateTime).toIso8601String();
        temp["dueDate"] = (n["dueDate"] as DateTime).toIso8601String();
        return temp;
      }).toList(),
    );
    await prefs.setString("notifications_data_$userId", encoded);
    debugPrint('💾 ĐÃ LƯU THÀNH CÔNG ${_notifications.length} notifications');
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final authService = AuthService();
    final user = await authService.getCurrentUser();
    if (user == null) {
      debugPrint('❌ Không tìm thấy user để load notifications');
      return;
    }
    final userId = user['id'];
    final jsonStr = prefs.getString("notifications_data_$userId");
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          _notifications = decoded.map<Map<String, dynamic>>((n) {
            final map = Map<String, dynamic>.from(n);
            map["time"] = DateTime.parse(map["time"]);
            map["dueDate"] = DateTime.parse(map["dueDate"]);
            return map;
          }).toList();
        });
        debugPrint(
          '📥 Đã load ${_notifications.length} notifications cho user $userId',
        );
      } catch (e) {
        debugPrint('❌ Lỗi load notifications: $e');
      }
    } else {
      debugPrint('📥 Chưa có notifications nào được lưu cho user $userId');
    }
  }

  Future<void> _loadUsername() async {
    try {
      final authService = AuthService();
      final currentUsername = await authService.getCurrentUsername();
      setState(() {
        username = currentUsername;
      });
    } catch (e) {
      setState(() {
        username = 'User';
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _isSameDay(date, tomorrow);
  }

  bool _isWithinNext7Days(DateTime date) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfDate = DateTime(date.year, date.month, date.day);
    final diff = startOfDate.difference(startOfToday).inDays;
    return diff >= 0 && diff <= 7;
  }

  bool _isMissedTask(DateTime dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.isBefore(now) && !_isSameDay(dueDate, now);
  }

  bool _isOverdue(DateTime dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final isPast = dueDate.isBefore(now);
    final isToday = _isSameDay(dueDate, now);
    return isPast && isToday;
  }

  void _checkAllTasksForNotifications() {
    final now = DateTime.now();
    final todoTasks = widget.tasks
        .where((t) => t["done"] == false && t["dueDate"] != null)
        .toList();
    debugPrint('🔍 Đang kiểm tra ${todoTasks.length} task cho thông báo...');
    for (final task in todoTasks) {
      final dueDate = task["dueDate"];
      final bool missed = _isMissedTask(dueDate);
      final bool overdue = _isOverdue(dueDate);
      final alreadyNotified = _notifications.any(
        (n) => n["taskTitle"] == task["title"],
      );
      debugPrint('📝 Task: "${task["title"]}"');
      debugPrint(' Due: $dueDate');
      debugPrint(' Now: $now');
      debugPrint(' Missed: $missed, Overdue: $overdue');
      debugPrint(' Already notified: $alreadyNotified');
      if ((missed || overdue) && !alreadyNotified) {
        debugPrint('🎯 TẠO THÔNG BÁO: ${task["title"]}');
        _addNotification(task["title"], missed ? "missed" : "overdue", dueDate);
        _showInstantNotification(task["title"], missed ? "missed" : "overdue");
      } else {
        debugPrint(
          '❌ KHÔNG tạo thông báo vì: ${alreadyNotified ? "đã thông báo" : "không missed/overdue"}',
        );
      }
    }
  }

  void _addNotification(String taskTitle, String type, DateTime dueDate) async {
    final notification = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "taskTitle": taskTitle,
      "type": type,
      "dueDate": dueDate,
      "time": DateTime.now(),
      "read": false,
    };
    debugPrint('💾 Thêm notification: $taskTitle - $type');
    setState(() {
      _notifications.insert(0, notification);
    });
    await _saveNotifications();
    debugPrint('📋 SAU KHI LƯU: ${_notifications.length} notifications');
  }

  void _showInstantNotification(String taskTitle, String type) {
    final message = type == "missed"
        ? "You missed the task: $taskTitle"
        : "Task is overdue: $taskTitle";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == "missed"
            ? Colors.redAccent
            : Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: _showNotificationsPanel,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterTasksByDate(
    List<Map<String, dynamic>> all,
  ) {
    final now = DateTime.now();
    if (selectedDateIndex == 0) {
      return all.where((t) => _isSameDay(t["dueDate"], now)).toList();
    } else if (selectedDateIndex == 1) {
      return all.where((t) => _isTomorrow(t["dueDate"])).toList();
    } else if (selectedDateIndex == 2) {
      return all.where((t) => _isWithinNext7Days(t["dueDate"])).toList();
    } else if (selectedDateIndex == 3) {
      return all.toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filterTasksByDate(widget.tasks);
    final todoTasks = filteredTasks.where((t) => t["done"] == false).toList();
    final completedTasks = filteredTasks
        .where((t) => t["done"] == true)
        .toList();
    final unreadCount = _notifications.where((n) => n["read"] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('assets/avt.jpg'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hey,",
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            Text(
                              "$username!",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: _showNotificationsPanel,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 9
                                        ? '9+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _openCreateTask,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "New Task",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _dateButton("Today", 0, isToday: true),
                    _dateButton("Tomorrow", 1),
                    _dateButton("Next 7 Days", 2),
                    _dateButton("All", 3),
                  ],
                ),
                const SizedBox(height: 25),
                Text(
                  "To Do (${todoTasks.length})",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (todoTasks.isEmpty) _emptyMessage("No tasks left"),
                ...todoTasks.map((task) => _taskCard(task)),
                const SizedBox(height: 25),
                Text(
                  "Completed (${completedTasks.length})",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (completedTasks.isEmpty)
                  _emptyMessage("No completed tasks yet 😅"),
                ...completedTasks.map((task) => _taskCard(task)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsPanel() {
    debugPrint(
      '👁️ Mở notifications panel - Số lượng: ${_notifications.length}',
    );
    for (var noti in _notifications) {
      debugPrint(
        ' 📌 ${noti["taskTitle"]} - ${noti["type"]} - read: ${noti["read"]}',
      );
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        "Mark all as read",
                        style: GoogleFonts.poppins(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No notifications",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        debugPrint(
                          '📌 Hiển thị notification: ${_notifications[index]["taskTitle"]}',
                        );
                        return _notificationItem(_notifications[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem(Map<String, dynamic> notification) {
    final isMissed = notification["type"] == "missed";
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isMissed ? Colors.redAccent : Colors.orangeAccent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isMissed ? Icons.error_outline : Icons.warning_amber,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        notification["taskTitle"],
        style: GoogleFonts.poppins(
          fontWeight: notification["read"]
              ? FontWeight.normal
              : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        isMissed ? "Task was missed" : "Task is overdue",
        style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Text(
        _formatNotificationTime(notification["time"]),
        style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
      ),
      onTap: () => _markAsRead(notification["id"]),
    );
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n["id"] == id);
      if (index != -1) _notifications[index]["read"] = true;
    });
    _saveNotifications();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n["id"] == id);
        });
        _saveNotifications();
      }
    });
  }

  void _markAllAsRead() {
    final readNotificationIds = _notifications
        .where((n) => !n["read"])
        .map((n) => n["id"])
        .toList();
    setState(() {
      for (var n in _notifications) {
        n["read"] = true;
      }
    });
    _saveNotifications();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _notifications.removeWhere(
            (n) => readNotificationIds.contains(n["id"]),
          );
        });
        _saveNotifications();
      }
    });
  }

  String _formatNotificationTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  Widget _dateButton(String text, int index, {bool isToday = false}) {
    final selected = selectedDateIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedDateIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueAccent
              : (isToday ? Colors.white : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: selected
                ? Colors.white
                : (isToday ? Colors.black : Colors.grey.shade600),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openCreateTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTaskSheet(
        groups: widget.groups,
        onCreateTask: (newTask) {
          widget.onAddTask(newTask);
          _saveTasksToPrefs();
          setState(() {});
        },
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    bool done = task["done"] ?? false;
    DateTime dueDate = task["dueDate"];
    bool missed = !done && _isMissedTask(dueDate);
    bool overdue = !done && dueDate.isBefore(DateTime.now()) && !missed;
    return GestureDetector(
      onTap: () => _showTaskOptions(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: done
              ? Colors.grey.shade400
              : (missed || overdue)
              ? Colors.redAccent.withOpacity(0.9)
              : (task["color"] is int)
              ? Color(task["color"])
              : task["color"],
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task["title"],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (missed) _statusTag("MISSED", Colors.red),
                        if (overdue) _statusTag("OVERDUE", Colors.orange),
                        if (missed || overdue) const SizedBox(width: 6),
                        Text(
                          _formatDeadline(
                            task["dueDate"],
                            missed: missed,
                            overdue: overdue,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(done ? 0.4 : 0.9),
                            fontWeight: (overdue || missed)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    task["done"] = !done;
                  });
                  widget.onUpdateTask(task);
                  _saveTasksToPrefs();
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: done ? Colors.white : Colors.transparent,
                  ),
                  child: done
                      ? const Icon(Icons.check, color: Colors.black, size: 16)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  String _formatDeadline(
    DateTime date, {
    bool missed = false,
    bool overdue = false,
  }) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return "Today • ${_formatTime(date)}";
    } else if (_isTomorrow(date)) {
      return "Tomorrow • ${_formatTime(date)}";
    } else {
      return "${date.day}/${date.month} • ${_formatTime(date)}";
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  Widget _emptyMessage(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.grey[600])),
    ),
  );

  void _showTaskOptions(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task["title"],
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("Delete Task"),
              onTap: () {
                widget.onDeleteTask(task);
                _saveTasksToPrefs();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
