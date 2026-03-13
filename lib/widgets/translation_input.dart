import 'package:flutter/material.dart';

/// Text input for the Translate screen.
///
/// - Circular arrow button submits (disabled when empty).
/// - Clear (×) button appears when text is present.
/// - Button becomes a spinner while [isLoading] is true.
class TranslationInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback? onClear;
  final bool isLoading;

  const TranslationInputField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.onClear,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (ctx, value, _) {
        final hasText = value.text.isNotEmpty;

        return TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            if (hasText && !isLoading) onSubmit();
          },
          decoration: InputDecoration(
            hintText: 'Enter a word or phrase...',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText && !isLoading)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: theme.colorScheme.onSurfaceVariant,
                      tooltip: 'Clear',
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                      },
                    ),
                  isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _SubmitCircle(hasText: hasText, onPressed: onSubmit),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubmitCircle extends StatelessWidget {
  final bool hasText;
  final VoidCallback onPressed;

  const _SubmitCircle({required this.hasText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasText
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withAlpha(77);

    return Container(
      margin: const EdgeInsets.all(6),
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasText ? onPressed : null,
          child: const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
