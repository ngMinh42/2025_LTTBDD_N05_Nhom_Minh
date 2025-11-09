import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_page.dart';
import 'groups_page.dart';
import 'settings_page.dart';
import 'notifications_page.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_page.dart';
import 'diary/diary_screen.dart';
import '../widgets/create_task_sheet.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final tasksString = prefs.getString('tasks_data');
    if (tasksString != null) {
      try {
        final List<dynamic> data = json.decode(tasksString);
        setState(() {
          tasks = data.map((e) {
            final task = Map<String, dynamic>.from(e);
            if (task['dueDate'] is String) {
              task['dueDate'] = DateTime.tryParse(task['dueDate']);
            }
            if (task['color'] is int) {
              task['color'] = Color(task['color']);
            }
            return task;
          }).toList();
        });
      } catch (e) {
        debugPrint('Error loading tasks: $e');
      }
    }

    final groupsString = prefs.getString('groups');
    if (groupsString != null) {
      try {
        final List<dynamic> data = json.decode(groupsString);
        setState(() {
          groups = data.map((e) {
            final g = Map<String, dynamic>.from(e);
            if (g['color'] is int) g['color'] = Color(g['color']);
            if (g['icon'] is int) {
              g['icon'] = IconData(g['icon'], fontFamily: 'MaterialIcons');
            } else if (g['icon'] == null) {
              g['icon'] = Icons.folder;
            }
            return g;
          }).toList();
        });
        debugPrint('Loaded ${groups.length} groups from SharedPreferences');
      } catch (e) {
        debugPrint('Error loading groups: $e');
        _setDefaultGroups();
      }
    } else {
      _setDefaultGroups();
    }
  }

  void _setDefaultGroups() {
    groups = [
      {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': 'Work',
        'subtitle': 'To Do',
        'tasks': '0 tasks',
        'color': const Color(0xFFF5C04E),
        'icon': Icons.work,
      },
      {
        'id': DateTime.now().millisecondsSinceEpoch + 1,
        'title': 'Family',
        'subtitle': 'In Progress',
        'tasks': '0 tasks',
        'color': const Color(0xFF4CAF88),
        'icon': Icons.family_restroom,
      },
    ];
    _saveGroups();
    debugPrint('Created default groups');
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = tasks.map((t) {
      final m = Map<String, dynamic>.from(t);
      if (m['dueDate'] is DateTime) {
        m['dueDate'] = (m['dueDate'] as DateTime).toIso8601String();
      }
      if (m['color'] is Color) {
        m['color'] = (m['color'] as Color).value;
      }
      return m;
    }).toList();
    await prefs.setString('tasks_data', json.encode(encoded));
    debugPrint('Saved ${tasks.length} tasks');

    _updateGroupTaskCount();
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = groups.map((g) {
      final m = Map<String, dynamic>.from(g);
      if (m['color'] is Color) {
        m['color'] = (m['color'] as Color).value;
      }
      if (m['icon'] is IconData) {
        m['icon'] = (m['icon'] as IconData).codePoint;
      }
      return m;
    }).toList();
    await prefs.setString('groups', json.encode(encoded));
    debugPrint('Saved ${groups.length} groups');
  }

  void _updateGroupTaskCount() {
    for (var group in groups) {
      final groupTitle = group['title'];
      final groupTasks = tasks.where((task) {
        final taskGroup = task['group'] ?? task['groupId'] ?? '';
        return taskGroup == groupTitle;
      }).toList();

      final total = groupTasks.length;
      final completed = groupTasks.where((task) => task['done'] == true).length;

      group['tasks'] = total == 0 ? '0 tasks' : '$completed/$total';
      group['totalTasks'] = total;
      group['completedTasks'] = completed;
    }

    _saveGroups();
    debugPrint('Updated group task counts');
  }

  void addTask(Map<String, dynamic> newTask) {
    setState(() {
      newTask["done"] = false;
      newTask["id"] = DateTime.now().millisecondsSinceEpoch;
      tasks.add(newTask);
    });
    _saveTasks();

    NotificationService.showAppNotification(
      title: "New Task Added",
      body: "You added a new task: ${newTask['title']}",
    );
  }

  void updateTask(Map<String, dynamic> updatedTask) {
    setState(() {});
    _saveTasks();

    if (updatedTask["done"] == true) {
      NotificationService.showAppNotification(
        title: "Task Completed",
        body: "You completed: ${updatedTask['title']}",
      );
    }
  }

  void deleteTask(Map<String, dynamic> task) {
    setState(() {
      tasks.removeWhere((t) => t['id'] == task['id']);
    });
    _saveTasks();
  }

  void addGroup(Map<String, dynamic> newGroup) {
    try {
      final Map<String, dynamic> safeGroup = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': newGroup['title']?.toString() ?? 'New Group',
        'subtitle': newGroup['subtitle']?.toString() ?? 'To Do',
        'tasks': '0 tasks',
        'color': (newGroup['color'] is Color)
            ? newGroup['color']
            : const Color(0xFFF5C04E),
        'icon': newGroup['icon'] ?? Icons.folder,
      };

      setState(() {
        groups.add(safeGroup);
      });

      _saveGroups();
      debugPrint('Added group: ${safeGroup['title']}');
    } catch (e) {
      debugPrint('Error adding group: $e');
    }
  }

  void deleteGroup(Map<String, dynamic> groupToDelete) {
    try {
      final groupId = groupToDelete['id'];
      final groupTitle = groupToDelete['title'];

      setState(() {
        groups.removeWhere((group) => group['id'] == groupId);
        tasks.removeWhere((task) => task['group'] == groupTitle);
      });

      _saveGroups();
      _saveTasks();

      debugPrint('Deleted group: $groupTitle');
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
  }

  Future<void> _handleLogout() async {
    final authService = AuthService();
    await authService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onLoginSuccess: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
              );
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        groups: groups,
        tasks: tasks,
        onAddTask: addTask,
        onUpdateTask: updateTask,
        onDeleteTask: deleteTask,
      ),
      GroupsPage(
        groups: groups,
        onAddGroup: addGroup,
        onDeleteGroup: deleteGroup,
      ),
      const DiaryScreen(),
      const NotificationsPage(),
      SettingsPage(
        onLanguageChange: () => setState(() {}),
        onLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "My List"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Diary"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: "Notifications",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
