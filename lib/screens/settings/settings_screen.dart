import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/language_selector.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final ctrl     = ref.read(settingsControllerProvider.notifier);
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Languages ────────────────────────────────────────────────────
          const _SectionHeader(title: 'Languages'),
          _LangRow(
            label: 'I speak',
            langCode: settings.iSpeakLang,
            onChanged: ctrl.updateISpeakLang,
          ),
          _LangRow(
            label: 'I\'m learning',
            langCode: settings.imLearningLang,
            onChanged: ctrl.updateImLearningLang,
          ),

          // ── Appearance ───────────────────────────────────────────────────
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeName(settings.themeMode)),
            leading: const Icon(Icons.palette_outlined),
            onTap: () => _showThemePicker(context, settings.themeMode, ctrl.updateTheme),
          ),

          // ── Learning ─────────────────────────────────────────────────────
          const _SectionHeader(title: 'Learning'),
          ListTile(
            title: const Text('Daily Goal'),
            subtitle: Text('${settings.dailyGoal} reviews per day'),
            leading: const Icon(Icons.flag_outlined),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: settings.dailyGoal > 1
                      ? () => ctrl.updateDailyGoal(settings.dailyGoal - 5)
                      : null,
                ),
                Text(
                  '${settings.dailyGoal}',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => ctrl.updateDailyGoal(settings.dailyGoal + 5),
                ),
              ],
            ),
          ),

          // ── Notifications ────────────────────────────────────────────────
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: Text(settings.pushEnabled ? 'Enabled' : 'Disabled'),
            secondary: const Icon(Icons.notifications_outlined),
            value: settings.pushEnabled,
            onChanged: (_) => ctrl.togglePush(),
          ),
          if (settings.pushEnabled) ...[
            ListTile(
              title: const Text('Quiet Hours'),
              subtitle: Text(
                '${_fmtHour(settings.quietHoursFrom)} – ${_fmtHour(settings.quietHoursTo)}',
              ),
              leading: const Icon(Icons.bedtime_outlined),
              onTap: () => _showQuietHoursPicker(
                context,
                settings.quietHoursFrom,
                settings.quietHoursTo,
                ctrl.updateQuietHours,
              ),
            ),
            ListTile(
              title: const Text('Frequency'),
              subtitle: Text(_freqLabel(settings.frequency)),
              leading: const Icon(Icons.tune_outlined),
              onTap: () => _showFreqPicker(context, settings.frequency, ctrl.updateFrequency),
            ),
          ],

          // ── Data ─────────────────────────────────────────────────────────
          const _SectionHeader(title: 'Data'),
          ListTile(
            title: const Text('Export Deck'),
            leading: const Icon(Icons.upload_outlined),
            onTap: () => ctrl.exportDeck(context),
          ),
          ListTile(
            title: const Text('Import Deck'),
            leading: const Icon(Icons.download_outlined),
            onTap: () => ctrl.importDeck(context),
          ),
          ListTile(
            title: Text(
              'Clear All Words',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            leading: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.error),
            onTap: () => _confirmClear(context, ctrl.clearAllWords),
          ),

          // ── Account ──────────────────────────────────────────────────────
          const _SectionHeader(title: 'Account'),
          ListTile(
            title: Text(
              'Sign Out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            leading: Icon(Icons.logout_rounded,
                color: theme.colorScheme.error),
            onTap: ctrl.signOut,
          ),

          // ── About ────────────────────────────────────────────────────────
          const _SectionHeader(title: 'About'),
          const ListTile(
            title: Text('WordDeck'),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light  => 'Light',
        ThemeMode.dark   => 'Dark',
      };

  String _fmtHour(int h) => '${h.toString().padLeft(2, '0')}:00';

  String _freqLabel(String f) => switch (f) {
        'low'    => 'Low (1–2×/day)',
        'high'   => 'High (5+×/day)',
        _        => 'Medium (3–4×/day)',
      };

  void _showThemePicker(
    BuildContext context,
    ThemeMode current,
    ValueChanged<ThemeMode> onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Choose Theme')),
            for (final mode in ThemeMode.values)
              ListTile(
                title: Text(_themeLabelFor(mode)),
                trailing: mode == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  onChanged(mode);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _themeLabelFor(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System default',
        ThemeMode.light  => 'Light',
        ThemeMode.dark   => 'Dark',
      };

  void _showFreqPicker(
    BuildContext context,
    String current,
    ValueChanged<String> onChanged,
  ) {
    const options = [
      ('low', 'Low (1–2×/day)'),
      ('medium', 'Medium (3–4×/day)'),
      ('high', 'High (5+×/day)'),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Notification Frequency')),
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                trailing: value == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  onChanged(value);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showQuietHoursPicker(
    BuildContext context,
    int fromHour,
    int toHour,
    void Function(int, int) onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _QuietHoursPicker(
        fromHour: fromHour,
        toHour: toHour,
        onChanged: onChanged,
      ),
    );
  }

  void _confirmClear(BuildContext context, VoidCallback onConfirm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Words?'),
        content: const Text(
            'This permanently deletes all your flashcards. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  final String label;
  final String langCode;
  final ValueChanged<String> onChanged;

  const _LangRow({
    required this.label,
    required this.langCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.language_outlined),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => LanguagePickerSheet(
          current: langCode,
          onSelected: (code) {
            onChanged(code);
            Navigator.of(context).pop();
          },
        ),
      ),
      trailing: _LangChip(langCode: langCode),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String langCode;
  const _LangChip({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // import AppConstants to get flag + name
    return Chip(
      label: Text(langCode.toUpperCase()),
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      side: BorderSide.none,
    );
  }
}

class _QuietHoursPicker extends StatefulWidget {
  final int fromHour;
  final int toHour;
  final void Function(int, int) onChanged;

  const _QuietHoursPicker({
    required this.fromHour,
    required this.toHour,
    required this.onChanged,
  });

  @override
  State<_QuietHoursPicker> createState() => _QuietHoursPickerState();
}

class _QuietHoursPickerState extends State<_QuietHoursPicker> {
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    _from = widget.fromHour;
    _to   = widget.toHour;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quiet Hours', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'No notifications between ${_fmt(_from)} and ${_fmt(_to)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('From: ${_fmt(_from)}', style: theme.textTheme.labelLarge),
          Slider(
            value: _from.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            label: _fmt(_from),
            onChanged: (v) => setState(() => _from = v.round()),
          ),
          const SizedBox(height: 8),
          Text('To: ${_fmt(_to)}', style: theme.textTheme.labelLarge),
          Slider(
            value: _to.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            label: _fmt(_to),
            onChanged: (v) => setState(() => _to = v.round()),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  widget.onChanged(_from, _to);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';
}
