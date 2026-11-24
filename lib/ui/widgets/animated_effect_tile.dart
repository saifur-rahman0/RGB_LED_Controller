import 'package:flutter/material.dart';

/// Live animating miniature preview tile widget for effects and scenes.
/// Runs a lightweight periodic animation to display real-time visual behavior.
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

class _AnimatedEffectTileState extends State<AnimatedEffectTile> with SingleTickerProviderStateMixin {
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
        final primaryColor = colors.isNotEmpty ? colors.first : const Color(0xFF8B5CF6);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive ? primaryColor : const Color(0xFF27272A),
              width: widget.isActive ? 2.0 : 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Dynamic Preview Banner
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      gradient: LinearGradient(
                        colors: colors.length > 1 ? colors : [colors.first, colors.first.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (widget.badge != null)
                          Positioned(
                            top: 8,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.badge!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (widget.isActive)
                          Positioned(
                            bottom: 6,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Metadata & Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(widget.icon, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isActive ? Colors.white : const Color(0xFFE4E4E7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              widget.subtitle,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA), height: 1.25),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
