import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/chat_screen.dart';

class SendakilLabApp extends StatelessWidget {
  const SendakilLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SendakilLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ChatScreen(),
    );
  }
}
