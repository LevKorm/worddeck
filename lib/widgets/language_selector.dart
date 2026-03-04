import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Language pair selector with animated swap button.
/// Tapping either language opens a bottom-sheet picker.
class LanguageSelectorWidget extends StatelessWidget {
  final String sourceLang;
  final String targetLang;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSwap;

  const LanguageSelectorWidget({
    super.key,
    required this.sourceLang,
    required this.targetLang,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LanguageChip(
              langCode: sourceLang,
              onTap: () => _showPicker(context, sourceLang, onSourceChanged),
            ),
          ),
          _SwapButton(onSwap: onSwap),
          Expanded(
            child: _LanguageChip(
              langCode: targetLang,
              onTap: () => _showPicker(context, targetLang, onTargetChanged),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    String current,
    ValueChanged<String> onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LanguagePickerSheet(
        current: current,
        onSelected: (code) {
          onChanged(code);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Private: language chip ─────────────────────────────────────────────────

class _LanguageChip extends StatelessWidget {
  final String langCode;
  final VoidCallback onTap;

  const _LanguageChip({required this.langCode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flag = AppConstants.languageFlags[langCode] ?? '🌐';
    final name = AppConstants.languageNames[langCode] ?? langCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private: animated swap button ─────────────────────────────────────────

class _SwapButton extends StatefulWidget {
  final VoidCallback onSwap;

  const _SwapButton({required this.onSwap});

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton> {
  int _turns = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() => _turns++);
        widget.onSwap();
      },
      child: AnimatedRotation(
        turns: _turns * 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.swap_horiz_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Language picker bottom sheet (public) ─────────────────────────────────

/// Reusable language picker sheet — used by [LanguageSelectorWidget]
/// and the Settings screen.
class LanguagePickerSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const LanguagePickerSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text('Select language', style: theme.textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: AppConstants.supportedLanguageCodes.length,
                itemBuilder: (_, i) {
                  final code = AppConstants.supportedLanguageCodes[i];
                  final flag = AppConstants.languageFlags[code] ?? '🌐';
                  final name = AppConstants.languageNames[code] ?? code;
                  final selected = code == current;

                  return ListTile(
                    leading: Text(flag, style: const TextStyle(fontSize: 22)),
                    title: Text(name),
                    trailing: selected
                        ? Icon(Icons.check_rounded,
                            color: theme.colorScheme.primary)
                        : null,
                    selected: selected,
                    selectedTileColor:
                        theme.colorScheme.primary.withAlpha(13),
                    onTap: () => onSelected(code),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
