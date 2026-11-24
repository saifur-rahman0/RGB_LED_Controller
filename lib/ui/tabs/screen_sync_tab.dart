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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MASTER SCREEN SYNC CONTROLLER BANNER
              GlowingCard(
                glowColor: activeColor,
                isGlowing: isRunning,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Glowing circular indicator
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? activeColor : const Color(0xFF27272A),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.65),
                                  blurRadius: 24,
                                  spreadRadius: 3,
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
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isRunning ? 'AMBILIGHT SCREEN SYNC ACTIVE' : 'SCREEN SYNC STANDBY',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: isRunning ? const Color(0xFF10B981) : const Color(0xFF71717A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRunning ? const Color(0xFF10B981) : const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isRunning
                                ? 'Sampling display at 15 FPS via Win32 hardware acceleration'
                                : 'Synchronize your LED strip to the dominant colors of your screen',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : const Color(0xFF10B981).withValues(alpha: 0.2),
                        foregroundColor: isRunning ? const Color(0xFFF87171) : const Color(0xFF34D399),
                        side: BorderSide(
                          color: isRunning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        isRunning ? 'Stop Sync' : 'Start Sync',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => screenSync.toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. CAPTURE AREA & ALGORITHM CONFIGURATION
              GlowingCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.crop_free_rounded, size: 18, color: Color(0xFF38BDF8)),
                        SizedBox(width: 8),
                        Text(
                          'SCREEN SAMPLING GEOMETRY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Area Selector Dropdown
                    Row(
                      children: [
                        const SizedBox(
                          width: 130,
                          child: Text(
                            'Sample Area:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3F3F46)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ScreenSyncArea>(
                                value: screenSync.area,
                                dropdownColor: const Color(0xFF1C1C20),
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                                style: const TextStyle(fontSize: 13, color: Colors.white),
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
                    const SizedBox(height: 6),
                    Text(
                      screenSync.area.description,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF27272A)),
                    const SizedBox(height: 10),

                    // Ignore Black Bars Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: const Color(0xFF38BDF8),
                      title: const Text(
                        'Ignore Black Bars (Letterbox / Pillarbox Crop)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Automatically trims dark cinema bars on widescreen films so active movie colors are matched.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
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
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Preserves a subtle warm ambient glow during dark/black scenes and DRM-protected media.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
                      ),
                      value: screenSync.keepDimGlow,
                      onChanged: (val) => screenSync.setKeepDimGlow(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. COLOR TUNING (SATURATION BOOST & SMOOTHING)
              GlowingCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: Color(0xFFA855F7)),
                        SizedBox(width: 8),
                        Text(
                          'COLOR & TRANSITION TUNING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Saturation Boost Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saturation Boost',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${screenSync.saturationBoost.toStringAsFixed(1)}x',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFA855F7)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFA855F7),
                        inactiveTrackColor: const Color(0xFF27272A),
                        thumbColor: const Color(0xFFA855F7),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: screenSync.saturationBoost,
                        min: 1.0,
                        max: 2.5,
                        divisions: 15,
                        onChanged: (val) => screenSync.setSaturationBoost(val),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Smoothing Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Color Smoothing (Responsiveness vs Calm)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${(screenSync.smoothingAlpha * 100).toInt()}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF06B6D4),
                        inactiveTrackColor: const Color(0xFF27272A),
                        thumbColor: const Color(0xFF06B6D4),
                        trackHeight: 4,
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
              const SizedBox(height: 20),

              // 4. DRM & PERFORMANCE NOTE
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFFBBF24)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Note on Protected Media (DRM): Hardware-protected streams (e.g. Netflix, Disney+ app) render as black surfaces in Windows capture. Games, desktop apps, YouTube, and video players (VLC, MPV) are fully captured.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA), height: 1.3),
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
