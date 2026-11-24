import 'dart:math';
import 'package:flutter/material.dart';
import '../../protocol/elk_protocol.dart';
import '../../services/ble_led_service.dart';
import '../widgets/animated_effect_tile.dart';
import '../widgets/glowing_card.dart';

class EffectsTab extends StatefulWidget {
  final BleLedService bleService;

  const EffectsTab({super.key, required this.bleService});

  @override
  State<EffectsTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectsTab> {
  String _selectedSection = 'Ambient Drifts';

  static const List<String> _sections = [
    'Ambient Drifts',
    'Flames & Pulses',
    'Hardware Modes',
    'All',
  ];

  @override
  Widget build(BuildContext context) {
    final ble = widget.bleService;
    final activeScene = ble.activeScene;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ACTIVE EFFECT CONTROLLER BANNER (MINIMAL)
          GlowingCard(
            glowColor: const Color(0xFF8B5CF6),
            isGlowing: ble.isPoweredOn && (activeScene != ActiveScene.none || ble.currentEffectMode != 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'LIGHTING ENGINE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFFA78BFA),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (ble.reduceFlashing)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FLASH LIMITER',
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        activeScene != ActiveScene.none
                            ? 'Playing: ${activeScene.name.toUpperCase()}'
                            : 'Hardware: ${ElkEffectCatalog.getById(ble.currentEffectMode).name}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (activeScene != ActiveScene.none)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFF87171),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 14),
                    label: const Text('Stop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () => ble.stopScene(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. SPEED SLIDER & REDUCE FLASHING SWITCH (COMPACT)
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Speed Slider
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EFFECT SPEED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA)),
                          ),
                          Text(
                            '${ble.currentEffectSpeed}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF06B6D4),
                          inactiveTrackColor: const Color(0xFF27272A),
                          thumbColor: const Color(0xFF06B6D4),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: ble.currentEffectSpeed.toDouble(),
                          min: 1,
                          max: 100,
                          onChanged: (v) => ble.sendEffectSpeed(v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),

                // Reduce Flashing Switch
                Container(
                  height: 36,
                  width: 1,
                  color: const Color(0xFF27272A),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Reduce Flashing',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Limits rapid light flashes and harsh strobes for visual comfort and accessibility.',
                          child: Icon(Icons.info_outline_rounded, size: 13, color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.85,
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: ble.reduceFlashing,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (v) => ble.setReduceFlashing(v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. SECTION SELECTOR TABS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sections.map((section) {
                final isSelected = _selectedSection == section;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(section),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B5CF6),
                    backgroundColor: const Color(0xFF18181B),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF27272A),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onSelected: (val) {
                      if (val) setState(() => _selectedSection = section);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // 4. ANIMATED EFFECT TILES GRID
          _buildEffectTilesGrid(ble),
        ],
      ),
    );
  }

  Widget _buildEffectTilesGrid(BleLedService ble) {
    final List<Widget> tiles = [];

    // Ambient Drifts Section
    if (_selectedSection == 'Ambient Drifts' || _selectedSection == 'All') {
      tiles.addAll([
        AnimatedEffectTile(
          title: 'Aurora',
          subtitle: 'Rolling northern lights green-teal-purple wave.',
          badge: 'DRIFT',
          icon: Icons.waves_rounded,
          isActive: ble.activeScene == ActiveScene.aurora,
          onTap: () => ble.startScene(ActiveScene.aurora),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFF00FF88), const Color(0xFF7C4DFF), (sin(p * 2 * pi) + 1) / 2)!,
            Color.lerp(const Color(0xFF00D2FF), const Color(0xFF00FF88), (cos(p * 2 * pi) + 1) / 2)!,
          ],
        ),
        AnimatedEffectTile(
          title: 'Lava Lamp',
          subtitle: 'Warm rising liquid blobs of molten crimson and amber.',
          badge: 'DRIFT',
          icon: Icons.bubble_chart_rounded,
          isActive: ble.activeScene == ActiveScene.lavaLamp,
          onTap: () => ble.startScene(ActiveScene.lavaLamp),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFFFF2200), const Color(0xFFFF8800), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFF990000),
          ],
        ),
        AnimatedEffectTile(
          title: 'Vaporwave',
          subtitle: 'Electric neon magenta and glowing cyan synthwave.',
          badge: 'DRIFT',
          icon: Icons.nightlife_rounded,
          isActive: ble.activeScene == ActiveScene.vaporwave,
          onTap: () => ble.startScene(ActiveScene.vaporwave),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFFFF007F), const Color(0xFF00F0FF), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFF7C4DFF),
          ],
        ),
        AnimatedEffectTile(
          title: 'Sunset',
          subtitle: 'Deep dusky violet fading into warm orange and gold.',
          badge: 'DRIFT',
          icon: Icons.wb_twilight_rounded,
          isActive: ble.activeScene == ActiveScene.sunset,
          onTap: () => ble.startScene(ActiveScene.sunset),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFF4A0E4E), const Color(0xFFFF5722), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFFFFC107),
          ],
        ),
        AnimatedEffectTile(
          title: 'Forest',
          subtitle: 'Emerald, pine, and moss green gentle canopy drifts.',
          badge: 'DRIFT',
          icon: Icons.forest_rounded,
          isActive: ble.activeScene == ActiveScene.forest,
          onTap: () => ble.startScene(ActiveScene.forest),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFF1B5E20), const Color(0xFF00E676), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFF2E7D32),
          ],
        ),
        AnimatedEffectTile(
          title: 'Galaxy',
          subtitle: 'Deep interstellar nebula indigo, midnight blue, and purple.',
          badge: 'DRIFT',
          icon: Icons.stars_rounded,
          isActive: ble.activeScene == ActiveScene.galaxy,
          onTap: () => ble.startScene(ActiveScene.galaxy),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFF0D083B), const Color(0xFFE040FB), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFF3F51B5),
          ],
        ),
        AnimatedEffectTile(
          title: 'Ice',
          subtitle: 'Crisp crystalline glaciers, pure white, and cyan frost.',
          badge: 'DRIFT',
          icon: Icons.ac_unit_rounded,
          isActive: ble.activeScene == ActiveScene.ice,
          onTap: () => ble.startScene(ActiveScene.ice),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFFE0F7FA), const Color(0xFF00E5FF), (sin(p * 2 * pi) + 1) / 2)!,
            Colors.white,
          ],
        ),
        AnimatedEffectTile(
          title: 'Rainbow',
          subtitle: 'Smooth continuous 360-degree chromatic spectrum sweep.',
          badge: 'DRIFT',
          icon: Icons.looks_rounded,
          isActive: ble.activeScene == ActiveScene.rgbCycle,
          onTap: () => ble.startScene(ActiveScene.rgbCycle),
          colorGenerator: (p) => [
            HSVColor.fromAHSV(1.0, (p * 360.0) % 360.0, 1.0, 1.0).toColor(),
            HSVColor.fromAHSV(1.0, ((p + 0.3) * 360.0) % 360.0, 1.0, 1.0).toColor(),
          ],
        ),
        AnimatedEffectTile(
          title: 'Ocean',
          subtitle: 'Deep oceanic navy to vivid aqua swell tides.',
          badge: 'DRIFT',
          icon: Icons.water_rounded,
          isActive: ble.activeScene == ActiveScene.oceanBreathe,
          onTap: () => ble.startScene(ActiveScene.oceanBreathe),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFF001F3F), const Color(0xFF00D2FF), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFF0074D9),
          ],
        ),
      ]);
    }

    // Flames & Pulses Section
    if (_selectedSection == 'Flames & Pulses' || _selectedSection == 'All') {
      tiles.addAll([
        AnimatedEffectTile(
          title: 'Candle',
          subtitle: 'Subtle warm flame pulsation and amber flicker.',
          badge: 'FLAME',
          icon: Icons.fireplace_rounded,
          isActive: ble.activeScene == ActiveScene.candle,
          onTap: () => ble.startScene(ActiveScene.candle),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFFFF9900), const Color(0xFFFF5500), (sin(p * 6 * pi) + 1) / 2)!,
            const Color(0xFF882200),
          ],
        ),
        AnimatedEffectTile(
          title: 'Fireplace',
          subtitle: 'Dynamic ember fluctuations between crimson and gold.',
          badge: 'FLAME',
          icon: Icons.local_fire_department_rounded,
          isActive: ble.activeScene == ActiveScene.fire,
          onTap: () => ble.startScene(ActiveScene.fire),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFFFF3A00), const Color(0xFFFFB300), (sin(p * 8 * pi) + 1) / 2)!,
            const Color(0xFFB71C1C),
          ],
        ),
        AnimatedEffectTile(
          title: '4-7-8 Breathing Guide',
          subtitle: 'Relaxation pacing: 4s inhale cyan, 7s hold blue, 8s exhale amber.',
          badge: 'WELLNESS',
          icon: Icons.spa_rounded,
          isActive: ble.activeScene == ActiveScene.breath478,
          onTap: () => ble.startScene(ActiveScene.breath478),
          colorGenerator: (p) => [
            Color.lerp(const Color(0xFF00F0FF), const Color(0xFF9C27B0), (sin(p * 2 * pi) + 1) / 2)!,
            const Color(0xFF3F51B5),
          ],
        ),
        AnimatedEffectTile(
          title: 'Heartbeat',
          subtitle: 'Cardiovascular double lub-dub pulse in rich crimson.',
          badge: 'PULSE',
          icon: Icons.favorite_rounded,
          isActive: ble.activeScene == ActiveScene.heartbeat,
          onTap: () => ble.startScene(ActiveScene.heartbeat),
          colorGenerator: (p) {
            final b = (p * 4) % 1.0;
            final isPulse = b < 0.2 || (b > 0.35 && b < 0.55);
            return [
              isPulse ? const Color(0xFFFF0033) : const Color(0xFF330005),
              const Color(0xFF110002),
            ];
          },
        ),
        AnimatedEffectTile(
          title: 'Neon Flicker',
          subtitle: 'Authentic stutter of an atmospheric vintage neon sign.',
          badge: 'PULSE',
          icon: Icons.flash_on_rounded,
          isActive: ble.activeScene == ActiveScene.neonFlicker,
          onTap: () => ble.startScene(ActiveScene.neonFlicker),
          colorGenerator: (p) => [
            ((p * 12).toInt() % 3 == 0) ? const Color(0xFFFF007F) : const Color(0xFF220011),
            const Color(0xFF440022),
          ],
        ),
        AnimatedEffectTile(
          title: 'Lightning',
          subtitle: 'Sudden high-voltage thunderstorm flash burst.',
          badge: 'BURST',
          icon: Icons.bolt_rounded,
          isActive: ble.activeScene == ActiveScene.lightning,
          onTap: () => ble.startScene(ActiveScene.lightning),
          colorGenerator: (p) => [
            ((p * 10).toInt() % 5 == 0) ? Colors.white : const Color(0xFF0D0D1A),
            const Color(0xFF1A1A33),
          ],
        ),
        AnimatedEffectTile(
          title: 'Police',
          subtitle: 'Alternating high-visibility red and blue emergency flash.',
          badge: 'STROBE',
          icon: Icons.local_police_rounded,
          isActive: ble.activeScene == ActiveScene.police,
          onTap: () => ble.startScene(ActiveScene.police),
          colorGenerator: (p) => [
            ((p * 8).toInt() % 2 == 0) ? const Color(0xFFFF0000) : const Color(0xFF0000FF),
            Colors.black,
          ],
        ),
        AnimatedEffectTile(
          title: 'Party',
          subtitle: 'Upbeat high-tempo chromatic disco rave pulses.',
          badge: 'PARTY',
          icon: Icons.celebration_rounded,
          isActive: ble.activeScene == ActiveScene.party,
          onTap: () => ble.startScene(ActiveScene.party),
          colorGenerator: (p) => [
            HSVColor.fromAHSV(1.0, ((p * 720.0).toInt() % 360).toDouble(), 1.0, 1.0).toColor(),
            Colors.black,
          ],
        ),
      ]);
    }

    // Hardware Modes Section
    if (_selectedSection == 'Hardware Modes' || _selectedSection == 'All') {
      for (final mode in ElkEffectCatalog.modes) {
        tiles.add(
          AnimatedEffectTile(
            title: mode.name,
            subtitle: mode.description,
            badge: mode.hexId,
            icon: Icons.memory_rounded,
            isActive: ble.activeScene == ActiveScene.none && ble.currentEffectMode == mode.id,
            onTap: () => ble.sendHardwareEffect(mode.id),
            colorGenerator: (p) => [
              _getHardwareModeColor(mode.id, p),
              _getHardwareModeColor(mode.id, p + 0.3),
            ],
          ),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 950
            ? 3
            : constraints.maxWidth > 620
                ? 2
                : 1;
        final childAspectRatio = constraints.maxWidth > 950 ? 3.6 : 3.0;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          children: tiles,
        );
      },
    );
  }

  Color _getHardwareModeColor(int modeId, double progress) {
    if (modeId >= 0x80 && modeId <= 0x86) {
      // Monochrome Fades
      const colors = [
        Color(0xFFFF0000),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFFFFFF00),
        Color(0xFF00FFFF),
        Color(0xFFFF00FF),
        Color(0xFFFFFFFF),
      ];
      final base = colors[modeId - 0x80];
      final factor = (sin(progress * 2 * pi) + 1) / 2;
      return base.withValues(alpha: 0.2 + 0.8 * factor);
    }
    // Crossfades and general
    return HSVColor.fromAHSV(1.0, ((progress * 360.0) % 360.0), 1.0, 1.0).toColor();
  }
}
