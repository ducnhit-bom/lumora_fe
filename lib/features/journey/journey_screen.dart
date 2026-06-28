import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import 'journey_controller.dart';
import 'journey_repository.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  final _journeyTitleController = TextEditingController(text: 'A calm week');
  final _sessionTitleController = TextEditingController();
  final _sessionNoteController = TextEditingController();
  final _sessionDurationController = TextEditingController(text: '45');
  String _category = 'work';
  String _priority = 'high';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(journeyControllerProvider.notifier).loadCurrent(),
    );
  }

  @override
  void dispose() {
    _journeyTitleController.dispose();
    _sessionTitleController.dispose();
    _sessionNoteController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journeyControllerProvider);
    final journey = state.journey;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(LumoraSpacing.lg),
        children: [
          Text(
            'Weekly Journey',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: LumoraSpacing.sm),
          Text(
            'Design a gentle plan for the week ahead.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: LumoraSpacing.lg),
          if (state.errorMessage != null) ...[
            _InlineMessage(text: state.errorMessage!, isError: true),
            const SizedBox(height: LumoraSpacing.md),
          ],
          if (state.acceptedMessage != null) ...[
            _InlineMessage(text: state.acceptedMessage!),
            const SizedBox(height: LumoraSpacing.md),
          ],
          if (journey == null)
            _CreateJourneyCard(
              controller: _journeyTitleController,
              isLoading: state.isLoading,
            )
          else ...[
            _JourneySummary(journey: journey),
            const SizedBox(height: LumoraSpacing.md),
            _AddSessionCard(
              titleController: _sessionTitleController,
              noteController: _sessionNoteController,
              durationController: _sessionDurationController,
              category: _category,
              priority: _priority,
              isLoading: state.isLoading,
              onCategoryChanged: (value) => setState(() => _category = value),
              onPriorityChanged: (value) => setState(() => _priority = value),
              onAdded: _clearSessionForm,
            ),
            const SizedBox(height: LumoraSpacing.md),
            _SessionPreview(sessions: journey.sessions),
            const SizedBox(height: LumoraSpacing.md),
            LumoraButton(
              label: state.isLoading ? 'Creating...' : 'Create AI Journey',
              onPressed: journey.sessions.isEmpty || state.isLoading
                  ? null
                  : () =>
                        ref.read(journeyControllerProvider.notifier).suggest(),
            ),
          ],
          if (state.suggestion != null) ...[
            const SizedBox(height: LumoraSpacing.md),
            _SuggestionPreview(
              suggestion: state.suggestion!,
              sessions: journey?.sessions ?? const [],
            ),
            const SizedBox(height: LumoraSpacing.md),
            LumoraButton(
              label: state.isLoading ? 'Accepting...' : 'Accept journey',
              onPressed: state.isLoading
                  ? null
                  : () => ref
                        .read(journeyControllerProvider.notifier)
                        .acceptSuggestion(),
            ),
          ],
          if (state.acceptedMessage != null) ...[
            const SizedBox(height: LumoraSpacing.md),
            OutlinedButton(
              onPressed: () => context.go('/today'),
              child: const Text('Return to Today'),
            ),
          ],
        ],
      ),
    );
  }

  void _clearSessionForm() {
    _sessionTitleController.clear();
    _sessionNoteController.clear();
    _sessionDurationController.text = '45';
  }
}

class _CreateJourneyCard extends ConsumerWidget {
  const _CreateJourneyCard({required this.controller, required this.isLoading});

  final TextEditingController controller;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with a weekly intention',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LumoraSpacing.md),
          TextField(
            key: const Key('journey-title-field'),
            controller: controller,
            decoration: const InputDecoration(labelText: 'Journey title'),
          ),
          const SizedBox(height: LumoraSpacing.md),
          LumoraButton(
            label: isLoading ? 'Creating...' : 'Create journey',
            onPressed: isLoading
                ? null
                : () => ref
                      .read(journeyControllerProvider.notifier)
                      .createDraft(title: controller.text),
          ),
        ],
      ),
    );
  }
}

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(journey.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: LumoraSpacing.xs),
          Text('${journey.sessions.length} focus sessions • ${journey.status}'),
        ],
      ),
    );
  }
}

class _AddSessionCard extends ConsumerWidget {
  const _AddSessionCard({
    required this.titleController,
    required this.noteController,
    required this.durationController,
    required this.category,
    required this.priority,
    required this.isLoading,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onAdded,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final TextEditingController durationController;
  final String category;
  final String priority;
  final bool isLoading;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a focus session',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LumoraSpacing.md),
          TextField(
            key: const Key('session-title-field'),
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Focus title'),
          ),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(labelText: 'Optional note'),
          ),
          TextField(
            key: const Key('session-duration-field'),
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Estimated minutes'),
          ),
          const SizedBox(height: LumoraSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'work', child: Text('Work')),
              DropdownMenuItem(value: 'personal', child: Text('Personal')),
              DropdownMenuItem(value: 'growth', child: Text('Growth')),
            ],
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'low', child: Text('Low')),
            ],
            onChanged: (value) {
              if (value != null) onPriorityChanged(value);
            },
          ),
          const SizedBox(height: LumoraSpacing.md),
          LumoraButton(
            label: isLoading ? 'Adding...' : 'Add focus',
            onPressed: isLoading ? null : () => _add(ref),
          ),
        ],
      ),
    );
  }

  Future<void> _add(WidgetRef ref) async {
    await ref
        .read(journeyControllerProvider.notifier)
        .addSession(
          title: titleController.text,
          note: noteController.text,
          category: category,
          priority: priority,
          estimatedMinutes: int.tryParse(durationController.text) ?? 0,
        );
    onAdded();
  }
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.sessions});

  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const LumoraCard(
        child: Text(
          'Add one meaningful focus session to unlock your weekly suggestion.',
        ),
      );
    }
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus preview', style: Theme.of(context).textTheme.titleMedium),
          for (final session in sessions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(session.title),
              subtitle: Text(
                '${session.priority} • ${session.estimatedMinutes} min',
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionPreview extends StatelessWidget {
  const _SuggestionPreview({required this.suggestion, required this.sessions});

  final SuggestedJourney suggestion;
  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested week',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LumoraSpacing.sm),
          for (final day in suggestion.days) ...[
            Text(day.date, style: Theme.of(context).textTheme.titleSmall),
            for (final item in day.sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${item.suggestedTime} • ${_sessionTitle(item.sessionId)}',
                ),
                subtitle: Text(item.reason),
              ),
          ],
        ],
      ),
    );
  }

  String _sessionTitle(String sessionId) {
    for (final session in sessions) {
      if (session.id == sessionId) return session.title;
    }
    return 'Focus session';
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
