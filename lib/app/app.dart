import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import 'router.dart';
import 'theme.dart';

class LumoraApp extends ConsumerWidget {
  const LumoraApp({
    this.initialLocation = '/today',
    super.key,
  });

  final String initialLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return MaterialApp.router(
      title: 'Lumora',
      debugShowCheckedModeBanner: false,
      theme: LumoraTheme.light,
      routerConfig: createAppRouter(
        initialLocation: initialLocation,
        isAuthenticated: auth.isAuthenticated,
      ),
    );
  }
}
