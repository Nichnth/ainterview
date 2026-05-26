enum InterviewLevel {
  intern('Intern'),
  junior('Junior Dev'),
  senior('Senior Dev');

  const InterviewLevel(this.label);

  final String label;

  static InterviewLevel fromLabel(String value) {
    return InterviewLevel.values.firstWhere(
      (level) => level.label == value,
      orElse: () => InterviewLevel.intern,
    );
  }
}

enum InterviewLanguage {
  indonesian('Indonesian'),
  english('English');

  const InterviewLanguage(this.label);

  final String label;

  static InterviewLanguage fromLabel(String value) {
    return InterviewLanguage.values.firstWhere(
      (language) => language.label == value,
      orElse: () => InterviewLanguage.indonesian,
    );
  }
}

enum InterviewStage {
  hr('HR'),
  technical('Technical');

  const InterviewStage(this.label);

  final String label;

  static InterviewStage fromLabel(String value) {
    return InterviewStage.values.firstWhere(
      (stage) => stage.label == value,
      orElse: () => InterviewStage.hr,
    );
  }
}
