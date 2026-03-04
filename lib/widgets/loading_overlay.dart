import 'package:flutter/material.dart';

/// Full-screen semi-transparent overlay with a centered spinner.
///
/// Wrap the main screen content as [child]; the overlay only appears
/// when [isLoading] is true.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          const ModalBarrier(
            dismissible: false,
            color: Colors.black26,
          ),
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
