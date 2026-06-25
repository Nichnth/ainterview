import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_session.dart';
import '../services/auth_service.dart';
import '../services/interview_session_repository.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId, this.sessionRepository});

  final String? userId;
  final InterviewSessionRepository? sessionRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localImagePath;
  List<InterviewSession> _sessions = const [];
  bool _isLoadingSessions = false;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSessionHistory();
  }

  Future<void> _loadProfileData() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      // Reload user to get the latest profile info (like displayName) from Firebase
      try {
        await user.reload();
      } catch (e) {
        // Handle error if necessary
      }

      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _localImagePath = prefs.getString('profile_image_${user.uid}');
        });
      }
    }
  }

  Future<void> _loadSessionHistory() async {
    final repository = widget.sessionRepository;
    final userId = widget.userId ?? AuthService.instance.currentUser?.uid;
    if (repository == null || userId == null) {
      return;
    }

    setState(() {
      _isLoadingSessions = true;
      _sessionError = null;
    });

    try {
      final sessions = await repository.fetchSessions(
        userId,
        completedOnly: true,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingSessions = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${user.uid}', pickedFile.path);
        setState(() {
          _localImagePath = pickedFile.path;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the latest user instance after reload
    final user = AuthService.instance.currentUser;

    // Use displayName from Firebase, fallback to email or 'User' if not set
    final displayName =
        user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (user?.email ?? 'User');

    return Scaffold(
      backgroundColor: AppColors.main,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              // Menurunkan posisi nama (top: 60) dan memperlebar jarak ke foto (bottom: 100)
              padding: const EdgeInsets.only(top: 60, bottom: 100),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.light),
                        onPressed: _handleLogout,
                        tooltip: 'Logout',
                      ),
                    ),
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.light,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.elliptical(
                        MediaQuery.of(context).size.width,
                        80,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 80),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _ReviewHistory(
                            isLoading: _isLoadingSessions,
                            errorMessage: _sessionError,
                            sessions: _sessions,
                            onRetry: _loadSessionHistory,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top:
                      -55, // Sedikit disesuaikan agar tetap proporsional di tengah lengkungan
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        border: Border.all(color: Colors.white, width: 4),
                        image: _localImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_localImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _localImagePath == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewHistory extends StatelessWidget {
  const _ReviewHistory({
    required this.isLoading,
    required this.errorMessage,
    required this.sessions,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<InterviewSession> sessions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load review history', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'Card review latihan interview\nakan muncul di sini',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black38, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ReviewHistoryCard(session: sessions[index]);
      },
    );
  }
}

class _ReviewHistoryCard extends StatelessWidget {
  const _ReviewHistoryCard({required this.session});

  final InterviewSession session;

  @override
  Widget build(BuildContext context) {
    final review = session.review;
    final recommendation = review?.recommendations.isEmpty ?? true
        ? null
        : review!.recommendations.first.title;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.level.label} ${session.stage.label}',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 4),
            Text(
              '${session.language.label} - ${_formatDate(session.startedAt)}',
              style: AppTextStyles.caption,
            ),
            if (session.preparationFocusTitle != null) ...[
              const SizedBox(height: 8),
              Text(
                session.preparationFocusTitle!,
                style: AppTextStyles.caption,
              ),
            ],
            if (review != null) ...[
              const SizedBox(height: 8),
              Text(review.summary, style: AppTextStyles.bodyMedium),
            ],
            if (recommendation != null) ...[
              const SizedBox(height: 8),
              Text(recommendation, style: AppTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
