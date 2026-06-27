import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/interview_message.dart';
import '../models/interview_session.dart';

class SessionHistoryDetailScreen extends StatelessWidget {
  final InterviewSession session;

  const SessionHistoryDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp-like background
      appBar: AppBar(
        backgroundColor: AppColors.main,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.level.label} - ${session.stage.label}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(session.startedAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: session.messages.length,
        itemBuilder: (context, index) {
          final message = session.messages[index];
          final isUser = message.sender == InterviewMessageSender.user;

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
