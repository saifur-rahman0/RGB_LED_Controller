import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// Glassmorphism card container with top-left luminance sheen,
/// reactive neon glow corona when active, and subtle hover elevation.
class GlowingCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final bool isGlowing;
  final bool isDanger;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlowingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.glowColor,
    this.isGlowing = false,
    this.isDanger = false,
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  State<GlowingCard> createState() => _GlowingCardState();
}

class _GlowingCardState extends State<GlowingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = widget.isDanger
        ? GlassColors.offline
        : (widget.glowColor ?? Theme.of(context).colorScheme.primary);

    final Color bgColor;
    final Gradient gradient;
    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow> shadows;

    if (widget.isGlowing) {
      bgColor = effectiveGlow.withValues(alpha: 0.08);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          effectiveGlow.withValues(alpha: _isHovered ? 0.19 : 0.15),
          GlassColors.glass.withValues(alpha: 0.65),
        ],
      );
      borderColor = effectiveGlow.withValues(alpha: _isHovered ? 0.85 : 0.7);
      borderWidth = 1.5;
      shadows = [
        BoxShadow(
          color: effectiveGlow.withValues(alpha: _isHovered ? 0.34 : 0.28),
          blurRadius: 24,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (widget.isDanger) {
      bgColor = GlassColors.offline.withValues(alpha: 0.06);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GlassColors.offline.withValues(alpha: 0.12),
          GlassColors.glass.withValues(alpha: 0.72),
        ],
      );
      borderColor = GlassColors.offline.withValues(alpha: 0.6);
      borderWidth = 1.0;
      shadows = [
        BoxShadow(
          color: GlassColors.offline.withValues(alpha: 0.2),
          blurRadius: 16,
        ),
      ];
    } else {
      bgColor = GlassColors.glass.withValues(alpha: _isHovered ? 0.85 : 0.75);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: _isHovered ? 0.06 : 0.04),
          Colors.transparent,
        ],
      );
      borderColor = _isHovered
          ? GlassColors.borderHover.withValues(alpha: 0.85)
          : GlassColors.borderRaised.withValues(alpha: 0.6);
      borderWidth = 1.0;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isHovered ? 0.5 : 0.4),
          blurRadius: _isHovered ? 16 : 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: widget.onTap,
            splashColor: effectiveGlow.withValues(alpha: 0.12),
            highlightColor: effectiveGlow.withValues(alpha: 0.06),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
