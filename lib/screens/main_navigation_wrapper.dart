import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_preparation_context.dart';
import '../models/interview_review.dart';
import '../providers/interview_plan_controller.dart';
import '../services/ai_interview_service.dart';
import '../services/auth_service.dart';
import '../services/backend_ai_interview_service.dart';
import '../services/firestore_repositories.dart';
import '../services/interview_plan_repository.dart';
import '../services/interview_session_repository.dart';
import '../services/open_router_ai_interview_service.dart';
import 'interview_plan_screen.dart';
import 'interview_session_screen.dart';
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
  int _practiceRequestVersion = 0;
  String? _practiceScheduleItemId;
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
    _aiService =
        widget.aiService ??
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      InterviewPlanScreen(
        controller: _planController,
        onPracticeItem: _startPracticeFromPlanItem,
      ),
      InterviewSessionScreen(
        aiService: _aiService,
        userId: widget.userId,
        planController: _planController,
        sessionRepository: _sessionRepository,
        practiceScheduleItemId: _practiceScheduleItemId,
        practiceRequestVersion: _practiceRequestVersion,
      ),
      widget.profilePage ??
          ProfileScreen(
            userId: widget.userId,
            sessionRepository: _sessionRepository,
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
        indicatorColor: AppColors.main.withValues(alpha: 0.2),
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

  void _startPracticeFromPlanItem(String scheduleItemId) {
    setState(() {
      _practiceScheduleItemId = scheduleItemId;
      _practiceRequestVersion += 1;
      _currentIndex = 1;
    });
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
