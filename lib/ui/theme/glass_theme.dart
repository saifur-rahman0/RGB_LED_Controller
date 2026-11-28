import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized Design System v2.0 tokens & shared Glassmorphism UI primitives
/// for the RGB LED Console.
class GlassColors {
  GlassColors._();

  // Surfaces (Zinc + Abyss Glass Stack)
  static const Color voidBg = Color(0xFF080810);
  static const Color abyss = Color(0xFF0F0F12);
  static const Color base = Color(0xFF111114);
  static const Color canvas = Color(0xFF141417);
  static const Color glass = Color(0xFF18181B);
  static const Color elevated = Color(0xFF1C1C20);
  static const Color overlay = Color(0xFF1C1C24);

  // Borders
  static const Color borderSubtle = Color(0xFF1F1F23);
  static const Color borderDefault = Color(0xFF27272A);
  static const Color borderMuted = Color(0xFF2E2E33);
  static const Color borderRaised = Color(0xFF3F3F46);
  static const Color borderHover = Color(0xFF52525B);

  // Brand & Semantic Accents
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color indigo = Color(0xFF6366F1);
  static const Color purple = Color(0xFFA855F7);
  static const Color pink = Color(0xFFEC4899);

  // Hardware Status
  static const Color connected = Color(0xFF10B981);
  static const Color connectedLight = Color(0xFF34D399);
  static const Color connecting = Color(0xFFFBBF24);
  static const Color scanning = Color(0xFF38BDF8);
  static const Color reconnecting = Color(0xFFFB923C);
  static const Color offline = Color(0xFFEF4444);
  static const Color offlineLight = Color(0xFFF87171);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textSubtle = Color(0xFF71717A);
  static const Color textPlaceholder = Color(0xFF52525B);
}

/// Custom SliderThumbShape that renders a luminous neon halo around the thumb.
class NeonSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final Color glowColor;

  const NeonSliderThumbShape({
    this.enabledThumbRadius = 6.0,
    required this.glowColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius + 3);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer neon halo
    final haloPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(center, enabledThumbRadius + 2.0, haloPaint);

    // Core thumb circle
    final corePaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, corePaint);

    // Specular inner center dot
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius * 0.4, highlightPaint);
  }
}

/// Builds a standardized neon compact slider theme for a given accent color.
SliderThemeData buildNeonSliderTheme(BuildContext context, Color accentColor) {
  return SliderTheme.of(context).copyWith(
    activeTrackColor: accentColor,
    inactiveTrackColor: GlassColors.borderDefault,
    thumbColor: accentColor,
    overlayColor: accentColor.withValues(alpha: 0.16),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    thumbShape: NeonSliderThumbShape(
      enabledThumbRadius: 6.0,
      glowColor: accentColor,
    ),
    trackHeight: 3.0,
  );
}

/// Standardized all-caps section header inside cards.
class GlassSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget? trailing;

  const GlassSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: accentColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: GlassColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Compact empty state placeholder for lists and grids.
class GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GlassColors.canvas.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GlassColors.borderDefault.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: GlassColors.borderDefault.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: GlassColors.textSubtle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: GlassColors.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: GlassColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens a frosted-glass backdrop dialog consistent with Design System v2.0.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: builder(ctx),
    ),
  );
}

OverlayEntry? _activeToastEntry;

/// Displays a sleek bottom-right neon toast notification with slide-up & fade.
void showNeonToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  Color accentColor = GlassColors.connected,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  _activeToastEntry?.remove();
  _activeToastEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _NeonToastOverlay(
      message: message,
      icon: icon,
      accentColor: accentColor,
      duration: duration,
      onDismissed: () {
        if (_activeToastEntry == entry) {
          _activeToastEntry?.remove();
          _activeToastEntry = null;
        }
      },
    ),
  );

  _activeToastEntry = entry;
  overlay.insert(entry);
}

class _NeonToastOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _NeonToastOverlay({
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_NeonToastOverlay> createState() => _NeonToastOverlayState();
}

class _NeonToastOverlayState extends State<_NeonToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 40,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: GlassColors.overlay.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.18),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 15, color: widget.accentColor),
                        const SizedBox(width: 8),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: GlassColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
