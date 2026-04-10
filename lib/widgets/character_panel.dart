import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


/// 右下キャラパネル — プラットフォームに応じた表示
class CharacterPanel extends StatelessWidget {
  final double width;
  final double height;

  const CharacterPanel({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web版: index.htmlのvideoタグで表示するため、Flutter側は透明スペーサー
      return SizedBox(width: width, height: height);
    }
    // ネイティブ版（iOS/Android）: プレースホルダー（後で実装）
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5F5).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7B4FA2).withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 48, color: Color(0xFF7B4FA2)),
          SizedBox(height: 8),
          Text(
            'キャラ動画',
            style: TextStyle(fontSize: 12, color: Color(0xFF7B4FA2)),
          ),
        ],
      ),
    );
  }
}
