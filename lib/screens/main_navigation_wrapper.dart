import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/interview_plan_controller.dart';
import '../services/ai_interview_service.dart';
import '../services/auth_service.dart';
import '../services/interview_plan_repository.dart';
import '../services/interview_session_repository.dart';
import '../services/firestore_interview_session_repository.dart';
import '../services/open_router_ai_interview_service.dart';
import '../widgets/custom_button.dart';
import 'duolingo_interview_screen.dart';
import 'interview_plan_screen.dart';
import 'profile_screen.dart';
import 'splash_screen.dart';

class SplashNavigationWrapper extends StatefulWidget {
  const SplashNavigationWrapper({super.key, this.aiService});

  final AiInterviewService? aiService;

  @override
  State<SplashNavigationWrapper> createState() => _SplashNavigationWrapperState();
}

class _SplashNavigationWrapperState extends State<SplashNavigationWrapper> {
  bool _showSplash = true;

  void _completeSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _completeSplash);
    }
    return MainNavigationWrapper(aiService: widget.aiService);
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key, this.aiService});

  final AiInterviewService? aiService;

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  static const _openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  late final InterviewPlanController _planController;
  late final InterviewSessionRepository _sessionRepository;
  late final AiInterviewService _aiService;

  @override
  void initState() {
    super.initState();
    final userId = AuthService.instance.currentUser?.uid ?? 'demo_user';
    
    _planController = InterviewPlanController(
      repository: InMemoryInterviewPlanRepository(),
      userId: userId,
    );
    _planController.loadPlans();
    
    // Switch to Firestore Repository
    _sessionRepository = FirestoreInterviewSessionRepository();
    
    _aiService = widget.aiService ??
        (_openRouterApiKey.isEmpty
            ? MissingOpenRouterApiKeyAiInterviewService()
            : OpenRouterAiInterviewService(apiKey: _openRouterApiKey));
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
      ProfileScreen(sessionRepository: _sessionRepository as FirestoreInterviewSessionRepository),
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
