import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_preparation_context.dart';
import '../models/interview_review.dart';
import '../providers/interview_plan_controller.dart';
import '../services/ai_interview_service.dart';
import '../services/auth_service.dart';
import '../services/backend_ai_interview_service.dart';
import '../services/firestore_repositories.dart';
import '../services/firestore_interview_session_repository.dart';
import '../services/interview_plan_repository.dart';
import '../services/interview_session_repository.dart';
import '../services/open_router_ai_interview_service.dart';
import '../widgets/custom_button.dart';
import 'duolingo_interview_screen.dart';
import 'interview_plan_screen.dart';
import 'profile_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({
    super.key,
    required this.userId,
    this.aiService,
    this.planRepository,
    this.sessionRepository,
    this.profilePage,
  });

  final String userId;
  final AiInterviewService? aiService;
  final InterviewPlanRepository? planRepository;
  final InterviewSessionRepository? sessionRepository;
  final Widget? profilePage;

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  static const _aiProxyBaseUrl = String.fromEnvironment('AI_PROXY_BASE_URL');
  static const _openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  late final InterviewPlanController _planController;
  late final InterviewSessionRepository _sessionRepository;
  late final AiInterviewService _aiService;

  @override
  void initState() {
    super.initState();
    _planController = InterviewPlanController(
      repository: widget.planRepository ?? FirestoreInterviewPlanRepository(),
      userId: widget.userId,
    );
    _planController.loadPlans();
    _sessionRepository =
        widget.sessionRepository ?? FirestoreInterviewSessionRepository();
    _aiService = widget.aiService ??
        buildDefaultAiInterviewService(
          proxyBaseUrl: _aiProxyBaseUrl,
          openRouterApiKey: _openRouterApiKey,
          idTokenProvider: () async =>
              AuthService.instance.currentUser?.getIdToken(),
        );
  }

  @override
  void dispose() {
    _planController.dispose();
    super.dispose();
  }

  void _launchInterviewProcess([String? scheduleItemId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => DuolingoInterviewScreen(
          aiService: _aiService,
          planController: _planController,
          sessionRepository: _sessionRepository,
          practiceScheduleItemId: scheduleItemId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InterviewPlanScreen(
        controller: _planController,
        onPracticeItem: _launchInterviewProcess,
      ),
      _InterviewLandingPage(onStart: () => _launchInterviewProcess()),
      widget.profilePage ??
          ProfileScreen(
            userId: widget.userId,
            sessionRepository: _sessionRepository as FirestoreInterviewSessionRepository,
          ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.main.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note, color: AppColors.main),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.main),
            label: 'Interview',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.main),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

AiInterviewService buildDefaultAiInterviewService({
  required String proxyBaseUrl,
  String openRouterApiKey = '',
  required Future<String?> Function() idTokenProvider,
}) {
  final trimmedProxyBaseUrl = proxyBaseUrl.trim();
  if (trimmedProxyBaseUrl.isNotEmpty) {
    final baseUrl = Uri.tryParse(trimmedProxyBaseUrl);
    if (baseUrl != null && baseUrl.hasScheme && baseUrl.host.isNotEmpty) {
      return BackendAiInterviewService(
        baseUrl: baseUrl,
        idTokenProvider: idTokenProvider,
      );
    }
  }

  final trimmedOpenRouterApiKey = openRouterApiKey.trim();
  if (trimmedOpenRouterApiKey.isNotEmpty) {
    return OpenRouterAiInterviewService(apiKey: trimmedOpenRouterApiKey);
  }

  return const MissingAiServiceConfiguration();
}

class MissingAiServiceConfiguration implements AiInterviewService {
  const MissingAiServiceConfiguration();

  static const _message =
      'AI service is not configured. For free demo mode, run Flutter with --dart-define=OPENROUTER_API_KEY=your_openrouter_key. For production, use --dart-define=AI_PROXY_BASE_URL=https://your-backend.example/interview.';

  @override
  Future<String> startInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    InterviewPreparationContext? preparationContext,
  }) async {
    throw StateError(_message);
  }

  @override
  Future<String> sendMessage({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    throw StateError(_message);
  }

  @override
  Future<InterviewReview> reviewInterview({
    required InterviewLevel level,
    required InterviewStage stage,
    required InterviewLanguage language,
    required List<InterviewMessage> messages,
    InterviewPreparationContext? preparationContext,
  }) async {
    throw StateError(_message);
  }
}

class _InterviewLandingPage extends StatelessWidget {
  const _InterviewLandingPage({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.main),
            const SizedBox(height: 24),
            Text('Ready for Practice?', style: AppTextStyles.h1),
            const SizedBox(height: 12),
            Text(
              'Start an interactive interview session with our AI coach.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 40),
            CustomButton(text: 'START INTERVIEW', onPressed: onStart),
          ],
        ),
      ),
    );
  }
}
