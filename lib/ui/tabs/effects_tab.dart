import 'package:flutter/material.dart';
import '../../protocol/elk_protocol.dart';
import '../../services/ble_led_service.dart';
import '../widgets/glowing_card.dart';

class EffectsTab extends StatefulWidget {
  final BleLedService bleService;

  const EffectsTab({super.key, required this.bleService});

  @override
  State<EffectsTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectsTab> {
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Crossfade',
    'Fade',
    'Strobe',
    'Jump',
    'Smooth',
    'Flash',
  ];

  @override
  Widget build(BuildContext context) {
    final ble = widget.bleService;
    final allModes = ElkEffectCatalog.modes;
    final filteredModes = _selectedCategory == 'All'
        ? allModes
        : allModes.where((m) => m.category == _selectedCategory).toList();

    final activeEffect = ElkEffectCatalog.getById(ble.currentEffectMode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ACTIVE HARDWARE EFFECT BANNER
          GlowingCard(
            glowColor: const Color(0xFF8B5CF6),
            isGlowing: ble.isPoweredOn && ble.activeScene == ActiveScene.none,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                  ),
                  child: const Center(
                    child: Icon(Icons.blur_linear_rounded, color: Color(0xFFA78BFA), size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CURRENT HARDWARE EFFECT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Color(0xFFA78BFA),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activeEffect.hexId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC4B5FD),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeEffect.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        activeEffect.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. HARDWARE EFFECT SPEED SLIDER
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed_rounded, size: 18, color: Color(0xFF06B6D4)),
                        SizedBox(width: 8),
                        Text(
                          'HARDWARE EFFECT SPEED (1..100)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ble.currentEffectSpeed}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.directions_walk_rounded, size: 18, color: Color(0xFF71717A)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF06B6D4),
                          inactiveTrackColor: const Color(0xFF27272A),
                          thumbColor: const Color(0xFF06B6D4),
                          overlayColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                          trackHeight: 5,
                        ),
                        child: Slider(
                          value: ble.currentEffectSpeed.toDouble(),
                          min: 1,
                          max: 100,
                          onChanged: (val) {
                            ble.sendEffectSpeed(val.round());
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF06B6D4)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. CATEGORY FILTER CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B5CF6),
                    backgroundColor: const Color(0xFF18181B),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF27272A),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 4. EFFECTS GRID (29 BUILT-IN MODES 0x80 TO 0x9C)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredModes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
            ),
            itemBuilder: (context, index) {
              final mode = filteredModes[index];
              final isCurrent = ble.currentEffectMode == mode.id;

              return GlowingCard(
                glowColor: const Color(0xFF8B5CF6),
                isGlowing: isCurrent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => ble.sendHardwareEffect(mode.id),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                            : const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(mode.category),
                        size: 20,
                        color: isCurrent ? const Color(0xFFC4B5FD) : const Color(0xFFA1A1AA),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                mode.hexId,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? const Color(0xFFA78BFA) : const Color(0xFF71717A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27272A),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  mode.category,
                                  style: const TextStyle(fontSize: 9, color: Color(0xFFA1A1AA)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mode.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : const Color(0xFFD4D4D8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Crossfade':
        return Icons.gradient_rounded;
      case 'Fade':
        return Icons.waves_rounded;
      case 'Strobe':
        return Icons.flash_on_rounded;
      case 'Jump':
        return Icons.sync_alt_rounded;
      case 'Smooth':
        return Icons.stream_rounded;
      case 'Flash':
        return Icons.flare_rounded;
      default:
        return Icons.tune_rounded;
    }
  }
}
