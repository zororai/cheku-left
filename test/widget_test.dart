import 'package:flutter_test/flutter_test.dart';
import 'package:pos/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ChekuLeftApp());
    expect(find.text('CHEKU LEFT'), findsOneWidget);
  });
}
