import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/collections/collection_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../widgets/create_space_dialog.dart';
import '../../widgets/language_selector.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + safeBottom),
        children: [
          // ── My Spaces ──────────────────────────────────────────────────
          const _SectionLabel(title: 'My Spaces'),
          const SizedBox(height: 8),
          const _SpacesCard(),

          const SizedBox(height: 20),

          // ── Collections ────────────────────────────────────────────────
          const _SectionLabel(title: 'Collections'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final collections =
                      ref.watch(collectionProvider).collections;
                  return _SettingsRow(
                    icon: Icons.folder_outlined,
                    label: 'Manage Collections',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${collections.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.textDim),
                      ],
                    ),
                    onTap: () => context.push('/collections/manage'),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Languages ──────────────────────────────────────────────────
          const _SectionLabel(title: 'Languages'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _LangRow(
                label: 'I speak',
                langCode: settings.iSpeakLang,
                onChanged: ctrl.updateISpeakLang,
              ),
              const _Divider(),
              _LangRow(
                label: 'I\'m learning',
                langCode: settings.imLearningLang,
                onChanged: ctrl.updateImLearningLang,
              ),
              const _Divider(),
              _SettingsRow(
                icon: Icons.translate_rounded,
                label: 'Interface Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'English',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textDim),
                  ],
                ),
                onTap: () {
                  // TODO: interface language picker
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Appearance ─────────────────────────────────────────────────
          const _SectionLabel(title: 'Appearance'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.palette_outlined,
                label: 'Theme',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _themeName(settings.themeMode),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textDim),
                  ],
                ),
                onTap: () => _showThemePicker(
                    context, settings.themeMode, ctrl.updateTheme),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Learning ───────────────────────────────────────────────────
          const _SectionLabel(title: 'Learning'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _DailyGoalRow(
                value: settings.dailyGoal,
                onDecrement: settings.dailyGoal > 5
                    ? () => ctrl.updateDailyGoal(settings.dailyGoal - 5)
                    : null,
                onIncrement: () =>
                    ctrl.updateDailyGoal(settings.dailyGoal + 5),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Notifications ──────────────────────────────────────────────
          const _SectionLabel(title: 'Notifications'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _ToggleRow(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                value: settings.pushEnabled,
                onChanged: (_) => ctrl.togglePush(),
              ),
              if (settings.pushEnabled) ...[
                const _Divider(),
                _SettingsRow(
                  icon: Icons.bedtime_outlined,
                  label: 'Quiet Hours',
                  trailing: Text(
                    '${_fmtHour(settings.quietHoursFrom)} – ${_fmtHour(settings.quietHoursTo)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  onTap: () => _showQuietHoursPicker(
                    context,
                    settings.quietHoursFrom,
                    settings.quietHoursTo,
                    ctrl.updateQuietHours,
                  ),
                ),
                const _Divider(),
                _SettingsRow(
                  icon: Icons.tune_outlined,
                  label: 'Frequency',
                  trailing: Text(
                    _freqLabel(settings.frequency),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  onTap: () => _showFreqPicker(
                      context, settings.frequency, ctrl.updateFrequency),
                ),
              ],
            ],
          ),

          const SizedBox(height: 32),

          // ── Data / Account / About — flat rows, no card ────────────────
          _FlatRow(
            icon: Icons.upload_outlined,
            label: 'Export Vocabulary',
            onTap: () => ctrl.exportDeck(context),
          ),
          _FlatRow(
            icon: Icons.download_outlined,
            label: 'Import Vocabulary',
            onTap: () => ctrl.importDeck(context),
          ),
          const SizedBox(height: 8),
          _FlatRow(
            icon: Icons.delete_outline_rounded,
            label: 'Clear All Words',
            color: AppColors.red,
            onTap: () => _confirmClear(context, ctrl.clearAllWords),
          ),
          _FlatRow(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: AppColors.red,
            onTap: ctrl.signOut,
          ),

          const SizedBox(height: 24),

          // Version
          const Center(
            child: Text(
              'WordDeck v2.1.1',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _themeName(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static String _fmtHour(int h) => '${h.toString().padLeft(2, '0')}:00';

  static String _freqLabel(String f) => switch (f) {
        'low' => 'Low',
        'high' => 'High',
        _ => 'Medium',
      };

  void _showThemePicker(
    BuildContext context,
    ThemeMode current,
    ValueChanged<ThemeMode> onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final mode in ThemeMode.values)
                _SheetOption(
                  label: _themeLabel(mode),
                  selected: mode == current,
                  onTap: () {
                    onChanged(mode);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  void _showFreqPicker(
    BuildContext context,
    String current,
    ValueChanged<String> onChanged,
  ) {
    const options = [
      ('low', 'Low (1-2x/day)'),
      ('medium', 'Medium (3-4x/day)'),
      ('high', 'High (5+/day)'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notification Frequency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final (value, label) in options)
                _SheetOption(
                  label: label,
                  selected: value == current,
                  onTap: () {
                    onChanged(value);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
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
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Words?',
            style: TextStyle(color: AppColors.text)),
        content: const Text(
          'This permanently deletes all your flashcards. This cannot be undone.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
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

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDim,
        ),
      ),
    );
  }
}

// ── Card container ─────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ── Divider inside card ────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 0.5,
        color: AppColors.surface3,
      ),
    );
  }
}

// ── Generic row inside card ────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.text,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Toggle row inside card ─────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 6, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: AppColors.text),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ── Language row inside card ───────────────────────────────────────────────

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
    final flag = AppConstants.flagForCode(langCode);
    final name = AppConstants.languageDisplayName(langCode);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => LanguagePickerSheet(
          current: langCode,
          onSelected: (code) {
            onChanged(code);
            Navigator.of(context).pop();
          },
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.language_outlined,
                size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, color: AppColors.text),
              ),
            ),
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}

// ── Daily goal row ─────────────────────────────────────────────────────────

class _DailyGoalRow extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _DailyGoalRow({
    required this.value,
    this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined,
              size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal',
                  style: TextStyle(fontSize: 15, color: AppColors.text),
                ),
                SizedBox(height: 2),
                Text(
                  'Reviews per day',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface2 : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.surface3 : AppColors.surface2,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.text : AppColors.textDim,
        ),
      ),
    );
  }
}

// ── Flat row (no card, for bottom section) ─────────────────────────────────

class _FlatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _FlatRow({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet option row ───────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: selected ? AppColors.accentDim : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: selected ? AppColors.accent : AppColors.text,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

// ── Spaces card ────────────────────────────────────────────────────────────

class _SpacesCard extends ConsumerWidget {
  const _SpacesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceState = ref.watch(spaceProvider);
    final userId = ref.read(currentUserProvider)?.userId;

    return _SettingsCard(
      children: [
        ...spaceState.spaces.asMap().entries.map((entry) {
          final i = entry.key;
          final space = entry.value;
          final isActive = space.id == spaceState.activeSpaceId;
          final flag = AppConstants.flagForCode(space.learningLanguage);
          final name =
              AppConstants.languageDisplayName(space.learningLanguage);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0) const _Divider(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!isActive && userId != null) {
                    ref
                        .read(spaceProvider.notifier)
                        .switchSpace(userId, space.id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${space.nativeFlag} ${space.subtitle}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 14, color: Colors.black),
                        ),
                      if (spaceState.spaces.length > 1) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _confirmDeleteSpace(
                              context, ref, userId, space.id),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.textDim),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        const _Divider(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showCreateSpaceDialog(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
                SizedBox(width: 12),
                Text(
                  'Add Space',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteSpace(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    String spaceId,
  ) {
    if (userId == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Space?',
            style: TextStyle(color: AppColors.text)),
        content: const Text(
          'This removes the space. Cards in this space are not deleted.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(spaceProvider.notifier).deleteSpace(userId, spaceId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Quiet hours picker ─────────────────────────────────────────────────────

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
    _to = widget.toHour;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quiet Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications between ${_fmt(_from)} and ${_fmt(_to)}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text('From: ${_fmt(_from)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              thumbColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface3,
            ),
            child: Slider(
              value: _from.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              label: _fmt(_from),
              onChanged: (v) => setState(() => _from = v.round()),
            ),
          ),
          const SizedBox(height: 8),
          Text('To: ${_fmt(_to)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              thumbColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface3,
            ),
            child: Slider(
              value: _to.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              label: _fmt(_to),
              onChanged: (v) => setState(() => _to = v.round()),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black),
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
