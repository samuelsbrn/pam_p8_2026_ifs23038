// lib/shared/widgets/app_background.dart

import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.showTopGlow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showTopGlow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E111B), Color(0xFF141B2B)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F7FF), Color(0xFFF8FBFF)],
          );

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
        if (showTopGlow) ...[
          Positioned(
            top: -60,
            left: -40,
            child: _BlurBlob(
              size: 220,
              color: isDark ? const Color(0xFF3A86FF) : const Color(0xFF6BA7FF),
              opacity: isDark ? 0.18 : 0.22,
            ),
          ),
          Positioned(
            top: 40,
            right: -90,
            child: _BlurBlob(
              size: 240,
              color: isDark ? const Color(0xFF00A896) : const Color(0xFF6FD9CD),
              opacity: isDark ? 0.14 : 0.2,
            ),
          ),
        ],
        Padding(padding: padding, child: child),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
