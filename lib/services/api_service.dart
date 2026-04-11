import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// FastAPIバックエンドとの通信サービス
class ApiService {
  // APIサーバーのポート
  static const _apiPort = 8888;

  static String get _baseUrl {
    if (kIsWeb) {
      // Webの場合、現在のホスト（localhostやTailscale IP）のAPIポートを使う
      // Uri.base はブラウザの現在のURLを返す
      final host = Uri.base.host;
      return 'http://$host:$_apiPort/api/v1';
    }
    // モバイルの場合（Androidエミュレータは10.0.2.2）
    return 'http://10.0.2.2:$_apiPort/api/v1';
  }

  /// チャットメッセージを送信し、秘書の返答を取得
  static Future<ChatApiResponse> sendMessage({
    required String message,
    String userId = 'default',
    String personality = 'bw',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'message': message,
        'personality': personality,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return ChatApiResponse(
        reply: data['reply'] as String,
        actions: List<Map<String, dynamic>>.from(data['actions'] ?? []),
      );
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }
}

class ChatApiResponse {
  final String reply;
  final List<Map<String, dynamic>> actions;

  ChatApiResponse({required this.reply, required this.actions});
}
