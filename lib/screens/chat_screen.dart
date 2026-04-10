import 'package:flutter/material.dart';
import '../models/message.dart';
import '../widgets/chat_bubble.dart';

/// メインチャット画面
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  int _messageCounter = 0;

  @override
  void initState() {
    super.initState();
    // デモ用の初期メッセージ
    _messages.addAll([
      Message(
        id: '0',
        content: 'おはようございます！今日のご予定を確認しますね。',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: '1',
        content: '10時から会議があったよね？',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      Message(
        id: '2',
        content: 'はい！10時からチームミーティングが入っています。場所はオンライン（Google Meet）です。議題は先週のスプリントレビューですね。',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messageCounter++;
      _messages.add(Message(
        id: 'user_$_messageCounter',
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _controller.clear();
    _scrollToBottom();

    // デモ用：秘書の自動返答（後でAPI接続に置き換え）
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messageCounter++;
        _messages.add(Message(
          id: 'bot_$_messageCounter',
          content: 'かしこまりました！確認いたしますね。',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE8D5F5),
              child: Icon(Icons.person, size: 18, color: Color(0xFF7B4FA2)),
            ),
            SizedBox(width: 10),
            Text('秘書'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 設定メニュー（後で実装）
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // チャットメッセージ一覧
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: _messages[index]);
                  },
                ),
              ),
              // 入力欄
              _buildInputBar(),
            ],
          ),

          // キャラパネル（右下）— 後で透過動画に差し替え
          Positioned(
            right: 8,
            bottom: 80,
            child: IgnorePointer(
              child: Builder(
                builder: (context) {
                  // チャット領域の約3割の高さ
                  final screenHeight = MediaQuery.of(context).size.height;
                  final charHeight = screenHeight * 0.3;
                  final charWidth = charHeight * 0.65; // 人物の縦長比率
                  return Container(
                    width: charWidth,
                    height: charHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5F5).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7B4FA2).withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 48, color: Color(0xFF7B4FA2)),
                    SizedBox(height: 8),
                    Text(
                      'キャラ動画',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B4FA2),
                      ),
                    ),
                  ],
                ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'メッセージを入力...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7B4FA2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
