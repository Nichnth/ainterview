import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_enums.dart';
import '../models/interview_message.dart';
import '../models/interview_review.dart';
import '../providers/interview_session_controller.dart';
import '../services/ai_interview_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';

class InterviewSessionScreen extends StatefulWidget {
  const InterviewSessionScreen({super.key, required this.aiService});

  final AiInterviewService aiService;

  @override
  State<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen> {
  late final InterviewSessionController _controller;
  final _answerController = TextEditingController();
  InterviewLevel _level = InterviewLevel.junior;
  InterviewStage _stage = InterviewStage.hr;
  InterviewLanguage _language = InterviewLanguage.indonesian;

  @override
  void initState() {
    super.initState();
    _controller = InterviewSessionController(aiService: widget.aiService);
  }

  @override
  void dispose() {
    _answerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    await _controller.start(level: _level, stage: _stage, language: _language);
  }

  Future<void> _sendAnswer() async {
    final answer = _answerController.text;
    _answerController.clear();
    await _controller.sendUserAnswer(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mock Interview', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.messages.isEmpty) {
            return _SetupView(
              level: _level,
              stage: _stage,
              language: _language,
              isBusy: _controller.isBusy,
              onLevelChanged: (level) {
                if (level != null) setState(() => _level = level);
              },
              onStageChanged: (stage) {
                if (stage != null) setState(() => _stage = stage);
              },
              onLanguageChanged: (language) {
                if (language != null) setState(() => _language = language);
              },
              onStart: _startSession,
            );
          }

          return _SessionView(
            controller: _controller,
            answerController: _answerController,
            onSend: _controller.isBusy || _controller.isEnded
                ? null
                : _sendAnswer,
            onEnd: _controller.isBusy || _controller.isEnded
                ? null
                : _controller.endAndReview,
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
    required this.onLevelChanged,
    required this.onStageChanged,
    required this.onLanguageChanged,
    required this.onStart,
  });

  final InterviewLevel level;
  final InterviewStage stage;
  final InterviewLanguage language;
  final bool isBusy;
  final ValueChanged<InterviewLevel?> onLevelChanged;
  final ValueChanged<InterviewStage?> onStageChanged;
  final ValueChanged<InterviewLanguage?> onLanguageChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interview Setup', style: AppTextStyles.h1),
          AppSizes.vSpaceSmall,
          Text(
            'Choose a level and stage, then practice with a contextual interviewer.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          AppSizes.vSpaceLarge,
          _Surface(
            child: Column(
              children: [
                CustomDropdown<InterviewLevel>(
                  label: 'Level',
                  hintText: 'Choose level',
                  value: level,
                  items: InterviewLevel.values
                      .map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Text(level.label),
                        ),
                      )
                      .toList(),
                  onChanged: onLevelChanged,
                ),
                AppSizes.vSpaceMedium,
                CustomDropdown<InterviewStage>(
                  label: 'Stage',
                  hintText: 'Choose stage',
                  value: stage,
                  items: InterviewStage.values
                      .map(
                        (stage) => DropdownMenuItem(
                          value: stage,
                          child: Text(stage.label),
                        ),
                      )
                      .toList(),
                  onChanged: onStageChanged,
                ),
                AppSizes.vSpaceMedium,
                CustomDropdown<InterviewLanguage>(
                  label: 'Language',
                  hintText: 'Choose language',
                  value: language,
                  items: InterviewLanguage.values
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language.label),
                        ),
                      )
                      .toList(),
                  onChanged: onLanguageChanged,
                ),
                AppSizes.vSpaceLarge,
                CustomButton(
                  text: 'Start Mock Interview',
                  onPressed: isBusy ? null : onStart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionView extends StatelessWidget {
  const _SessionView({
    required this.controller,
    required this.answerController,
    required this.onSend,
    required this.onEnd,
  });

  final InterviewSessionController controller;
  final TextEditingController answerController;
  final VoidCallback? onSend;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final title = '${controller.level!.label} ${controller.stage!.label}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.pMedium),
          child: _Surface(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.main.withValues(alpha: 0.14),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.main,
                  ),
                ),
                AppSizes.hSpaceMedium,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.h3),
                      Text(
                        controller.isBusy
                            ? 'Processing response'
                            : 'Text interview ready',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final message in controller.messages)
                  _MessageBubble(message: message),
                if (controller.review != null)
                  _ReviewPanel(review: controller.review!),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.pMedium),
          child: Column(
            children: [
              if (!controller.isEnded)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: answerController,
                        decoration: InputDecoration(
                          hintText: 'Type your answer',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSmall,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSmall,
                            ),
                            borderSide: const BorderSide(color: AppColors.main),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.pMedium,
                            vertical: AppSizes.pSmall,
                          ),
                        ),
                      ),
                    ),
                    AppSizes.hSpaceSmall,
                    IconButton.filled(
                      onPressed: onSend,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              if (!controller.isEnded) AppSizes.vSpaceSmall,
              CustomButton(
                text: 'End Interview & Get Review',
                onPressed: onEnd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final InterviewMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == InterviewMessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: AppSizes.pSmall),
        padding: const EdgeInsets.all(AppSizes.pMedium),
        decoration: BoxDecoration(
          color: isUser ? AppColors.main : Colors.white,
          border: Border.all(color: isUser ? AppColors.main : AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isUser ? Colors.white : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.review});

  final InterviewReview review;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interview Review', style: AppTextStyles.h2),
          AppSizes.vSpaceSmall,
          Text(review.summary, style: AppTextStyles.bodyMedium),
          AppSizes.vSpaceMedium,
          Text('Communication', style: AppTextStyles.h3),
          Text(review.communicationFeedback, style: AppTextStyles.caption),
          AppSizes.vSpaceSmall,
          Text('Technical', style: AppTextStyles.h3),
          Text(review.technicalFeedback, style: AppTextStyles.caption),
          AppSizes.vSpaceMedium,
          for (final recommendation in review.recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.pSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18,
                  ),
                  AppSizes.hSpaceSmall,
                  Expanded(
                    child: Text(
                      recommendation,
                      style: AppTextStyles.bodyMedium,
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

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pMedium),
        child: child,
      ),
    );
  }
}
