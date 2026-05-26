import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_review.dart';

abstract class AiInterviewService {
  Future<String> startInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
  });

  Future<String> sendMessage({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
  });

  Future<InterviewReview> reviewInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
  });
}

class MockAiInterviewService implements AiInterviewService {
  @override
  Future<String> startInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
  }) async {
    if (language == InterviewLanguage.indonesian) {
      return 'Kita mulai sesi ${level.label} ${stage.label}. ${_firstQuestion(level, stage, language)}';
    }

    return 'Welcome to the ${level.label} ${stage.label} interview. ${_firstQuestion(level, stage, language)}';
  }

  @override
  Future<String> sendMessage({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
  }) async {
    final lastAnswer = messages.last.text;
    if (language == InterviewLanguage.indonesian) {
      return 'Terima kasih. Untuk konteks ${level.label} ${stage.label}, jelaskan lebih spesifik: ${_followUp(level, stage, lastAnswer, language)}';
    }

    return 'Thanks. For a ${level.label} ${stage.label} interview, go one level deeper: ${_followUp(level, stage, lastAnswer, language)}';
  }

  @override
  Future<InterviewReview> reviewInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
  }) async {
    final answeredCount = messages
        .where((message) => message.sender == InterviewMessageSender.user)
        .length;

    if (language == InterviewLanguage.indonesian) {
      return InterviewReview(
        summary:
            'Sesi ${level.label} ${stage.label} selesai dengan $answeredCount jawaban. Kamu sudah memberi konteks awal yang bisa dikembangkan.',
        communicationFeedback:
            'Jawaban sudah cukup jelas. Tambahkan struktur situasi, aksi, dan hasil agar lebih meyakinkan.',
        technicalFeedback: _technicalReview(level, stage, language),
        improvementAreas: const [
          'Perjelas contoh project yang paling relevan.',
          'Tambahkan alasan teknis di balik keputusan yang kamu ambil.',
        ],
        recommendations: const [
          'Latihan 1 sesi HR mock interview.',
          'Review ulang catatan technical focus sesuai level.',
        ],
      );
    }

    return InterviewReview(
      summary:
          '${level.label} ${stage.label} session completed with $answeredCount answer(s). You gave a useful baseline and can now sharpen the evidence.',
      communicationFeedback:
          'Your answer is understandable. Use a clearer situation-action-result structure for stronger interview signal.',
      technicalFeedback: _technicalReview(level, stage, language),
      improvementAreas: const [
        'Anchor answers in one concrete project example.',
        'Explain trade-offs and measurable impact more explicitly.',
      ],
      recommendations: const [
        'Run one focused mock interview session.',
        'Review the next technical practice topic in your plan.',
      ],
    );
  }

  String _firstQuestion(
    InterviewLevel level,
    InterviewStage stage,
    InterviewLanguage language,
  ) {
    if (language == InterviewLanguage.indonesian) {
      return switch (stage) {
        InterviewStage.hr =>
          'Ceritakan tentang dirimu dan pengalaman yang paling relevan untuk posisi mobile programmer.',
        InterviewStage.technical => switch (level) {
          InterviewLevel.intern =>
            'Jelaskan konsep OOP yang paling sering kamu pakai saat membuat aplikasi mobile.',
          InterviewLevel.junior =>
            'Bagaimana kamu mengelola state dan error saat memanggil API di Flutter?',
          InterviewLevel.senior =>
            'Bagaimana kamu merancang architecture aplikasi mobile yang scalable dan mudah dites?',
        },
      };
    }

    return switch (stage) {
      InterviewStage.hr =>
        'Tell me about yourself and the most relevant experience you bring to a mobile programmer role.',
      InterviewStage.technical => switch (level) {
        InterviewLevel.intern =>
          'Explain an OOP concept you often use when building mobile apps.',
        InterviewLevel.junior =>
          'How do you manage state and API errors in a Flutter app?',
        InterviewLevel.senior =>
          'How would you design a scalable and testable mobile app architecture?',
      },
    };
  }

  String _followUp(
    InterviewLevel level,
    InterviewStage stage,
    String lastAnswer,
    InterviewLanguage language,
  ) {
    final trimmedAnswer = lastAnswer.trim();
    final answerHint = trimmedAnswer.isEmpty
        ? ''
        : ' Ambil contoh dari jawabanmu: "$trimmedAnswer".';

    if (language == InterviewLanguage.indonesian) {
      return switch (stage) {
        InterviewStage.hr =>
          'apa tantangan terbesarnya, tindakanmu, dan hasilnya?$answerHint',
        InterviewStage.technical => switch (level) {
          InterviewLevel.intern =>
            'bagaimana kamu memastikan konsep dasarnya benar dan mudah dipahami?$answerHint',
          InterviewLevel.junior =>
            'bagaimana kamu menangani failure case, loading state, dan retry?$answerHint',
          InterviewLevel.senior =>
            'apa trade-off architecture, testing strategy, dan risiko security-nya?$answerHint',
        },
      };
    }

    return switch (stage) {
      InterviewStage.hr =>
        'what was the hardest part, what did you do, and what changed as a result?',
      InterviewStage.technical => switch (level) {
        InterviewLevel.intern =>
          'how would you prove the fundamental concept is correct and easy to explain?',
        InterviewLevel.junior =>
          'how would you handle failure cases, loading state, and retry behavior?',
        InterviewLevel.senior =>
          'what are the architecture trade-offs, testing strategy, and security risks?',
      },
    };
  }

  String _technicalReview(
    InterviewLevel level,
    InterviewStage stage,
    InterviewLanguage language,
  ) {
    if (stage == InterviewStage.hr) {
      return language == InterviewLanguage.indonesian
          ? 'Belum banyak sinyal teknis karena sesi ini berfokus pada HR.'
          : 'Technical signal is limited because this was an HR-focused session.';
    }

    return switch (level) {
      InterviewLevel.intern =>
        language == InterviewLanguage.indonesian
            ? 'Perkuat penjelasan fundamental programming dan OOP.'
            : 'Strengthen programming fundamentals and OOP explanations.',
      InterviewLevel.junior =>
        language == InterviewLanguage.indonesian
            ? 'Perkuat detail state management, API failure handling, dan debugging.'
            : 'Strengthen state management, API failure handling, and debugging details.',
      InterviewLevel.senior =>
        language == InterviewLanguage.indonesian
            ? 'Perkuat architecture reasoning, testing strategy, security, dan performance trade-off.'
            : 'Your architecture reasoning is a good start; add testing strategy, security, and performance trade-offs.',
    };
  }
}
