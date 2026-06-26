import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_card.dart';

class AuthPlaceholderScreen extends StatelessWidget {
  const AuthPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LumoraSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Lumora',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: LumoraSpacing.lg),
              LumoraCard(
                child: Text(
                  'Email/password sign in arrives in Phase 2.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
