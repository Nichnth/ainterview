import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_enums.dart';
import '../models/interview_plan.dart';
import '../models/schedule_item.dart';
import '../providers/interview_plan_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/date_time_picker.dart';

class InterviewPlanScreen extends StatefulWidget {
  const InterviewPlanScreen({
    super.key,
    required this.controller,
    this.onPracticeItem,
  });

  final InterviewPlanController controller;
  final ValueChanged<String>? onPracticeItem;

  @override
  State<InterviewPlanScreen> createState() => _InterviewPlanScreenState();
}

class _InterviewPlanScreenState extends State<InterviewPlanScreen> {
  late DateTime _targetDate;
  InterviewLevel _level = InterviewLevel.junior;
  InterviewLanguage _language = InterviewLanguage.indonesian;
  String? _editingPlanId;

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
    try {
      final editingPlanId = _editingPlanId;
      if (editingPlanId == null) {
        await widget.controller.createPlan(
          targetDate: _targetDate,
          level: _level,
          language: _language,
        );
        return;
      }

      await widget.controller.updatePlan(
        editingPlanId,
        targetDate: _targetDate,
        level: _level,
        language: _language,
      );
      if (mounted) {
        setState(() => _editingPlanId = null);
      }
    } catch (_) {
      // The controller exposes mutation failures through errorMessage.
    }
  }

  void _beginEditPlan(InterviewPlan plan) {
    setState(() {
      _editingPlanId = plan.id;
      _targetDate = plan.targetDate;
      _level = plan.level;
      _language = plan.language;
    });
  }

  void _cancelEditPlan() {
    setState(() {
      _editingPlanId = null;
      _targetDate = DateTime.now().add(const Duration(days: 14));
      _level = InterviewLevel.junior;
      _language = InterviewLanguage.indonesian;
    });
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
                  isLoading: widget.controller.isLoading,
                  onPickDate: _pickTargetDate,
                  onLevelChanged: (level) {
                    if (level != null) setState(() => _level = level);
                  },
                  onLanguageChanged: (language) {
                    if (language != null) setState(() => _language = language);
                  },
                  onSave: _savePlan,
                  isEditing: _editingPlanId != null,
                  onCancelEdit: _editingPlanId == null ? null : _cancelEditPlan,
                ),
                AppSizes.vSpaceLarge,
                if (widget.controller.isLoading)
                  const _LoadingPlanState()
                else if (widget.controller.errorMessage != null)
                  _ErrorPlanState(message: widget.controller.errorMessage!)
                else if (widget.controller.plans.isEmpty)
                  const _EmptyPlanState()
                else ...[
                  _PlanList(
                    plans: widget.controller.plans,
                    selectedPlanId: widget.controller.selectedPlanId,
                    onSelected: widget.controller.selectPlan,
                  ),
                  AppSizes.vSpaceLarge,
                  if (widget.controller.selectedPlan != null)
                    _PlanDetail(
                      plan: widget.controller.selectedPlan!,
                      controller: widget.controller,
                      onPracticeItem: widget.onPracticeItem,
                      onEdit: _beginEditPlan,
                    ),
                ],
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
    required this.isLoading,
    required this.onPickDate,
    required this.onLevelChanged,
    required this.onLanguageChanged,
    required this.onSave,
    required this.isEditing,
    required this.onCancelEdit,
  });

  final DateTime targetDate;
  final InterviewLevel level;
  final InterviewLanguage language;
  final bool isLoading;
  final VoidCallback onPickDate;
  final ValueChanged<InterviewLevel?> onLevelChanged;
  final ValueChanged<InterviewLanguage?> onLanguageChanged;
  final VoidCallback onSave;
  final bool isEditing;
  final VoidCallback? onCancelEdit;

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
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: isEditing
                      ? 'Update Practice Plan'
                      : 'Generate Practice Plan',
                  onPressed: isLoading ? null : onSave,
                ),
              ),
              if (onCancelEdit != null) ...[
                AppSizes.hSpaceSmall,
                TextButton(
                  onPressed: isLoading ? null : onCancelEdit,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.selectedPlanId,
    required this.onSelected,
  });

  final List<InterviewPlan> plans;
  final String? selectedPlanId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Plans', style: AppTextStyles.h2),
          AppSizes.vSpaceMedium,
          for (final plan in plans) ...[
            _PlanSummaryTile(
              plan: plan,
              isSelected: plan.id == selectedPlanId,
              onTap: () => onSelected(plan.id),
            ),
            if (plan != plans.last) AppSizes.vSpaceSmall,
          ],
        ],
      ),
    );
  }
}

class _PlanSummaryTile extends StatelessWidget {
  const _PlanSummaryTile({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final InterviewPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completedCount = plan.scheduleItems
        .where((item) => item.isCompleted)
        .length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.main.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.main : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pMedium),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.main : AppColors.textMuted,
              ),
              AppSizes.hSpaceSmall,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.level.label} - ${_formatDate(plan.targetDate)}',
                      style: AppTextStyles.h3,
                    ),
                    AppSizes.vSpaceSmall,
                    Text(
                      '${plan.language.label} - $completedCount/${plan.scheduleItems.length} completed',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanDetail extends StatelessWidget {
  const _PlanDetail({
    required this.plan,
    required this.controller,
    required this.onPracticeItem,
    required this.onEdit,
  });

  final InterviewPlan plan;
  final InterviewPlanController controller;
  final ValueChanged<String>? onPracticeItem;
  final ValueChanged<InterviewPlan> onEdit;

  @override
  Widget build(BuildContext context) {
    final remainingDays = _daysUntil(plan.targetDate);
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
              Wrap(
                spacing: AppSizes.pSmall,
                children: [
                  TextButton.icon(
                    onPressed: () => onEdit(plan),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await controller.deletePlan(plan.id);
                      } catch (_) {
                        // The controller exposes mutation failures.
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
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
                item: plan.scheduleItems[index],
                onChanged: (value) async {
                  try {
                    await controller.toggleScheduleItem(
                      plan.id,
                      itemIndex: index,
                      isCompleted: value ?? false,
                    );
                  } catch (_) {
                    // The controller exposes mutation failures.
                  }
                },
                onPractice: onPracticeItem == null
                    ? null
                    : () => onPracticeItem!(plan.scheduleItems[index].id),
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
    required this.item,
    required this.onChanged,
    required this.onPractice,
  });

  final int itemNumber;
  final ScheduleItem item;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.pSmall),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          color: item.isCompleted
              ? AppColors.success.withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Column(
          children: [
            CheckboxListTile(
              value: item.isCompleted,
              onChanged: onChanged,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.success,
              title: Text(item.title, style: AppTextStyles.h3),
              subtitle: Text(
                'Day ${item.dayOffset} - ${item.description}',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pMedium,
                0,
                AppSizes.pMedium,
                AppSizes.pSmall,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: ValueKey('practice_${item.id}'),
                  onPressed: onPractice,
                  icon: const Icon(Icons.play_arrow_outlined, size: 18),
                  label: const Text('Practice'),
                ),
              ),
            ),
          ],
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

class _LoadingPlanState extends StatelessWidget {
  const _LoadingPlanState();

  @override
  Widget build(BuildContext context) {
    return const _Surface(child: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorPlanState extends StatelessWidget {
  const _ErrorPlanState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          AppSizes.vSpaceSmall,
          Text('Could not load plans', style: AppTextStyles.h3),
          AppSizes.vSpaceSmall,
          Text(
            message,
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

int _daysUntil(DateTime date) {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedTarget = DateTime(date.year, date.month, date.day);
  return normalizedTarget.difference(normalizedToday).inDays.clamp(0, 999);
}
