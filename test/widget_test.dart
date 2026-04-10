import 'package:flutter_test/flutter_test.dart';
import 'package:p_secretary_app/main.dart';

void main() {
  testWidgets('アプリが起動する', (WidgetTester tester) async {
    await tester.pumpWidget(const PSecretaryApp());
    expect(find.text('秘書'), findsOneWidget);
  });
}
