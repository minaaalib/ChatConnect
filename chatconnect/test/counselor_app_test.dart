import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatconnect/main_counselor.dart';
import 'package:chatconnect/services/mock_auth_service.dart';

void main() {
  // Empty Supabase settings = offline demo mode.
  setUp(() => dotenv.loadFromString(isOptional: true));

  testWidgets('Counselor app opens on its own sign-in, then the inbox', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CounselorApp());
    await tester.pumpAndSettle();

    expect(find.text('Counselor Sign In'), findsOneWidget);
    // No student-only things on the counselor sign-in.
    expect(find.text('Need help? Chat with Kai'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'staff@wvsu.edu.ph');
    await tester.enterText(find.byType(TextField).at(1), 'demo');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Step 2: staff school ID. The inbox stays locked until it's right.
    expect(find.text('Counselor Sign In'), findsNothing);
    expect(find.text('Enter your staff school ID'), findsOneWidget);
    expect(find.text('GUIDANCE OFFICE'), findsNothing);

    await tester.enterText(find.byType(TextField), '111111');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(
      find.text('Staff school ID does not match. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('GUIDANCE OFFICE'), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      MockAuthService.demoStaffSchoolId,
    );
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your staff school ID'), findsNothing);
    expect(find.text('GUIDANCE OFFICE'), findsOneWidget); // sidebar
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Confirming an appointment creates the (demo) Google Meet.
    await tester.tap(find.textContaining('Appointments ('));
    await tester.pumpAndSettle();
    expect(find.text('Join Google Meet'), findsNothing);

    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm & create Meet'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmed with a demo Meet link.'), findsOneWidget);
    // Confirmed items move out of the pending list; show all to see it.
    final showAll = find.textContaining('Show');
    if (showAll.evaluate().isNotEmpty) {
      await tester.tap(showAll.first);
      await tester.pumpAndSettle();
    }
    expect(find.text('Join Google Meet'), findsOneWidget);
  });
}
