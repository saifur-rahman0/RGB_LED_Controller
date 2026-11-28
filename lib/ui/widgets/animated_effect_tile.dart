import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// Compact, glassmorphic animated effect tile widget.
/// Renders a 38x38 live preview swatch with top-left glass sheen,
/// hover border highlight, strobe safety state, and active status dot.
class AnimatedEffectTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final bool isActive;
  final bool isStrobeWarning;
  final bool isDisabledBySafety;
  final VoidCallback onTap;
  final List<Color> Function(double progress) colorGenerator;

  const AnimatedEffectTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.isActive,
    this.isStrobeWarning = false,
    this.isDisabledBySafety = false,
    required this.onTap,
    required this.colorGenerator,
  });

  @override
  State<AnimatedEffectTile> createState() => _AnimatedEffectTileState();
}

class _AnimatedEffectTileState extends State<AnimatedEffectTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tileContent = MouseRegion(
      cursor: widget.isDisabledBySafety
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final colors = widget.colorGenerator(_animController.value);
          final primaryColor =
              colors.isNotEmpty ? colors.first : GlassColors.violet;

          return Opacity(
            opacity: widget.isDisabledBySafety ? 0.42 : 1.0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.isDisabledBySafety
                    ? () {
                        showNeonToast(
                          context,
                          'Disabled: Reduce Flashing safety limiter is ON',
                          icon: Icons.health_and_safety_rounded,
                          accentColor: GlassColors.connecting,
                        );
                      }
                    : widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? primaryColor.withValues(alpha: 0.12)
                        : GlassColors.glass.withValues(
                            alpha: _isHovered ? 0.88 : 0.75,
                          ),
                    gradient: widget.isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withValues(alpha: 0.16),
                              GlassColors.glass.withValues(alpha: 0.7),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(
                                alpha: _isHovered ? 0.05 : 0.03,
                              ),
                              Colors.transparent,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.isActive
                          ? primaryColor.withValues(alpha: 0.8)
                          : (_isHovered
                              ? GlassColors.borderHover
                              : GlassColors.borderRaised.withValues(alpha: 0.55)),
                      width: widget.isActive ? 1.5 : 1.0,
                    ),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      // Animated Dynamic Preview Mini-Box with top-left glass sheen
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: colors.length > 1
                                ? colors
                                : [
                                    colors.first,
                                    colors.first.withValues(alpha: 0.6),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 2,
                              left: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(
                                widget.icon,
                                size: 18,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Metadata & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isActive
                                          ? Colors.white
                                          : const Color(0xFFF4F4F5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isStrobeWarning) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: widget.isDisabledBySafety
                                        ? 'Disabled: Reduce Flashing is ON'
                                        : 'High-frequency flicker / strobe effect',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GlassColors.connecting.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: GlassColors.connecting
                                              .withValues(alpha: 0.45),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 9.5,
                                            color: GlassColors.connecting,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.badge != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GlassColors.borderDefault,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: GlassColors.borderRaised,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      widget.badge!,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: GlassColors.textMuted,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF8E8E93),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Active Glowing Status Dot
                      if (widget.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: GlassColors.connected,
                            boxShadow: [
                              BoxShadow(
                                color: GlassColors.connected,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.isDisabledBySafety) {
      return Tooltip(
        message: 'Disabled: Reduce Flashing is ON',
        child: tileContent,
      );
    }
    return tileContent;
  }
}
