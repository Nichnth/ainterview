import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class PinInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool enabled;
  final bool hasError;

  const PinInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _pinValues;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _pinValues = List.generate(widget.length, (_) => '');
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      _pinValues[index] = value.substring(value.length - 1);
      _controllers[index].text = _pinValues[index];
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      _pinValues[index] = '';
    }

    String currentPin = _pinValues.join();
    if (currentPin.length == widget.length) {
      widget.onCompleted(currentPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2,
            onChanged: (value) => _onChanged(value, index),
            decoration: InputDecoration(
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                borderSide: BorderSide(color: widget.hasError ? AppColors.danger : AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                borderSide: BorderSide(
                  color: widget.hasError ? AppColors.danger : AppColors.main,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        );
      }),
    );
  }
}