import 'package:flutter_test/flutter_test.dart';
import 'package:cube_puzzle/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CubePuzzleApp());
    expect(find.byType(CubePuzzleApp), findsOneWidget);
  });
}
