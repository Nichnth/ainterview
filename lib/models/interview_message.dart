enum InterviewMessageSender { user, ai }

class InterviewMessage {
  const InterviewMessage({
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final InterviewMessageSender sender;
  final String text;
  final DateTime createdAt;

  Map<String, Object> toMap() {
    return {
      'sender': sender.name,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InterviewMessage.fromMap(Map<String, dynamic> map) {
    return InterviewMessage(
      sender: _senderFromValue(map['sender']),
      text: map['text'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
    );
  }

  static InterviewMessageSender _senderFromValue(Object? value) {
    if (value is InterviewMessageSender) {
      return value;
    }

    if (value is String) {
      for (final sender in InterviewMessageSender.values) {
        if (sender.name == value) {
          return sender;
        }
      }
    }

    throw ArgumentError('Unknown interview message sender: $value');
  }

  static DateTime _readDate(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    throw ArgumentError('Expected DateTime or ISO-8601 string.');
  }
}
