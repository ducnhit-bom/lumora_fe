import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import 'today_controller.dart';
import 'today_repository.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(todayControllerProvider.notifier).loadToday(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final sessions = state.plan?.sessions ?? const <TodaySession>[];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(LumoraSpacing.lg),
        children: [
          Text('Today', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: LumoraSpacing.sm),
          Text(
            'One calm focus at a time.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: LumoraSpacing.lg),
          if (state.errorMessage != null) ...[
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: LumoraSpacing.md),
          ],
          if (state.isLoading && state.plan == null)
            const LumoraCard(child: Text('Loading your focus for today...'))
          else if (sessions.isEmpty)
            const LumoraCard(child: Text('No focus sessions today.'))
          else ...[
            _HeroFocus(session: sessions.first),
            const SizedBox(height: LumoraSpacing.md),
            for (final session in sessions) ...[
              _SessionCard(session: session, isLoading: state.isLoading),
              const SizedBox(height: LumoraSpacing.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _HeroFocus extends StatelessWidget {
  const _HeroFocus({required this.session});

  final TodaySession session;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('First focus', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: LumoraSpacing.sm),
          Text(session.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: LumoraSpacing.xs),
          Text(_meta(session)),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session, required this.isLoading});

  final TodaySession session;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: LumoraSpacing.xs),
          Text(_meta(session)),
          if (session.note != null) ...[
            const SizedBox(height: LumoraSpacing.sm),
            Text(session.note!),
          ],
          const SizedBox(height: LumoraSpacing.md),
          Wrap(
            spacing: LumoraSpacing.sm,
            runSpacing: LumoraSpacing.sm,
            children: [
              if (session.status == 'scheduled') ...[
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => context.go('/sessions/${session.id}'),
                  child: const Text('Details'),
                ),
                LumoraButton(
                  label: 'Complete',
                  onPressed: isLoading
                      ? null
                      : () async {
                          await ref
                              .read(todayControllerProvider.notifier)
                              .complete(session.id);
                          final reflectionSessionId = ref
                              .read(todayControllerProvider)
                              .openReflectionSessionId;
                          if (context.mounted && reflectionSessionId != null) {
                            context.go('/reflections/session/$reflectionSessionId');
                          }
                        },
                ),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(todayControllerProvider.notifier)
                            .skip(session.id),
                  child: const Text('Skip'),
                ),
              ],
              if (session.status == 'completed')
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(todayControllerProvider.notifier)
                            .undoComplete(session.id),
                  child: const Text('Undo complete'),
                ),
              if (session.status == 'skipped') const Text('Skipped for today'),
            ],
          ),
        ],
      ),
    );
  }
}

String _meta(TodaySession session) {
  final time = session.scheduledTime ?? 'Any time';
  return '$time • ${session.estimatedMinutes} min • ${session.priority}';
}
