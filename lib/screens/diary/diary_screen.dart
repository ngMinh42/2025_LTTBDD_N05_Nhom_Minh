import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/diary_entry.dart';
import 'write_diary_screen.dart';
import '../../services/diary_service.dart';
import '../../services/notification_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadEntriesOnce();
  }

  Future<void> _loadEntriesOnce() async {
    if (!_isLoading) return;
    setState(() => _isLoading = true);

    final entries = await DiaryService.loadEntries();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _openWriteDiary() async {
    final newEntry = await Navigator.push<DiaryEntry>(
      context,
      MaterialPageRoute(builder: (_) => const WriteDiaryScreen()),
    );

    if (newEntry != null && mounted) {
      final exists = _entries.any(
        (e) =>
            e.content == newEntry.content &&
            e.emoji == newEntry.emoji &&
            e.createdAt.difference(newEntry.createdAt).inSeconds.abs() < 2,
      );

      if (!exists) {
        setState(() {
          _entries.insert(0, newEntry);
        });
        await DiaryService.saveEntries(_entries);

        NotificationService.showAppNotification(
          title: "Diary Entry Added",
          body:
              "${newEntry.emoji} \"${newEntry.content.substring(0, newEntry.content.length.clamp(0, 40))}${newEntry.content.length > 40 ? '...' : ''}\"",
        );
      }
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final index = _entries.indexOf(entry);
    if (index == -1) return;

    final deletedEntry = _entries.removeAt(index);
    setState(() {});
    await DiaryService.saveEntries(_entries);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _entries.insert(index, deletedEntry);
              });
              DiaryService.saveEntries(_entries);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Diary',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? _buildEmptyState()
          : _buildDiaryList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _openWriteDiary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No entries yet',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to start writing',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final uniqueKey =
            '${entry.content.hashCode}_${entry.createdAt.millisecondsSinceEpoch}';

        return Dismissible(
          key: Key(uniqueKey),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Delete Entry?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'This action cannot be undone.',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await _deleteEntry(entry);
            }
            return confirm;
          },
          child: _DiaryEntryCard(entry: entry),
        );
      },
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  const _DiaryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(entry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(entry.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            entry.content,
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
