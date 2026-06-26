import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/app/app.dart';

void main() {
  testWidgets('shows Lumora foundation shell tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

    expect(find.text('Lumora'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Journey'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Plan a meaningful week, then return to one calm focus at a time.'), findsOneWidget);
  });

  testWidgets('navigates between foundation tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

    await tester.tap(find.text('Journey').last);
    await tester.pumpAndSettle();

    expect(find.text('Weekly Journey'), findsOneWidget);
    expect(find.text('Mock mode keeps planning available while the API catches up.'), findsOneWidget);
  });

  testWidgets('shows auth placeholder route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp(initialLocation: '/auth')));

    expect(find.text('Welcome to Lumora'), findsOneWidget);
    expect(find.text('Email/password sign in arrives in Phase 2.'), findsOneWidget);
  });
}
