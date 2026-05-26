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
}
