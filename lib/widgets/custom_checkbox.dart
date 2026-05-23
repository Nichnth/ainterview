import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomCheckbox extends StatelessWidget {
  final Widget labelWidget;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool hasError;

  const CustomCheckbox({
    super.key,
    required this.labelWidget,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onChanged != null;

    return Row(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor: hasError ? AppColors.danger : AppColors.border,
          ),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: isEnabled ? AppColors.main : AppColors.border,
          ),
        ),
        Expanded(
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: labelWidget,
          ),
        ),
      ],
    );
  }
}