import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class BottomSheetSelector extends StatelessWidget {
  final String label;
  final String selectedValueText;
  final VoidCallback? onTap;

  const BottomSheetSelector({
    super.key,
    required this.label,
    required this.selectedValueText,
    required this.onTap,
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : AppColors.light,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: isEnabled ? AppColors.border : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedValueText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isEnabled ? AppColors.textMain : AppColors.textMuted,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: isEnabled ? AppColors.textMuted : AppColors.border),
              ],
            ),
          ),
        ),
      ],
    );
  }
}