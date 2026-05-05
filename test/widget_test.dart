import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineflix/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CineFlixApp()));
    await tester.pump();

    expect(find.text('Tonight\'s Picks'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
