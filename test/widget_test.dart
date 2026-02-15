import 'package:flutter_test/flutter_test.dart';
import 'package:cheku_left/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ChekuLeftApp());
    expect(find.text('CHEKU LEFT'), findsOneWidget);
  });
}
