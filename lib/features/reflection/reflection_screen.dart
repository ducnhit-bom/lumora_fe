import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import 'reflection_controller.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(reflectionControllerProvider.notifier).load(widget.sessionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reflection')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LumoraSpacing.lg),
          children: [
            Text(
              'Capture one useful signal before moving on.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: LumoraSpacing.lg),
            LumoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isLoading && state.question == null)
                    const Text('Loading your reflection prompt...')
                  else ...[
                    Text(
                      state.question ?? 'What helped you make progress?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: LumoraSpacing.md),
                    TextField(
                      key: const Key('reflection-content-field'),
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 500,
                      onChanged: ref
                          .read(reflectionControllerProvider.notifier)
                          .updateContent,
                      decoration: const InputDecoration(
                        labelText: 'Short reflection',
                        hintText: 'One sentence is enough.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: LumoraSpacing.sm),
                    Text('Mood', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: LumoraSpacing.xs),
                    const Wrap(
                      spacing: LumoraSpacing.sm,
                      children: [
                        _MoodChip(label: 'Energized', value: 'energized'),
                        _MoodChip(label: 'Balanced', value: 'balanced'),
                        _MoodChip(label: 'Challenged', value: 'challenged'),
                      ],
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: LumoraSpacing.md),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: LumoraSpacing.lg),
                    Wrap(
                      spacing: LumoraSpacing.sm,
                      runSpacing: LumoraSpacing.sm,
                      children: [
                        LumoraButton(
                          label: state.isLoading ? 'Saving...' : 'Save reflection',
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(reflectionControllerProvider.notifier)
                                      .save();
                                  final saved = ref
                                      .read(reflectionControllerProvider)
                                      .savedReflection;
                                  if (context.mounted && saved != null) {
                                    context.go('/today');
                                  }
                                },
                        ),
                        OutlinedButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  ref
                                      .read(reflectionControllerProvider.notifier)
                                      .skip();
                                  context.go('/today');
                                },
                          child: const Text('Skip reflection'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChip extends ConsumerWidget {
  const _MoodChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reflectionControllerProvider).mood == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => ref
          .read(reflectionControllerProvider.notifier)
          .selectMood(value),
    );
  }
}
