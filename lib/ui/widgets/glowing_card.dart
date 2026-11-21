import 'package:flutter/material.dart';

/// Reusable dark-zinc styled card with optional accent glow border
class GlowingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final bool isGlowing;
  final VoidCallback? onTap;

  const GlowingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.glowColor,
    this.isGlowing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // Zinc-900
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGlowing
              ? effectiveGlowColor.withValues(alpha: 0.8)
              : const Color(0xFF27272A), // Zinc-800
          width: isGlowing ? 1.5 : 1.0,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: effectiveGlowColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
