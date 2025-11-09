import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/group_card.dart';
import '../widgets/create_group_sheet.dart';

class GroupsPage extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final Function(Map<String, dynamic>) onAddGroup;
  final Function(Map<String, dynamic>) onDeleteGroup;

  const GroupsPage({
    super.key,
    required this.groups,
    required this.onAddGroup,
    required this.onDeleteGroup,
  });

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  void _openCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGroupSheet(
        onCreateGroup: (newGroup) {
          widget.onAddGroup(newGroup);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${group['title']}?'),
        content: Text('All tasks in this group will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteGroup(group);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Success ${group['title']}')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getSafeIcon(dynamic icon) {
    try {
      if (icon is IconData) {
        return icon;
      } else if (icon is int) {
        return IconData(icon, fontFamily: 'MaterialIcons');
      }
      return Icons.folder;
    } catch (e) {
      return Icons.folder;
    }
  }

  Color _getSafeColor(dynamic color) {
    try {
      if (color is Color) {
        return color;
      } else if (color is int) {
        return Color(color);
      }
      return const Color(0xFFF5C04E);
    } catch (e) {
      return const Color(0xFFF5C04E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "List",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openCreateGroupSheet,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      "New List",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Expanded(
                child: widget.groups.isEmpty
                    ? const Center(
                        child: Text(
                          "No groups yet",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.groups.length,
                        itemBuilder: (context, index) {
                          final g = widget.groups[index];
                          final safeTitle =
                              g['title']?.toString() ?? 'No Title';
                          final safeSubtitle =
                              g['subtitle']?.toString() ?? 'To Do';
                          final safeTasks = g['tasks']?.toString() ?? '0 tasks';
                          final safeColor = _getSafeColor(g['color']);
                          final safeIcon = _getSafeIcon(g['icon']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: GroupCard(
                              title: safeTitle,
                              subtitle: safeSubtitle,
                              tasks: safeTasks,
                              color: safeColor,
                              icon: safeIcon,
                              onDelete: () => _showDeleteConfirmation(g),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
