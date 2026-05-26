import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_enums.dart';
import '../models/interview_plan.dart';
import '../providers/interview_plan_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/date_time_picker.dart';

class InterviewPlanScreen extends StatefulWidget {
  const InterviewPlanScreen({super.key, required this.controller});

  final InterviewPlanController controller;

  @override
  State<InterviewPlanScreen> createState() => _InterviewPlanScreenState();
}

class _InterviewPlanScreenState extends State<InterviewPlanScreen> {
  late DateTime _targetDate;
  InterviewLevel _level = InterviewLevel.junior;
  InterviewLanguage _language = InterviewLanguage.indonesian;

  @override
  void initState() {
    super.initState();
    _targetDate = DateTime.now().add(const Duration(days: 14));
  }

  Future<void> _pickTargetDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      setState(() => _targetDate = selectedDate);
    }
  }

  Future<void> _savePlan() async {
    final existingPlan = widget.controller.plans.isEmpty
        ? null
        : widget.controller.plans.first;

    if (existingPlan == null) {
      await widget.controller.createPlan(
        targetDate: _targetDate,
        level: _level,
        language: _language,
      );
      return;
    }

    await widget.controller.updatePlan(
      existingPlan.id,
      targetDate: _targetDate,
      level: _level,
      language: _language,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Interview', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interview Plan', style: AppTextStyles.h1),
                AppSizes.vSpaceSmall,
                Text(
                  'Build a focused preparation timeline toward your target interview date.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                AppSizes.vSpaceLarge,
                _PlanForm(
                  targetDate: _targetDate,
                  level: _level,
                  language: _language,
                  hasPlan: widget.controller.plans.isNotEmpty,
                  isLoading: widget.controller.isLoading,
                  onPickDate: _pickTargetDate,
                  onLevelChanged: (level) {
                    if (level != null) setState(() => _level = level);
                  },
                  onLanguageChanged: (language) {
                    if (language != null) setState(() => _language = language);
                  },
                  onSave: _savePlan,
                ),
                AppSizes.vSpaceLarge,
                if (widget.controller.plans.isEmpty)
                  const _EmptyPlanState()
                else
                  _PlanDetail(
                    plan: widget.controller.plans.first,
                    controller: widget.controller,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanForm extends StatelessWidget {
  const _PlanForm({
    required this.targetDate,
    required this.level,
    required this.language,
    required this.hasPlan,
    required this.isLoading,
    required this.onPickDate,
    required this.onLevelChanged,
    required this.onLanguageChanged,
    required this.onSave,
  });

  final DateTime targetDate;
  final InterviewLevel level;
  final InterviewLanguage language;
  final bool hasPlan;
  final bool isLoading;
  final VoidCallback onPickDate;
  final ValueChanged<InterviewLevel?> onLevelChanged;
  final ValueChanged<InterviewLanguage?> onLanguageChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDateTimePicker(
            label: 'Target Interview Date',
            valueText: _formatDate(targetDate),
            onTap: onPickDate,
          ),
          AppSizes.vSpaceMedium,
          CustomDropdown<InterviewLevel>(
            label: 'Target Level',
            hintText: 'Choose level',
            value: level,
            items: InterviewLevel.values
                .map(
                  (level) =>
                      DropdownMenuItem(value: level, child: Text(level.label)),
                )
                .toList(),
            onChanged: onLevelChanged,
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
            text: hasPlan
                ? 'Regenerate Practice Plan'
                : 'Generate Practice Plan',
            onPressed: isLoading ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _PlanDetail extends StatelessWidget {
  const _PlanDetail({required this.plan, required this.controller});

  final InterviewPlan plan;
  final InterviewPlanController controller;

  @override
  Widget build(BuildContext context) {
    final remainingDays = plan.targetDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 999);
    final completedCount = plan.scheduleItems
        .where((item) => item.isCompleted)
        .length;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.level.label} Preparation',
                      style: AppTextStyles.h2,
                    ),
                    AppSizes.vSpaceSmall,
                    Text(
                      '$remainingDays days left - $completedCount/${plan.scheduleItems.length} completed',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.deletePlan(plan.id),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
          AppSizes.vSpaceMedium,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
          AppSizes.vSpaceMedium,
          ...[
            for (var index = 0; index < plan.scheduleItems.length; index++)
              _ScheduleTile(
                itemNumber: index + 1,
                title: plan.scheduleItems[index].title,
                description: plan.scheduleItems[index].description,
                dayOffset: plan.scheduleItems[index].dayOffset,
                isCompleted: plan.scheduleItems[index].isCompleted,
                onChanged: (value) => controller.toggleScheduleItem(
                  plan.id,
                  itemIndex: index,
                  isCompleted: value ?? false,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.itemNumber,
    required this.title,
    required this.description,
    required this.dayOffset,
    required this.isCompleted,
    required this.onChanged,
  });

  final int itemNumber;
  final String title;
  final String description;
  final int dayOffset;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.pSmall),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: CheckboxListTile(
          value: isCompleted,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.success,
          title: Text(title, style: AppTextStyles.h3),
          subtitle: Text(
            'Day $dayOffset - $description',
            style: AppTextStyles.caption,
          ),
          secondary: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.main.withValues(alpha: 0.14),
            child: Text(
              '$itemNumber',
              style: AppTextStyles.caption.copyWith(color: AppColors.main),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_note_outlined, color: AppColors.main, size: 32),
          AppSizes.vSpaceSmall,
          Text('No preparation plan yet', style: AppTextStyles.h3),
          AppSizes.vSpaceSmall,
          Text(
            'Choose your interview target and generate a timeline to begin.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
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

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
