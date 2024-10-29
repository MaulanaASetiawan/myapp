import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';
import 'package:myapp/notification_service.dart';

void main() {
  testWidgets('Subscription form test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final notificationService = NotificationService();

    await tester.pumpWidget(MyApp(notificationService: notificationService));

    // Verify that we start on the subscription page.
    expect(find.text('Leakage Detector - Subscribe'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter a topic and tap subscribe.
    await tester.enterText(find.byType(TextField), 'test/topic');
    await tester.tap(find.text('Subscribe'));
    await tester.pump();

    // Verify the topic has been added.
    expect(find.text('test/topic'), findsOneWidget);
  });

  testWidgets('Silence Notification button test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final notificationService = NotificationService();

    await tester.pumpWidget(MyApp(notificationService: notificationService));

    // Tap the silence notification button.
    await tester.tap(find.byIcon(Icons.notifications_off));
    await tester.pump();

    // Here you can add further assertions to verify the expected behavior
    // when the silence notification button is pressed.
  });
}
