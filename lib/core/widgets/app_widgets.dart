import 'package:flutter/material.dart';

/// A reusable loading indicator widget
class AppLoadingIndicator extends StatelessWidget {
  /// Creates an [AppLoadingIndicator] widget
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// A reusable error widget
class AppErrorWidget extends StatelessWidget {
  /// Creates an [AppErrorWidget]
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// The error message to display
  final String message;
  
  /// Optional callback for retry action
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}