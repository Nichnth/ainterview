import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/bookmark.dart';
import '../models/interview_session.dart';
import '../services/auth_service.dart';
import '../services/bookmark_repository.dart';
import '../services/firestore_interview_session_repository.dart';
import '../widgets/edit_label_dialog.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final FirestoreInterviewSessionRepository? sessionRepository;

  const ProfileScreen({
    super.key,
    this.userId,
    this.sessionRepository,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localImagePath;
  List<InterviewSession> _sessions = const [];
  bool _isLoadingSessions = false;
  String? _sessionError;

  // Bookmarks
  final _bookmarkRepo = BookmarkRepository();
  List<Bookmark> _bookmarks = const [];
  bool _isLoadingBookmarks = false;
  StreamSubscription<List<Bookmark>>? _bookmarkSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSessionHistory();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } catch (e) {
        // Handle error if necessary
      }

      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_${user.uid}');
      if (path != null && File(path).existsSync()) {
        if (mounted) {
          setState(() {
            _localImagePath = path;
          });
        }
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

  void _loadBookmarks() {
    final userId = widget.userId ?? AuthService.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoadingBookmarks = true);

    _bookmarkSubscription = _bookmarkRepo.watchBookmarks(userId).listen(
      (bookmarks) {
        if (!mounted) return;
        setState(() {
          _bookmarks = bookmarks;
          _isLoadingBookmarks = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoadingBookmarks = false);
      },
    );
  }

  Future<void> _editBookmarkLabel(Bookmark bookmark) async {
    final userId = widget.userId ?? AuthService.instance.currentUser?.uid;
    if (userId == null) return;

    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => EditLabelDialog(initialLabel: bookmark.label),
    );

    if (newLabel == null || newLabel.isEmpty || !mounted) return;

    try {
      await _bookmarkRepo.updateBookmarkLabel(userId, bookmark.id, newLabel);
      _loadBookmarks();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $error')),
      );
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final userId = widget.userId ?? AuthService.instance.currentUser?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text('Remove "${bookmark.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _bookmarkRepo.deleteBookmark(userId, bookmark.id);
      _loadBookmarks();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $error')),
      );
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
              padding: const EdgeInsets.only(top: 40, bottom: 80),
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
                          MediaQuery.of(context).size.width, 80),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 80),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _ProfileContent(
                            bookmarks: _bookmarks,
                            isLoadingBookmarks: _isLoadingBookmarks,
                            onEditBookmark: _editBookmarkLabel,
                            onDeleteBookmark: _deleteBookmark,
                            isLoadingSessions: _isLoadingSessions,
                            sessionError: _sessionError,
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
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.grey)
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

/// Combined content widget that shows bookmarks section + review history
class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.bookmarks,
    required this.isLoadingBookmarks,
    required this.onEditBookmark,
    required this.onDeleteBookmark,
    required this.isLoadingSessions,
    required this.sessionError,
    required this.sessions,
    required this.onRetry,
  });

  final List<Bookmark> bookmarks;
  final bool isLoadingBookmarks;
  final void Function(Bookmark) onEditBookmark;
  final void Function(Bookmark) onDeleteBookmark;
  final bool isLoadingSessions;
  final String? sessionError;
  final List<InterviewSession> sessions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // ── Bookmarks Section ──
        Row(
          children: [
            const Icon(Icons.bookmark, color: AppColors.main, size: 20),
            const SizedBox(width: 6),
            Text('Bookmarks', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingBookmarks)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (bookmarks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No bookmarks yet.\nBookmark a session after completing an interview!',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ),
          )
        else
          ...bookmarks.map(
            (bookmark) => _BookmarkCard(
              bookmark: bookmark,
              onEdit: () => onEditBookmark(bookmark),
              onDelete: () => onDeleteBookmark(bookmark),
            ),
          ),

        const SizedBox(height: 24),

        // ── Review History Section ──
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.secondary, size: 20),
            const SizedBox(width: 6),
            Text('Review History', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingSessions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (sessionError != null)
          _ErrorCard(message: sessionError!, onRetry: onRetry)
        else if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'Card review latihan interview\nakan muncul di sini',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ),
          )
        else
          ...sessions.map(
            (session) => _ReviewHistoryCard(session: session),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.onEdit,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: label + action icons
            Row(
              children: [
                const Icon(Icons.bookmark, color: AppColors.main, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bookmark.label,
                    style: AppTextStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.secondary, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Edit label',
                ),
                const SizedBox(width: 8),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.grey, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Level / Stage badges
            Row(
              children: [
                _Badge(text: bookmark.level),
                const SizedBox(width: 6),
                _Badge(text: bookmark.stage),
                const SizedBox(width: 6),
                _Badge(text: bookmark.language),
              ],
            ),
            const SizedBox(height: 10),

            // Summary
            Text(
              bookmark.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm')
                      .format(bookmark.sessionDate),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.main.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.main,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load review history', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.caption),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final InterviewSession session;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _SessionHistoryCard({
    required this.session,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.main.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.level.label,
                      style: const TextStyle(
                        color: AppColors.main,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          session.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: session.isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: onFavorite,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.grey, size: 20),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Stage: ${session.stage.label}',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 4),
              Text(
                session.review?.summary ?? 'Session result summary...',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(session.startedAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
