import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class CustomDateTimePicker extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback? onTap;
  final String? errorText;

  const CustomDateTimePicker({
    super.key,
    required this.label,
    required this.valueText,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isEnabled ? AppColors.textMain : AppColors.textMuted,
          ),
        ),
        AppSizes.vSpaceSmall,
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              errorStyle: AppTextStyles.error,
              filled: !isEnabled,
              fillColor: AppColors.light,
              suffixIcon: Icon(Icons.calendar_today,
                  color: isEnabled ? AppColors.textMuted : AppColors.border),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
            ),
            child: Text(
              valueText,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isEnabled ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}