import 'package:flutter_test/flutter_test.dart';
import 'package:cineflix/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CineFlixApp());
    expect(find.text('CineFlix'), findsOneWidget);
  });
}
