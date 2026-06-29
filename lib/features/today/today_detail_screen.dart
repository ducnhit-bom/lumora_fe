import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import 'today_controller.dart';

class TodayDetailScreen extends ConsumerStatefulWidget {
  const TodayDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<TodayDetailScreen> createState() => _TodayDetailScreenState();
}

class _TodayDetailScreenState extends ConsumerState<TodayDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(todayControllerProvider.notifier)
          .loadDetail(widget.sessionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final session = state.selectedSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LumoraSpacing.lg),
          children: [
            if (state.errorMessage != null)
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (state.isLoading && session == null)
              const LumoraCard(child: Text('Loading focus detail...'))
            else if (session != null)
              LumoraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: LumoraSpacing.sm),
                    Text(
                      '${session.scheduledTime ?? 'Any time'} • ${session.estimatedMinutes} min • ${session.priority}',
                    ),
                    if (session.note != null) ...[
                      const SizedBox(height: LumoraSpacing.md),
                      Text(session.note!),
                    ],
                    const SizedBox(height: LumoraSpacing.lg),
                    if (session.status == 'scheduled')
                      LumoraButton(
                        label: 'Complete',
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(todayControllerProvider.notifier)
                                    .complete(session.id);
                                final reflectionSessionId = ref
                                    .read(todayControllerProvider)
                                    .openReflectionSessionId;
                                if (context.mounted &&
                                    reflectionSessionId != null) {
                                  context.go(
                                    '/reflections/session/$reflectionSessionId',
                                  );
                                }
                              },
                      ),
                    if (session.status == 'completed')
                      OutlinedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => ref
                                  .read(todayControllerProvider.notifier)
                                  .undoComplete(session.id),
                        child: const Text('Undo complete'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
