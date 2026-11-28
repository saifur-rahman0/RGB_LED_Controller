import 'package:flutter/material.dart';
import '../../services/screen_sync_service.dart';
import '../theme/glass_theme.dart';
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
              // 1. MASTER SCREEN SYNC CONTROLLER BANNER
              GlowingCard(
                glowColor: activeColor,
                isGlowing: isRunning,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Dual-halo neon circular indicator
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning
                            ? activeColor
                            : GlassColors.borderDefault,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.65),
                                  blurRadius: 24,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.9),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          isRunning ? Icons.tv_rounded : Icons.tv_off_rounded,
                          color: isRunning
                              ? (ThemeData.estimateBrightnessForColor(
                                          activeColor,
                                        ) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black)
                              : GlassColors.textSubtle,
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
                              Text(
                                isRunning
                                    ? 'AMBILIGHT SCREEN SYNC ACTIVE'
                                    : 'SCREEN SYNC STANDBY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isRunning
                                      ? GlassColors.connected
                                      : GlassColors.textSubtle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRunning
                                      ? GlassColors.connected
                                      : GlassColors.textSubtle,
                                  boxShadow: isRunning
                                      ? [
                                          const BoxShadow(
                                            color: GlassColors.connected,
                                            blurRadius: 5,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isRunning
                                ? 'Sampling at 15 FPS via Win32 GDI acceleration'
                                : 'Sync lights with dominant screen colors',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: GlassColors.textMuted,
                            ),
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
                            ? GlassColors.offline.withValues(alpha: 0.2)
                            : GlassColors.connected.withValues(alpha: 0.2),
                        foregroundColor: isRunning
                            ? GlassColors.offlineLight
                            : GlassColors.connectedLight,
                        side: BorderSide(
                          color: isRunning
                              ? GlassColors.offline
                              : GlassColors.connected,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        isRunning
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isRunning ? 'Stop' : 'Start',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      onPressed: () => screenSync.toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. CAPTURE AREA & ALGORITHM CONFIGURATION
              GlowingCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassSectionHeader(
                      icon: Icons.crop_free_rounded,
                      title: 'SCREEN SAMPLING GEOMETRY',
                      accentColor: GlassColors.scanning,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text(
                            'Sample Area:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: GlassColors.elevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: GlassColors.borderRaised,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ScreenSyncArea>(
                                value: screenSync.area,
                                dropdownColor: GlassColors.elevated,
                                icon: const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
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
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: GlassColors.textSubtle,
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(color: GlassColors.borderDefault),
                    const SizedBox(height: 4),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeThumbColor: GlassColors.scanning,
                      title: const Text(
                        'Ignore Black Bars (Cinema Crop)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Automatically trims dark cinema bars on widescreen films.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: GlassColors.textMuted,
                        ),
                      ),
                      value: screenSync.cropBlackBars,
                      onChanged: (val) => screenSync.setCropBlackBars(val),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeThumbColor: GlassColors.connecting,
                      title: const Text(
                        'Keep Dim Glow on Dark Scenes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Preserves a subtle warm glow during dark media.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: GlassColors.textMuted,
                        ),
                      ),
                      value: screenSync.keepDimGlow,
                      onChanged: (val) => screenSync.setKeepDimGlow(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. COLOR TUNING
              GlowingCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassSectionHeader(
                      icon: Icons.tune_rounded,
                      title: 'COLOR & TRANSITION TUNING',
                      accentColor: GlassColors.purple,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saturation Boost',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${screenSync.saturationBoost.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: GlassColors.purple,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: buildNeonSliderTheme(context, GlassColors.purple),
                      child: Slider(
                        value: screenSync.saturationBoost,
                        min: 1.0,
                        max: 2.5,
                        divisions: 15,
                        onChanged: (val) => screenSync.setSaturationBoost(val),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Color Smoothing',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${(screenSync.smoothingAlpha * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: GlassColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: buildNeonSliderTheme(context, GlassColors.cyan),
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

              // 4. DRM & PERFORMANCE NOTE
              GlowingCard(
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: GlassColors.connecting,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: Protected media (Netflix app, Disney+ app) render black in Windows capture. Desktop apps, games, YouTube, and media players (VLC) are fully supported.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: GlassColors.textMuted,
                          height: 1.35,
                        ),
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
