import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'providers/interview_plan_controller.dart';
import 'screens/interview_plan_screen.dart';
import 'screens/interview_session_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ai_interview_service.dart';
import 'services/interview_plan_repository.dart';
import 'services/open_router_ai_interview_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Components Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'InstrumentSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.main,
          primary: AppColors.main,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashNavigationWrapper(),
    );
  }
}

class SplashNavigationWrapper extends StatefulWidget {
  const SplashNavigationWrapper({super.key});

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
    return const MainNavigationWrapper();
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  static const _openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  late final InterviewPlanController _planController;
  late final AiInterviewService _aiService;

  @override
  void initState() {
    super.initState();
    _planController = InterviewPlanController(
      repository: InMemoryInterviewPlanRepository(),
      userId: 'demo_user',
    );
    _aiService = _openRouterApiKey.isEmpty
        ? MockAiInterviewService()
        : OpenRouterAiInterviewService(apiKey: _openRouterApiKey);
  }

  @override
  void dispose() {
    _planController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InterviewPlanScreen(controller: _planController),
      InterviewSessionScreen(aiService: _aiService),
      const Center(child: Text('Profile and saved reviews will appear here.')),
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
}
