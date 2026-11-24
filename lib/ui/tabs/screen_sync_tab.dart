import 'package:flutter/material.dart';
import '../../services/screen_sync_service.dart';
import '../widgets/glowing_card.dart';

class ScreenSyncTab extends StatelessWidget {
  final ScreenSyncService screenSync;

  const ScreenSyncTab({super.key, required this.screenSync});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: screenSync,
      builder: (context, _) {
        final isRunning = screenSync.isRunning;
        final activeColor = screenSync.smoothedColor;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MASTER SCREEN SYNC CONTROLLER BANNER (MINIMAL)
              GlowingCard(
                glowColor: activeColor,
                isGlowing: isRunning,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Glowing circular indicator
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? activeColor : const Color(0xFF27272A),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.65),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          isRunning ? Icons.tv_rounded : Icons.tv_off_rounded,
                          color: isRunning
                              ? (ThemeData.estimateBrightnessForColor(activeColor) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                              : const Color(0xFF71717A),
                          size: 18,
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
                              Text(
                                isRunning ? 'AMBILIGHT SCREEN SYNC ACTIVE' : 'SCREEN SYNC STANDBY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isRunning ? const Color(0xFF10B981) : const Color(0xFF71717A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRunning ? const Color(0xFF10B981) : const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isRunning
                                ? 'Sampling at 15 FPS via Win32 GDI acceleration'
                                : 'Sync lights with dominant screen colors',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : const Color(0xFF10B981).withValues(alpha: 0.2),
                        foregroundColor: isRunning ? const Color(0xFFF87171) : const Color(0xFF34D399),
                        side: BorderSide(
                          color: isRunning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 16),
                      label: Text(
                        isRunning ? 'Stop' : 'Start',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () => screenSync.toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. CAPTURE AREA & ALGORITHM CONFIGURATION (COMPACT)
              GlowingCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.crop_free_rounded, size: 16, color: Color(0xFF38BDF8)),
                        SizedBox(width: 6),
                        Text(
                          'SCREEN SAMPLING GEOMETRY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Area Selector Dropdown
                    Row(
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text(
                            'Sample Area:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF3F3F46)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ScreenSyncArea>(
                                value: screenSync.area,
                                dropdownColor: const Color(0xFF1C1C20),
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 18),
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                items: ScreenSyncArea.values.map((area) {
                                  return DropdownMenuItem(
                                    value: area,
                                    child: Text(area.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) screenSync.setArea(val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      screenSync.area.description,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF71717A)),
                    ),

                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFF27272A)),
                    const SizedBox(height: 6),

                    // Ignore Black Bars Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: const Color(0xFF38BDF8),
                      title: const Text(
                        'Ignore Black Bars (Cinema Crop)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 11.5),
                      ),
                      subtitle: const Text(
                        'Automatically trims dark cinema bars on widescreen films.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFFA1A1AA)),
                      ),
                      value: screenSync.cropBlackBars,
                      onChanged: (val) => screenSync.setCropBlackBars(val),
                    ),

                    // Keep Dim Glow Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: const Color(0xFFFBBF24),
                      title: const Text(
                        'Keep Dim Glow on Dark Scenes',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 11.5),
                      ),
                      subtitle: const Text(
                        'Preserves a subtle warm glow during dark media.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFFA1A1AA)),
                      ),
                      value: screenSync.keepDimGlow,
                      onChanged: (val) => screenSync.setKeepDimGlow(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. COLOR TUNING (COMPACT)
              GlowingCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 16, color: Color(0xFFA855F7)),
                        SizedBox(width: 6),
                        Text(
                          'COLOR & TRANSITION TUNING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Saturation Boost Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saturation Boost',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${screenSync.saturationBoost.toStringAsFixed(1)}x',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFA855F7)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFA855F7),
                        inactiveTrackColor: const Color(0xFF27272A),
                        thumbColor: const Color(0xFFA855F7),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: screenSync.saturationBoost,
                        min: 1.0,
                        max: 2.5,
                        divisions: 15,
                        onChanged: (val) => screenSync.setSaturationBoost(val),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Smoothing Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Color Smoothing',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${(screenSync.smoothingAlpha * 100).toInt()}%',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
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
                        value: screenSync.smoothingAlpha,
                        min: 0.15,
                        max: 0.85,
                        divisions: 14,
                        onChanged: (val) => screenSync.setSmoothingAlpha(val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. DRM & PERFORMANCE NOTE (COMPACT)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFFBBF24)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: Protected media (Netflix app, Disney+ app) render black in Windows capture. Desktop apps, games, YouTube, and media players (VLC) are fully supported.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFFA1A1AA), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
