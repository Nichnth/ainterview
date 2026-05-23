import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomRadioButton<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const CustomRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onChanged != null;

    return Row(
      children: [
        Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppColors.main,
        ),
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isEnabled ? AppColors.textMain : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}