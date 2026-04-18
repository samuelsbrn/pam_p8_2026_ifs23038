// lib/shared/widgets/error_widget.dart

import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.error.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 32,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Terjadi Kesalahan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
