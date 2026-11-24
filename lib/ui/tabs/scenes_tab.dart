import 'package:flutter/material.dart';
import '../../services/ble_led_service.dart';
import '../widgets/glowing_card.dart';

class ScenesTab extends StatelessWidget {
  final BleLedService bleService;

  const ScenesTab({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    final active = bleService.activeScene;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / Stop Scene Bar
          GlowingCard(
            glowColor: const Color(0xFFF43F5E),
            isGlowing: active != ActiveScene.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  active != ActiveScene.none ? Icons.play_circle_filled_rounded : Icons.stop_circle_rounded,
                  size: 26,
                  color: active != ActiveScene.none ? const Color(0xFF10B981) : const Color(0xFF71717A),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOFTWARE ANIMATION ENGINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active != ActiveScene.none
                            ? 'Currently Playing: ${_getSceneTitle(active)}'
                            : 'All Software Scenes Paused',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: active != ActiveScene.none ? const Color(0xFF34D399) : const Color(0xFFE4E4E7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (active != ActiveScene.none)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFF87171),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Stop Scene', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => bleService.stopScene(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scene Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
            children: [
              _buildSceneCard(
                context: context,
                scene: ActiveScene.cozyFire,
                title: 'Cozy Fire',
                subtitle: 'Dynamic amber, crimson, and golden warm flame flicker emulation.',
                gradientColors: const [Color(0xFFFF3A00), Color(0xFFFF9900), Color(0xFF991A00)],
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFFF6B00),
                isActive: active == ActiveScene.cozyFire,
                onTap: () => bleService.startScene(ActiveScene.cozyFire),
              ),
              _buildSceneCard(
                context: context,
                scene: ActiveScene.cyberpunkPulse,
                title: 'Cyberpunk Pulse',
                subtitle: 'High-contrast synthetic breathing between Neon Pink, Cyan & Violet.',
                gradientColors: const [Color(0xFFFF007F), Color(0xFF00F0FF), Color(0xFF9D00FF)],
                icon: Icons.electric_bolt_rounded,
                accentColor: const Color(0xFFFF007F),
                isActive: active == ActiveScene.cyberpunkPulse,
                onTap: () => bleService.startScene(ActiveScene.cyberpunkPulse),
              ),
              _buildSceneCard(
                context: context,
                scene: ActiveScene.oceanBreathe,
                title: 'Ocean Breathe',
                subtitle: 'Slow, deep sinusoidal undulating waves from deep navy to aqua froth.',
                gradientColors: const [Color(0xFF001F3F), Color(0xFF0074D9), Color(0xFF39CCCC)],
                icon: Icons.water_rounded,
                accentColor: const Color(0xFF0074D9),
                isActive: active == ActiveScene.oceanBreathe,
                onTap: () => bleService.startScene(ActiveScene.oceanBreathe),
              ),
              _buildSceneCard(
                context: context,
                scene: ActiveScene.rgbCycle,
                title: 'RGB Cycle',
                subtitle: 'Continuous smooth 360-degree chromatic spectrum sweep loop.',
                gradientColors: const [
                  Color(0xFFFF0000),
                  Color(0xFF00FF00),
                  Color(0xFF0000FF),
                  Color(0xFFFF0000),
                ],
                icon: Icons.sync_rounded,
                accentColor: const Color(0xFF10B981),
                isActive: active == ActiveScene.rgbCycle,
                onTap: () => bleService.startScene(ActiveScene.rgbCycle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSceneCard({
    required BuildContext context,
    required ActiveScene scene,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
    required Color accentColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GlowingCard(
      glowColor: accentColor,
      isGlowing: isActive,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient Banner Preview
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'PLAYING' : 'READY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isActive ? const Color(0xFF34D399) : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA), height: 1.3),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        isActive ? 'Active Animation' : 'Start Scene',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? accentColor : const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isActive ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 15,
                        color: isActive ? accentColor : const Color(0xFF71717A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSceneTitle(ActiveScene s) {
    switch (s) {
      case ActiveScene.cozyFire:
        return 'Cozy Fire';
      case ActiveScene.cyberpunkPulse:
        return 'Cyberpunk Pulse';
      case ActiveScene.oceanBreathe:
        return 'Ocean Breathe';
      case ActiveScene.rgbCycle:
        return 'RGB Cycle';
      case ActiveScene.none:
        return 'None';
      default:
        return 'Ambient Scene';
    }
  }
}
