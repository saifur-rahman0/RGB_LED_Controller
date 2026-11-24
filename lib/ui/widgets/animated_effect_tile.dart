import 'package:flutter/material.dart';

/// Compact, minimal animated effect tile widget.
/// Renders a sleek 38x38 live preview swatch with subtle typography and active indicators.
class AnimatedEffectTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final List<Color> Function(double progress) colorGenerator;

  const AnimatedEffectTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.colorGenerator,
  });

  @override
  State<AnimatedEffectTile> createState() => _AnimatedEffectTileState();
}

class _AnimatedEffectTileState extends State<AnimatedEffectTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

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
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final colors = widget.colorGenerator(_animController.value);
        final primaryColor =
            colors.isNotEmpty ? colors.first : const Color(0xFF8B5CF6);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? primaryColor.withValues(alpha: 0.12)
                    : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isActive
                      ? primaryColor.withValues(alpha: 0.8)
                      : const Color(0xFF27272A),
                  width: widget.isActive ? 1.5 : 1.0,
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Animated Dynamic Preview Mini-Box
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: colors.length > 1
                            ? colors
                            : [colors.first, colors.first.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
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
                            if (widget.badge != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27272A),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFF3F3F46),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  widget.badge!,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFA1A1AA),
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
                        color: Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
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
        );
      },
    );
  }
}
