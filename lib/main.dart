import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'constants/app_colors.dart';
import 'screens/main_navigation_wrapper.dart';
import 'screens/splash_screen.dart';
import 'services/ai_interview_service.dart';
import 'services/auth_service.dart';
import 'services/interview_plan_repository.dart';
import 'services/interview_session_repository.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.aiService,
    this.authenticatedUserId,
    this.showSplash = true,
    this.profilePage,
    this.planRepository,
    this.sessionRepository,
  });

  final AiInterviewService? aiService;
  final String? authenticatedUserId;
  final bool showSplash;
  final Widget? profilePage;
  final InterviewPlanRepository? planRepository;
  final InterviewSessionRepository? sessionRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Interview Coach',
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
      home: showSplash
          ? SplashNavigationWrapper(
              aiService: aiService,
              authenticatedUserId: authenticatedUserId,
              profilePage: profilePage,
              planRepository: planRepository,
              sessionRepository: sessionRepository,
            )
          : _AuthGate(
              aiService: aiService,
              authenticatedUserId: authenticatedUserId,
              profilePage: profilePage,
              planRepository: planRepository,
              sessionRepository: sessionRepository,
            ),
    );
  }
}

class SplashNavigationWrapper extends StatefulWidget {
  const SplashNavigationWrapper({
    super.key,
    this.aiService,
    this.authenticatedUserId,
    this.profilePage,
    this.planRepository,
    this.sessionRepository,
  });

  final AiInterviewService? aiService;
  final String? authenticatedUserId;
  final Widget? profilePage;
  final InterviewPlanRepository? planRepository;
  final InterviewSessionRepository? sessionRepository;

  @override
  State<SplashNavigationWrapper> createState() =>
      _SplashNavigationWrapperState();
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
    return _AuthGate(
      aiService: widget.aiService,
      authenticatedUserId: widget.authenticatedUserId,
      profilePage: widget.profilePage,
      planRepository: widget.planRepository,
      sessionRepository: widget.sessionRepository,
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({
    required this.aiService,
    required this.authenticatedUserId,
    required this.profilePage,
    required this.planRepository,
    required this.sessionRepository,
  });

  final AiInterviewService? aiService;
  final String? authenticatedUserId;
  final Widget? profilePage;
  final InterviewPlanRepository? planRepository;
  final InterviewSessionRepository? sessionRepository;

  @override
  Widget build(BuildContext context) {
    final userIdOverride = authenticatedUserId;
    if (userIdOverride != null) {
      return MainNavigationWrapper(
        userId: userIdOverride,
        aiService: aiService,
        profilePage: profilePage,
        planRepository: planRepository,
        sessionRepository: sessionRepository,
      );
    }

    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const LoginScreen();
        }

        return MainNavigationWrapper(
          userId: user.uid,
          aiService: aiService,
          profilePage: profilePage,
          planRepository: planRepository,
          sessionRepository: sessionRepository,
        );
      },
    );
  }
}
