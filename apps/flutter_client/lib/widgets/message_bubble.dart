import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final maxWidth = MediaQuery.sizeOf(context).width > 900 ? 760.0 : double.infinity;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.blue,
                child: Icon(Icons.auto_awesome, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFFE8F3FF) : Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: SelectableText(
                  message.content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.48,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFDCEAF5),
                child: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.navy),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
