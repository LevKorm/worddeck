import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../modules/auth/auth_provider.dart';
import '../modules/spaces/space_provider.dart';
import 'language_selector.dart';

/// Shows a bottom sheet for creating a new language space.
Future<void> showCreateSpaceDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CreateSpaceSheet(),
  );
}

class _CreateSpaceSheet extends ConsumerStatefulWidget {
  const _CreateSpaceSheet();

  @override
  ConsumerState<_CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends ConsumerState<_CreateSpaceSheet> {
  String _nativeLang = AppConstants.defaultNativeLanguage;
  String _learningLang = AppConstants.defaultLearningLanguage;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingSpaces = ref.watch(spaceProvider).spaces;

    // Check for duplicate
    final isDuplicate = existingSpaces.any((s) =>
        s.nativeLanguage == _nativeLang &&
        s.learningLanguage == _learningLang);
    final isSame = _nativeLang == _learningLang;
    final canCreate = !isDuplicate && !isSame && !_isCreating;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Vocabulary Space',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A separate space for each language you\'re learning.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // I speak
          Text('I speak', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          _LangPickerTile(
            langCode: _nativeLang,
            onChanged: (code) => setState(() => _nativeLang = code),
          ),
          const SizedBox(height: 16),

          // I'm learning
          Text('I\'m learning', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          _LangPickerTile(
            langCode: _learningLang,
            onChanged: (code) => setState(() => _learningLang = code),
          ),
          const SizedBox(height: 8),

          if (isSame)
            _HintText('Native and learning languages must be different.'),
          if (isDuplicate)
            _HintText('You already have a space for this language pair.'),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canCreate ? _onCreate : null,
              child: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Space'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreate() async {
    final userId = ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    setState(() => _isCreating = true);
    await ref
        .read(spaceProvider.notifier)
        .createSpace(userId, _nativeLang, _learningLang);
    if (mounted) Navigator.of(context).pop();
  }
}

class _LangPickerTile extends StatelessWidget {
  final String langCode;
  final ValueChanged<String> onChanged;

  const _LangPickerTile({required this.langCode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              AppConstants.flagForCode(langCode),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppConstants.languageDisplayName(langCode),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
