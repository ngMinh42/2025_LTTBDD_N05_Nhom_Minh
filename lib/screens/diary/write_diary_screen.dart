import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/diary_entry.dart';

class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedEmoji = 'smiling face';

  final List<String> _emojis = [
    '😄',
    '😆',
    '😊',
    '😌',
    '🙏',
    '😍',
    '😎',
    '🧘',
    '🙂',
    '🤔',
    '😴',
    '😐',
    '🫶',
    '🏃‍♂️',
    '😢',
    '😔',
    '😣',
    '😠',
    '😰',
    '😞',
    '💔',
    '🤩',
    '🎨',
    '⚡',
    '😲',
    '💪',
    '🕰️',
    '💖',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your day?',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _emojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Write your thoughts here...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final entry = DiaryEntry(
      content: content,
      emoji: _selectedEmoji,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, entry);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
