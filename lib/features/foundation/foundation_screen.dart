import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_card.dart';

class FoundationScreen extends StatelessWidget {
  const FoundationScreen({
    required this.title,
    required this.headline,
    super.key,
  });

  final String title;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(LumoraSpacing.lg),
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: LumoraSpacing.lg),
          LumoraCard(
            child: Text(
              headline,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
