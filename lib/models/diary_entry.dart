class DiaryEntry {
  final String content;
  final String emoji;
  final DateTime createdAt;

  DiaryEntry({
    required this.content,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    content: json['content'] as String,
    emoji: json['emoji'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
