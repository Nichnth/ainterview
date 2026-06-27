import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EditLabelDialog extends StatefulWidget {
  const EditLabelDialog({
    super.key,
    required this.initialLabel,
    this.title = 'Edit Label',
  });

  final String initialLabel;
  final String title;

  @override
  State<EditLabelDialog> createState() => _EditLabelDialogState();
}

class _EditLabelDialogState extends State<EditLabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Label',
          filled: true,
          fillColor: AppColors.light,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.main),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.main,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
