import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'constants/app_colors.dart';
import 'screens/main_navigation_wrapper.dart';
import 'services/ai_interview_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.aiService});

  final AiInterviewService? aiService;

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
      // Menggunakan wrapper yang benar dari folder screens
      home: SplashNavigationWrapper(aiService: aiService),
    );
  }
}
