import '../models/interview_enums.dart';
import '../models/schedule_item.dart';

class InterviewPlanGenerator {
  const InterviewPlanGenerator._();

  static List<ScheduleItem> generate({
    required DateTime today,
    required DateTime targetDate,
    required InterviewLevel level,
    required InterviewLanguage language,
  }) {
    final templates = _templatesFor(level, language);
    final availableDays = _availableDays(today, targetDate);

    return [
      for (var index = 0; index < templates.length; index++)
        ScheduleItem(
          id: ScheduleItem.stableId(templates[index].title),
          dayOffset: _dayOffset(index, templates.length, availableDays),
          title: templates[index].title,
          description: templates[index].description,
          suggestedStage: templates[index].suggestedStage,
        ),
    ];
  }

  static int _availableDays(DateTime today, DateTime targetDate) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedTarget = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final difference = normalizedTarget.difference(normalizedToday).inDays;
    return difference < 1 ? 1 : difference;
  }

  static int _dayOffset(int index, int itemCount, int availableDays) {
    if (itemCount <= 1) {
      return 1;
    }

    final spread = index * (availableDays - 1) / (itemCount - 1);
    return 1 + spread.round();
  }

  static List<_TaskTemplate> _templatesFor(
    InterviewLevel level,
    InterviewLanguage language,
  ) {
    return switch (language) {
      InterviewLanguage.indonesian => _indonesianTemplates(level),
      InterviewLanguage.english => _englishTemplates(level),
    };
  }

  static List<_TaskTemplate> _indonesianTemplates(InterviewLevel level) {
    final technicalTopics = switch (level) {
      InterviewLevel.intern => const [
        _TaskTemplate(
          'Technical Focus: Programming Fundamentals',
          'Latihan konsep variabel, control flow, function, dan error sederhana.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: OOP dan Data Structure Dasar',
          'Latihan menjelaskan class, object, list, map, stack, dan queue.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Mobile Basics: Flutter/Dart Lifecycle',
          'Latihan menjawab pertanyaan widget lifecycle dan dasar platform mobile.',
          InterviewStage.technical,
        ),
      ],
      InterviewLevel.junior => const [
        _TaskTemplate(
          'Technical Focus: State Management',
          'Latihan scenario Provider, BLoC, state mutation, dan pemisahan UI dengan logic.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: API dan Database',
          'Latihan networking, parsing response, error handling, cache, dan local database.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: Git dan Debugging',
          'Latihan workflow branch, pull request, conflict, logging, dan root cause analysis.',
          InterviewStage.technical,
        ),
      ],
      InterviewLevel.senior => const [
        _TaskTemplate(
          'Technical Focus: Architecture',
          'Latihan Clean Architecture, MVVM, dependency boundaries, dan trade-off design.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: System Design Mobile',
          'Latihan desain offline-first, sync, pagination, observability, dan scalability.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: Testing, Security, Optimization',
          'Latihan strategi testing, secure storage, performance profiling, dan code review.',
          InterviewStage.technical,
        ),
      ],
    };

    return [
      const _TaskTemplate(
        'HR Mock Interview: Introduction',
        'Latihan perkenalan, motivasi melamar, kekuatan, dan cara menyampaikan pengalaman.',
        InterviewStage.hr,
      ),
      const _TaskTemplate(
        'HR Practice: Behavioral Scenarios',
        'Latihan menjawab konflik tim, feedback, deadline, dan problem solving dengan metode STAR.',
        InterviewStage.hr,
      ),
      ...technicalTopics,
      const _TaskTemplate(
        'Full Mock Interview',
        'Latihan simulasi HR dan Technical secara berurutan, lalu catat area improvement.',
      ),
    ];
  }

  static List<_TaskTemplate> _englishTemplates(InterviewLevel level) {
    final technicalTopics = switch (level) {
      InterviewLevel.intern => const [
        _TaskTemplate(
          'Technical Focus: Programming Fundamentals',
          'Practice variables, control flow, functions, and simple error handling.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: OOP and Basic Data Structures',
          'Practice class, object, list, map, stack, and queue explanations.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Mobile Basics: Flutter/Dart Lifecycle',
          'Practice widget lifecycle and mobile platform fundamentals.',
          InterviewStage.technical,
        ),
      ],
      InterviewLevel.junior => const [
        _TaskTemplate(
          'Technical Focus: State Management',
          'Practice Provider, BLoC, state mutation, and UI-logic separation scenarios.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: API and Database',
          'Practice networking, response parsing, error handling, caching, and local database flows.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: Git and Debugging',
          'Practice branching, pull requests, conflicts, logging, and root cause analysis.',
          InterviewStage.technical,
        ),
      ],
      InterviewLevel.senior => const [
        _TaskTemplate(
          'Technical Focus: Architecture',
          'Practice Clean Architecture, MVVM, dependency boundaries, and design trade-offs.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: System Design Mobile',
          'Practice offline-first design, sync, pagination, observability, and scalability.',
          InterviewStage.technical,
        ),
        _TaskTemplate(
          'Technical Focus: Testing, Security, Optimization',
          'Practice testing strategy, secure storage, performance profiling, and code review.',
          InterviewStage.technical,
        ),
      ],
    };

    return [
      const _TaskTemplate(
        'HR Mock Interview: Introduction',
        'Practice your introduction, motivation, strengths, and project storytelling.',
        InterviewStage.hr,
      ),
      const _TaskTemplate(
        'HR Practice: Behavioral Scenarios',
        'Practice team conflict, feedback, deadlines, and STAR-based problem solving.',
        InterviewStage.hr,
      ),
      ...technicalTopics,
      const _TaskTemplate(
        'Full Mock Interview',
        'Run HR and Technical simulation back-to-back, then capture improvement areas.',
      ),
    ];
  }
}

class _TaskTemplate {
  const _TaskTemplate(this.title, this.description, [this.suggestedStage]);

  final String title;
  final String description;
  final InterviewStage? suggestedStage;
}
