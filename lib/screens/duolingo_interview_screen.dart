import 'dart:async';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_preparation_context.dart';
import '../providers/interview_plan_controller.dart';
import '../providers/interview_session_controller.dart';
import '../services/ai_interview_service.dart';
import '../services/interview_session_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';

class DuolingoInterviewScreen extends StatefulWidget {
  const DuolingoInterviewScreen({
    super.key,
    required this.aiService,
    this.planController,
    this.sessionRepository,
    this.practiceScheduleItemId,
    this.practiceRequestVersion = 0,
  });

  final AiInterviewService aiService;
  final InterviewPlanController? planController;
  final InterviewSessionRepository? sessionRepository;
  final String? practiceScheduleItemId;
  final int practiceRequestVersion;

  @override
  State<DuolingoInterviewScreen> createState() => _DuolingoInterviewScreenState();
}

class _DuolingoInterviewScreenState extends State<DuolingoInterviewScreen> {
  late final InterviewSessionController _controller;
  final _answerController = TextEditingController();
  InterviewLevel _level = InterviewLevel.junior;
  InterviewStage _stage = InterviewStage.hr;
  InterviewLanguage _language = InterviewLanguage.indonesian;
  String? _selectedScheduleItemId;

  @override
  void initState() {
    super.initState();
    _controller = InterviewSessionController(
      aiService: widget.aiService,
      sessionRepository: widget.sessionRepository,
    );
    _applyPracticeRequest();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DuolingoInterviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.practiceRequestVersion != oldWidget.practiceRequestVersion) {
      _applyPracticeRequest();
    }
  }

  Future<void> _startSession() async {
    FocusScope.of(context).unfocus();
    final activePlan = widget.planController?.activePlan;
    final preparationContext = _activePreparationContext();
    
    await _controller.start(
      level: activePlan?.level ?? _level,
      stage: _stage,
      language: activePlan?.language ?? _language,
      linkedPlanId: activePlan?.id,
      linkedScheduleItemId: preparationContext?.selectedScheduleItemId,
      preparationContext: preparationContext,
    );
  }

  Future<void> _sendAnswer() async {
    final answer = _answerController.text;
    if (answer.trim().isEmpty) return;
    
    FocusScope.of(context).unfocus();
    _answerController.clear();
    await _controller.sendUserAnswer(answer);
  }

  Future<void> _handleQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Interview?'),
        content: const Text('Your progress in this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('QUIT', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (quit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  InterviewPreparationContext? _activePreparationContext() {
    final activePlan = widget.planController?.activePlan;
    return activePlan == null
        ? null
        : InterviewPreparationContext.fromPlan(
            activePlan,
            selectedScheduleItemId: _selectedScheduleItemId,
          );
  }

  void _applyPracticeRequest() {
    final scheduleItemId = widget.practiceScheduleItemId;
    final activePlan = widget.planController?.activePlan;
    if (scheduleItemId == null || activePlan == null) return;

    final preparationContext = InterviewPreparationContext.fromPlan(
      activePlan,
      selectedScheduleItemId: scheduleItemId,
    );
    
    setState(() {
      _selectedScheduleItemId = scheduleItemId;
      _level = activePlan.level;
      _language = activePlan.language;
      final suggestedStage = preparationContext.suggestedStage;
      if (suggestedStage != null) _stage = suggestedStage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_controller.messages.isEmpty || _controller.isEnded) {
          Navigator.of(context).pop();
          return;
        }
        _handleQuit();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.messages.isEmpty) {
            return _SetupView(
              level: _level,
              stage: _stage,
              language: _language,
              isBusy: _controller.isBusy,
              errorMessage: _controller.errorMessage,
              onLevelChanged: (v) => setState(() => _level = v!),
              onStageChanged: (v) => setState(() => _stage = v!),
              onLanguageChanged: (v) => setState(() => _language = v!),
              onStart: _startSession,
              onClose: () => Navigator.of(context).pop(),
            );
          }

          if (_controller.isEnded && _controller.review != null) {
            return _CompletionView(
              summary: _controller.review!.summary,
              onFinished: () => Navigator.of(context).pop(),
            );
          }

          return _DuolingoSessionView(
            controller: _controller,
            answerController: _answerController,
            onSend: _controller.isBusy ? null : _sendAnswer,
            onQuit: _handleQuit,
          );
        },
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.level,
    required this.stage,
    required this.language,
    required this.isBusy,
    this.errorMessage,
    required this.onLevelChanged,
    required this.onStageChanged,
    required this.onLanguageChanged,
    required this.onStart,
    required this.onClose,
  });

  final InterviewLevel level;
  final InterviewStage stage;
  final InterviewLanguage language;
  final bool isBusy;
  final String? errorMessage;
  final ValueChanged<InterviewLevel?> onLevelChanged;
  final ValueChanged<InterviewStage?> onStageChanged;
  final ValueChanged<InterviewLanguage?> onLanguageChanged;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onClose),
        title: Text('Setup Interview', style: AppTextStyles.h2),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 80, color: AppColors.main),
            const SizedBox(height: 24),
            Text('Ready for your interview?', style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            CustomDropdown<InterviewLevel>(
              label: 'Experience Level',
              hintText: 'Select level',
              value: level,
              items: InterviewLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
              onChanged: onLevelChanged,
            ),
            const SizedBox(height: 16),
            CustomDropdown<InterviewStage>(
              label: 'Interview Stage',
              hintText: 'Select stage',
              value: stage,
              items: InterviewStage.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
              onChanged: onStageChanged,
            ),
            const SizedBox(height: 16),
            CustomDropdown<InterviewLanguage>(
              label: 'Language',
              hintText: 'Select language',
              value: language,
              items: InterviewLanguage.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
              onChanged: onLanguageChanged,
            ),
            const SizedBox(height: 32),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(errorMessage!, style: AppTextStyles.error),
              ),
            CustomButton(
              text: 'START INTERVIEW',
              onPressed: isBusy ? null : onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _DuolingoSessionView extends StatelessWidget {
  const _DuolingoSessionView({
    required this.controller,
    required this.answerController,
    required this.onSend,
    required this.onQuit,
  });

  final InterviewSessionController controller;
  final TextEditingController answerController;
  final VoidCallback? onSend;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final messages = controller.messages;
    final lastAiMessage = messages.lastWhere(
      (m) => m.sender == InterviewMessageSender.ai,
      orElse: () => InterviewMessage(sender: InterviewMessageSender.ai, text: '...', createdAt: DateTime.now()),
    );
    final progress = (messages.length / 10).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close, color: AppColors.secondary), onPressed: onQuit),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.favorite, color: Colors.red),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(color: AppColors.light, shape: BoxShape.circle),
                          child: const Icon(Icons.face_retouching_natural, size: 50, color: AppColors.main),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Text(
                              lastAiMessage.text,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (messages.isNotEmpty && messages.last.sender == InterviewMessageSender.user)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.main.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(messages.last.text, style: AppTextStyles.bodyMedium),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 2))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: answerController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type your response...',
                      filled: true,
                      fillColor: AppColors.light,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: controller.isBusy 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('CHECK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  if (messages.length > 3) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => controller.endAndReview(),
                      child: const Text('Finish and get review early'),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.summary, required this.onFinished});
  final String summary;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              Text('Session Complete!', style: AppTextStyles.h1),
              const SizedBox(height: 16),
              Text(
                summary,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
              ),
              const Spacer(),
              CustomButton(text: 'CONTINUE', onPressed: onFinished),
            ],
          ),
        ),
      ),
    );
  }
}
