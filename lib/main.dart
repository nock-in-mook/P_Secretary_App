import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const PSecretaryApp());
}

class PSecretaryApp extends StatelessWidget {
  const PSecretaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P Secretary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B4FA2), // 紫ベースのテーマカラー
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0EDF3), // 薄紫グレーの背景
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
