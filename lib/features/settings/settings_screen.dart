import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import '../auth/auth_controller.dart';
import 'settings_controller.dart';
import 'settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(() => ref.read(settingsControllerProvider.notifier).load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LumoraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: LumoraSpacing.lg),
          _ProfileCard(email: auth.session?.email),
          const SizedBox(height: LumoraSpacing.md),
          if (state.isLoading && state.settings == null)
            const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null && state.settings == null)
            Padding(
              padding: const EdgeInsets.all(LumoraSpacing.md),
              child: Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
              ),
            )
          else if (state.settings != null) ...[
            _PreferenceCard(
              settings: state.settings!,
              onChanged: (updated) => controller.save(updated),
            ),
            if (state.saved)
              Padding(
                padding: const EdgeInsets.only(top: LumoraSpacing.sm),
                child: Text(
                  'Saved',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LumoraColors.champagne,
                  ),
                ),
              ),
          ],
          const SizedBox(height: LumoraSpacing.xl),
          LumoraButton(
            label: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    ),
  );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: LumoraSpacing.xs),
          Text(
            email ?? 'No active session',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.settings, required this.onChanged});

  final UserSettings settings;
  final ValueChanged<UserSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: LumoraSpacing.md),
          _buildToggle(
            context,
            'Auto-open reflection',
            'Automatically open reflection after completing a session.',
            settings.autoOpenReflection,
            (v) => onChanged(settings.copyWith(autoOpenReflection: v)),
          ),
          const Divider(height: LumoraSpacing.lg),
          _buildTimePicker(
            context,
            'Preferred focus time',
            settings.preferredFocusTime,
          ),
          const Divider(height: LumoraSpacing.lg),
          _buildStepper(
            context,
            'Max sessions per day',
            settings.maxSessionsPerDay,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LumoraColors.ink,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LumoraColors.muted,
              )),
            ],
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: LumoraColors.champagne,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LumoraColors.ink,
          )),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: LumoraColors.muted,
        )),
        const SizedBox(width: LumoraSpacing.xs),
        IconButton(
          icon: const Icon(Icons.access_time, color: LumoraColors.muted),
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _parseTime(value),
            );
            if (time != null) {
              final formatted =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              onChanged(settings.copyWith(preferredFocusTime: formatted));
            }
          },
        ),
      ],
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Widget _buildStepper(
    BuildContext context,
    String title,
    int value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LumoraColors.ink,
          )),
        ),
        IconButton(
          icon: const Icon(Icons.remove, color: LumoraColors.muted),
          onPressed: value > 1
              ? () => onChanged(settings.copyWith(maxSessionsPerDay: value - 1))
              : null,
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LumoraColors.ink,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: LumoraColors.muted),
          onPressed: value < 20
              ? () => onChanged(settings.copyWith(maxSessionsPerDay: value + 1))
              : null,
        ),
      ],
    );
  }
}
