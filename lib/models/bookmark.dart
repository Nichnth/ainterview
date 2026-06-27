class Bookmark {
  const Bookmark({
    required this.id,
    required this.sessionId,
    required this.label,
    required this.summary,
    required this.level,
    required this.stage,
    required this.language,
    required this.sessionDate,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String label;
  final String summary;
  final String level;
  final String stage;
  final String language;
  final DateTime sessionDate;
  final DateTime createdAt;

  Bookmark copyWith({
    String? id,
    String? sessionId,
    String? label,
    String? summary,
    String? level,
    String? stage,
    String? language,
    DateTime? sessionDate,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      label: label ?? this.label,
      summary: summary ?? this.summary,
      level: level ?? this.level,
      stage: stage ?? this.stage,
      language: language ?? this.language,
      sessionDate: sessionDate ?? this.sessionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'label': label,
      'summary': summary,
      'level': level,
      'stage': stage,
      'language': language,
      'sessionDate': sessionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(String id, Map<String, dynamic> map) {
    return Bookmark(
      id: id,
      sessionId: map['sessionId'] as String? ?? '',
      label: map['label'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      level: map['level'] as String? ?? '',
      stage: map['stage'] as String? ?? '',
      language: map['language'] as String? ?? '',
      sessionDate: _readDate(map['sessionDate']),
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
