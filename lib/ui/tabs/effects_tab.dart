import 'dart:math';
import 'package:flutter/material.dart';
import '../../protocol/elk_protocol.dart';
import '../../services/ble_led_service.dart';
import '../theme/glass_theme.dart';
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
  bool _isGridView = true;

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
    final isEngineActive =
        ble.isPoweredOn &&
        (activeScene != ActiveScene.none || ble.currentEffectMode != 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ACTIVE EFFECT CONTROLLER BANNER
          GlowingCard(
            glowColor: GlassColors.violet,
            isGlowing: isEngineActive,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: GlassColors.violet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: GlassColors.violet.withValues(alpha: 0.55),
                    ),
                    boxShadow: isEngineActive
                        ? [
                            BoxShadow(
                              color: GlassColors.violet.withValues(alpha: 0.45),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: GlassColors.violetLight,
                      size: 19,
                    ),
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
                              color: GlassColors.violetLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (ble.reduceFlashing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: GlassColors.connected.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: GlassColors.connected.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'FLASH LIMITER',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: GlassColors.connected,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeScene != ActiveScene.none
                            ? 'Playing: ${activeScene.name.toUpperCase()}'
                            : (ble.currentEffectMode != 0
                                  ? 'Hardware: ${ElkEffectCatalog.getById(ble.currentEffectMode).name}'
                                  : 'Solid Color Mode • Select an effect below'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (activeScene != ActiveScene.none)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassColors.offline.withValues(
                        alpha: 0.2,
                      ),
                      foregroundColor: GlassColors.offlineLight,
                      side: const BorderSide(color: GlassColors.offline),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 15),
                    label: const Text(
                      'Stop',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    onPressed: () => ble.stopScene(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. SPEED SLIDER & REDUCE FLASHING SWITCH
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EFFECT SPEED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: GlassColors.textMuted,
                            ),
                          ),
                          Text(
                            '${ble.currentEffectSpeed}%',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: GlassColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: buildNeonSliderTheme(context, GlassColors.cyan),
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
                const SizedBox(width: 16),
                Container(
                  height: 36,
                  width: 1,
                  color: GlassColors.borderDefault,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Reduce Flashing',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message:
                              'Limits rapid flashes and locks strobe-class modes for visual safety.',
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.85,
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: ble.reduceFlashing,
                        activeThumbColor: GlassColors.connected,
                        onChanged: (v) => ble.setReduceFlashing(v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. SECTION SELECTOR PILLS + GRID/LIST VIEW TOGGLE
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sections.map((section) {
                      final isSelected = _selectedSection == section;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(section),
                          selected: isSelected,
                          selectedColor: GlassColors.violet,
                          backgroundColor: GlassColors.glass,
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isSelected
                                ? GlassColors.violet
                                : GlassColors.borderDefault,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : GlassColors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedSection = section);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: GlassColors.glass.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GlassColors.borderDefault),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view_rounded, size: 15),
                      tooltip: 'Grid View',
                      visualDensity: VisualDensity.compact,
                      color: _isGridView
                          ? GlassColors.violetLight
                          : GlassColors.textSubtle,
                      onPressed: () => setState(() => _isGridView = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.view_list_rounded, size: 15),
                      tooltip: 'Compact List View',
                      visualDensity: VisualDensity.compact,
                      color: !_isGridView
                          ? GlassColors.violetLight
                          : GlassColors.textSubtle,
                      onPressed: () => setState(() => _isGridView = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. ANIMATED EFFECT TILES
          _buildEffectTilesGrid(ble),
        ],
      ),
    );
  }

  Widget _buildEffectTilesGrid(BleLedService ble) {
    final List<Widget> tiles = [];
    final safetyOn = ble.reduceFlashing;

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
            Color.lerp(
              const Color(0xFF00FF88),
              const Color(0xFF7C4DFF),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
            Color.lerp(
              const Color(0xFF00D2FF),
              const Color(0xFF00FF88),
              (cos(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFFFF2200),
              const Color(0xFFFF8800),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFFFF007F),
              const Color(0xFF00F0FF),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFF4A0E4E),
              const Color(0xFFFF5722),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFF1B5E20),
              const Color(0xFF00E676),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFF0D083B),
              const Color(0xFFE040FB),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFFE0F7FA),
              const Color(0xFF00E5FF),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            HSVColor.fromAHSV(1.0, ((p + 0.3) * 360.0) % 360.0, 1.0, 1.0)
                .toColor(),
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
            Color.lerp(
              const Color(0xFF001F3F),
              const Color(0xFF00D2FF),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFFFF9900),
              const Color(0xFFFF5500),
              (sin(p * 6 * pi) + 1) / 2,
            )!,
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
            Color.lerp(
              const Color(0xFFFF3A00),
              const Color(0xFFFFB300),
              (sin(p * 8 * pi) + 1) / 2,
            )!,
            const Color(0xFFB71C1C),
          ],
        ),
        AnimatedEffectTile(
          title: '4-7-8 Breathing Guide',
          subtitle:
              'Relaxation pacing: 4s inhale cyan, 7s hold blue, 8s exhale amber.',
          badge: 'WELLNESS',
          icon: Icons.spa_rounded,
          isActive: ble.activeScene == ActiveScene.breath478,
          onTap: () => ble.startScene(ActiveScene.breath478),
          colorGenerator: (p) => [
            Color.lerp(
              const Color(0xFF00F0FF),
              const Color(0xFF9C27B0),
              (sin(p * 2 * pi) + 1) / 2,
            )!,
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
          isStrobeWarning: true,
          isDisabledBySafety: safetyOn,
          isActive: ble.activeScene == ActiveScene.neonFlicker,
          onTap: () => ble.startScene(ActiveScene.neonFlicker),
          colorGenerator: (p) => [
            ((p * 12).toInt() % 3 == 0)
                ? const Color(0xFFFF007F)
                : const Color(0xFF220011),
            const Color(0xFF440022),
          ],
        ),
        AnimatedEffectTile(
          title: 'Lightning',
          subtitle: 'Sudden high-voltage thunderstorm flash burst.',
          badge: 'BURST',
          icon: Icons.bolt_rounded,
          isStrobeWarning: true,
          isDisabledBySafety: safetyOn,
          isActive: ble.activeScene == ActiveScene.lightning,
          onTap: () => ble.startScene(ActiveScene.lightning),
          colorGenerator: (p) => [
            ((p * 10).toInt() % 5 == 0)
                ? Colors.white
                : const Color(0xFF0D0D1A),
            const Color(0xFF1A1A33),
          ],
        ),
        AnimatedEffectTile(
          title: 'Police',
          subtitle: 'Alternating high-visibility red and blue emergency flash.',
          badge: 'STROBE',
          icon: Icons.local_police_rounded,
          isStrobeWarning: true,
          isDisabledBySafety: safetyOn,
          isActive: ble.activeScene == ActiveScene.police,
          onTap: () => ble.startScene(ActiveScene.police),
          colorGenerator: (p) => [
            ((p * 8).toInt() % 2 == 0)
                ? const Color(0xFFFF0000)
                : const Color(0xFF0000FF),
            Colors.black,
          ],
        ),
        AnimatedEffectTile(
          title: 'Party',
          subtitle: 'Upbeat high-tempo chromatic disco rave pulses.',
          badge: 'PARTY',
          icon: Icons.celebration_rounded,
          isStrobeWarning: true,
          isDisabledBySafety: safetyOn,
          isActive: ble.activeScene == ActiveScene.party,
          onTap: () => ble.startScene(ActiveScene.party),
          colorGenerator: (p) => [
            HSVColor.fromAHSV(
              1.0,
              ((p * 720.0).toInt() % 360).toDouble(),
              1.0,
              1.0,
            ).toColor(),
            Colors.black,
          ],
        ),
      ]);
    }

    // Hardware Modes Section
    if (_selectedSection == 'Hardware Modes' || _selectedSection == 'All') {
      for (final mode in ElkEffectCatalog.modes) {
        final isStrobe = mode.category == 'Strobe' || mode.category == 'Flash';
        tiles.add(
          AnimatedEffectTile(
            title: mode.name,
            subtitle: mode.description,
            badge: mode.hexId,
            icon: Icons.memory_rounded,
            isStrobeWarning: isStrobe,
            isDisabledBySafety: safetyOn && isStrobe,
            isActive:
                ble.activeScene == ActiveScene.none &&
                ble.currentEffectMode == mode.id,
            onTap: () => ble.sendHardwareEffect(mode.id),
            colorGenerator: (p) => [
              _getHardwareModeColor(mode.id, p),
              _getHardwareModeColor(mode.id, p + 0.3),
            ],
          ),
        );
      }
    }

    if (!_isGridView) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => SizedBox(
          height: 58,
          child: tiles[index],
        ),
      );
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
    return HSVColor.fromAHSV(1.0, ((progress * 360.0) % 360.0), 1.0, 1.0)
        .toColor();
  }
}
