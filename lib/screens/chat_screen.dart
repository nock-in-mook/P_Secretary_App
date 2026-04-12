import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/character_switcher.dart';
import '../widgets/character_panel.dart';
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
  final GlobalKey _inputBarKey = GlobalKey();
  final List<Message> _messages = [];
  int _messageCounter = 0;

  // 仮のキャラ切り替え: BW=bookworm / F06=銀髪ボブ
  // 動画ファイル名は拡張子なし。setCharacterVideo側で webm/mp4 を選ぶ。
  static const _characters = {
    'bw': ('bookworm', 'bw_idle'),
    'f06': ('銀髪ボブ', 'f06_idle'),
  };
  String _currentCharId = 'bw';

  void _switchCharacter(String id) {
    if (!_characters.containsKey(id) || id == _currentCharId) return;
    setState(() => _currentCharId = id);
    setCharacterVideo(_characters[id]!.$2);
  }

  void _syncVideoBottom() {
    if (!kIsWeb) return;
    final box = _inputBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    updateCharacterVideoBottom(box.size.height);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVideoBottom());
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
        timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
      ),
      Message(
        id: '2',
        content: 'はい！10時からチームミーティングが入っています。場所はオンライン（Google Meet）です。議題は先週のスプリントレビューですね。',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 13)),
      ),
      Message(
        id: '3',
        content: '了解。あと午後の予定も教えて',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      Message(
        id: '4',
        content: '午後は14時からデザインレビュー、16時から1on1が入っています。デザインレビューの資料はまだ共有されていないようですが、確認しましょうか？',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 11)),
      ),
      Message(
        id: '5',
        content: 'お願い！あと明日のリマインダーもセットして',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Message(
        id: '6',
        content: 'かしこまりました！明日のリマインダーですね。何時に、どんな内容で設定しましょうか？',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      Message(
        id: '7',
        content: '朝9時に「企画書の締め切り」で',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      Message(
        id: '8',
        content: '設定しました！\n\n📋 リマインダー\n・明日 9:00「企画書の締め切り」\n\n当日の朝にお知らせしますね。前日の夜にも一度リマインドしましょうか？',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
      ),
      Message(
        id: '9',
        content: 'うん、前日夜もお願い',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      Message(
        id: '10',
        content: '了解です！今夜20時にもリマインドを入れておきますね。忘れずにお届けします！',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: '11',
        content: 'ありがとう、頼りになるね',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      Message(
        id: '12',
        content: 'えへへ、ありがとうございます！いつでも頼ってくださいね。他に何かありますか？',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ]);
    // 初回ビルド後に最新メッセージまでジャンプ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
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

    // FastAPI経由でGeminiに問い合わせ
    try {
      final response = await ApiService.sendMessage(
        message: text,
        personality: _currentCharId,
      );
      if (!mounted) return;
      setState(() {
        _messageCounter++;
        _messages.add(Message(
          id: 'bot_$_messageCounter',
          content: response.reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageCounter++;
        _messages.add(Message(
          id: 'err_$_messageCounter',
          content: '通信エラーが発生しました: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  /// キャラパネルの高さ分を末尾メッセージの推定行数で埋めて、
  /// 該当するメッセージのindexを返す
  Set<int> get _narrowIndices {
    final screenHeight = MediaQuery.of(context).size.height;
    final charPanelHeight = screenHeight * 0.3;
    // 1行あたりの推定高さ（フォント15 * 行間1.4 + パディング等）
    const lineHeight = 24.0;
    // 吹き出しのパディング・マージン分
    const bubbleOverhead = 30.0;

    final result = <int>{};
    var accumulatedHeight = 0.0;

    for (var i = _messages.length - 1; i >= 0; i--) {
      final text = _messages[i].content;
      // 各行の折り返しを推定（吹き出し内で約16文字/行）
      final lines = text.split('\n').fold<int>(0, (sum, line) {
        return sum + (line.isEmpty ? 1 : (line.length / 16).ceil());
      });
      final msgHeight = lines * lineHeight + bubbleOverhead;

      accumulatedHeight += msgHeight;
      result.add(i);
      if (accumulatedHeight >= charPanelHeight) break;
    }

    return result;
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.face_retouching_natural),
            tooltip: 'キャラ切り替え',
            onSelected: _switchCharacter,
            itemBuilder: (_) => _characters.entries
                .map((e) => PopupMenuItem<String>(
                      value: e.key,
                      child: Row(
                        children: [
                          Icon(
                            e.key == _currentCharId
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: const Color(0xFF7B4FA2),
                          ),
                          const SizedBox(width: 8),
                          Text(e.value.$1),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // チャットメッセージ一覧（キャラパネルと重ねる）
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: 12,
                    // キャラパネルに隠れる分の余白を末尾に確保
                    bottom: MediaQuery.of(context).size.height * 0.3 + 16,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(
                      message: _messages[index],
                      narrowForCharacter: _narrowIndices.contains(index),
                    );
                  },
                ),
                // キャラパネル（右下固定）
                Positioned(
                  right: 0,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Builder(
                      builder: (context) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final charHeight = screenHeight * 0.3;
                        final charWidth = charHeight * 0.65;
                        return CharacterPanel(
                          width: charWidth,
                          height: charHeight,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 入力欄
          _buildInputBar(),
        ],
      ),
    ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      key: _inputBarKey,
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
