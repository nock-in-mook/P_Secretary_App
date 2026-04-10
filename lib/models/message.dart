/// チャットメッセージのモデル
class Message {
  final String id;
  final String content;
  final bool isUser; // true=ユーザー, false=秘書
  final DateTime timestamp;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
