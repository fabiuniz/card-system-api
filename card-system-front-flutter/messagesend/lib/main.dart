import 'package:flutter/material.dart';
import 'screens/message_screen.dart';

void main() => runApp(const MessageSendApp());

class MessageSendApp extends StatelessWidget {
  const MessageSendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Message & File Tool',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const MessageScreen(),
    );
  }
}