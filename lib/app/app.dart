import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class LumoraApp extends StatelessWidget {
  const LumoraApp({
    this.initialLocation = '/today',
    super.key,
  });

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumora',
      debugShowCheckedModeBanner: false,
      theme: LumoraTheme.light,
      routerConfig: createAppRouter(initialLocation: initialLocation),
    );
  }
}
