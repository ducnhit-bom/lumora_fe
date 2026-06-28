import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/app/app.dart';
import 'package:lumora_fe/features/auth/auth_controller.dart';

void main() {
  testWidgets('redirects unauthenticated users to auth', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

    expect(find.text('Welcome to Lumora'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('shows Lumora foundation shell tabs for authenticated user', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith((ref) => AuthController.signedInForTest())],
        child: const LumoraApp(),
      ),
    );

    expect(find.text('Lumora'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Journey'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Plan a meaningful week, then return to one calm focus at a time.'), findsOneWidget);
  });

  testWidgets('navigates between foundation tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith((ref) => AuthController.signedInForTest())],
        child: const LumoraApp(),
      ),
    );

    await tester.tap(find.text('Journey').last);
    await tester.pumpAndSettle();

    expect(find.text('Weekly Journey'), findsOneWidget);
    expect(find.text('Mock mode keeps planning available while the API catches up.'), findsOneWidget);
  });

  testWidgets('shows auth placeholder route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp(initialLocation: '/auth')));

    expect(find.text('Welcome to Lumora'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('mock login enters Today and logout returns to auth', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

    await tester.enterText(find.byType(EditableText).at(0), 'linh@example.com');
    await tester.enterText(find.byType(EditableText).at(1), 'secret123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Lumora'), findsOneWidget);
  });
}
