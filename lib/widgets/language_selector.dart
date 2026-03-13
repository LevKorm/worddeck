import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Language pair selector with animated swap button.
/// Tapping either language opens a bottom-sheet picker.
class LanguageSelectorWidget extends StatelessWidget {
  final String sourceLang;
  final String targetLang;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSwap;
  final String? sourceLabel;
  final String? targetLabel;

  const LanguageSelectorWidget({
    super.key,
    required this.sourceLang,
    required this.targetLang,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
    this.sourceLabel,
    this.targetLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _LanguageLabel(
              langCode: sourceLang,
              subLabel: sourceLabel,
              onTap: () => _showPicker(context, sourceLang, onSourceChanged),
            ),
          ),
          _SwapButton(onSwap: onSwap),
          Expanded(
            child: _LanguageLabel(
              langCode: targetLang,
              subLabel: targetLabel,
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

// ── Private: language label ────────────────────────────────────────────────

class _LanguageLabel extends StatelessWidget {
  final String langCode;
  final VoidCallback onTap;
  final String? subLabel;

  const _LanguageLabel({required this.langCode, required this.onTap, this.subLabel});

  @override
  Widget build(BuildContext context) {
    final name = AppConstants.languageNames[langCode] ?? langCode;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                subLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ],
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
    return GestureDetector(
      onTap: () {
        setState(() => _turns++);
        widget.onSwap();
      },
      child: AnimatedRotation(
        turns: _turns * 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.swap_horiz_rounded,
            size: 20,
            color: AppColors.textDim,
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
