import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import 'review_controller.dart';
import 'review_repository.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reviewControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    final review = state.review;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(LumoraSpacing.lg),
        children: [
          Text('Weekly Review', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: LumoraSpacing.sm),
          Text(
            'A gentle read on your week, without turning progress into pressure.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: LumoraSpacing.lg),
          if (state.isLoading)
            const LumoraCard(child: Text('Reading your week...'))
          else if (state.errorMessage != null)
            LumoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: LumoraSpacing.md),
                  LumoraButton(
                    label: 'Try again',
                    onPressed: () => ref.read(reviewControllerProvider.notifier).load(),
                  ),
                ],
              ),
            )
          else if (state.hasNoJourney)
            LumoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No weekly journey yet.', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: LumoraSpacing.sm),
                  const Text('Plan a gentle week first, then Lumora can reflect it back to you.'),
                  const SizedBox(height: LumoraSpacing.md),
                  LumoraButton(label: 'Plan this week', onPressed: () => context.go('/journey')),
                ],
              ),
            )
          else if (review != null) ...[
            _SummaryGrid(review: review),
            const SizedBox(height: LumoraSpacing.md),
            _InsightCard(title: 'Insight', text: review.insight.text),
            const SizedBox(height: LumoraSpacing.md),
            _InsightCard(title: 'Recommendation', text: review.recommendation),
            const SizedBox(height: LumoraSpacing.md),
            LumoraButton(label: 'Plan next week', onPressed: () => context.go('/journey')),
          ],
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.review});

  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(label: 'Completed', value: '${review.sessionsCompleted}'),
            ),
            const SizedBox(width: LumoraSpacing.sm),
            Expanded(
              child: _SummaryCard(label: 'Reflections', value: '${review.reflectionCount}'),
            ),
          ],
        ),
        const SizedBox(height: LumoraSpacing.sm),
        _SummaryCard(label: 'Mood signal', value: review.moodSummary.strongest),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: LumoraSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: LumoraSpacing.sm),
          Text(text),
        ],
      ),
    );
  }
}
