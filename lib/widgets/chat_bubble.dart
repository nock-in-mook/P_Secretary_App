import 'package:flutter/material.dart';
import '../models/message.dart';

/// LINEライクな吹き出しウィジェット
class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 秘書アバター（左側）
          if (!isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8D5F5),
              child: Icon(Icons.person, size: 20, color: Color(0xFF7B4FA2)),
            ),
            const SizedBox(width: 8),
          ],

          // 時刻（ユーザー側は吹き出しの左）
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),

          // 吹き出し本体
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF7B4FA2) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // 時刻（秘書側は吹き出しの右）
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
