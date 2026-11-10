import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatconnect/main.dart';

void main() {
  // Empty Supabase settings = offline demo mode.
  setUp(() => dotenv.loadFromString(isOptional: true));

  testWidgets('App boots to the onboarding screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChatConnectApp());
    await tester.pumpAndSettle();

    expect(find.text('Start Your Wellbeing Journey'), findsOneWidget);
  });
}
