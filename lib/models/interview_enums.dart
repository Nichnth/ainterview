enum InterviewLevel {
  intern('intern', 'Intern'),
  junior('junior', 'Junior Dev'),
  senior('senior', 'Senior Dev');

  const InterviewLevel(this.key, this.label);

  final String key;
  final String label;

  static InterviewLevel fromLabel(String value) {
    final normalizedValue = _normalizeEnumValue(value);
    return InterviewLevel.values.firstWhere(
      (level) =>
          _normalizeEnumValue(level.label) == normalizedValue ||
          _normalizeEnumValue(level.key) == normalizedValue ||
          _normalizeEnumValue(level.name) == normalizedValue,
      orElse: () => InterviewLevel.intern,
    );
  }
}

enum InterviewLanguage {
  indonesian('indonesian', 'Indonesian'),
  english('english', 'English');

  const InterviewLanguage(this.key, this.label);

  final String key;
  final String label;

  static InterviewLanguage fromLabel(String value) {
    final normalizedValue = _normalizeEnumValue(value);
    return InterviewLanguage.values.firstWhere(
      (language) =>
          _normalizeEnumValue(language.label) == normalizedValue ||
          _normalizeEnumValue(language.key) == normalizedValue ||
          _normalizeEnumValue(language.name) == normalizedValue,
      orElse: () => InterviewLanguage.indonesian,
    );
  }
}

enum InterviewStage {
  hr('hr', 'HR'),
  technical('technical', 'Technical');

  const InterviewStage(this.key, this.label);

  final String key;
  final String label;

  static InterviewStage fromLabel(String value) {
    return tryFromLabel(value) ?? InterviewStage.hr;
  }

  static InterviewStage? tryFromLabel(String value) {
    final normalizedValue = _normalizeEnumValue(value);
    for (final stage in InterviewStage.values) {
      if (_normalizeEnumValue(stage.label) == normalizedValue ||
          _normalizeEnumValue(stage.key) == normalizedValue ||
          _normalizeEnumValue(stage.name) == normalizedValue) {
        return stage;
      }
    }

    return null;
  }
}

String _normalizeEnumValue(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
