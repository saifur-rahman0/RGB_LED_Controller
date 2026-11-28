import 'package:flutter/material.dart';
import '../../services/audio_reactive_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glowing_card.dart';

class AudioReactiveTab extends StatelessWidget {
  final AudioReactiveService audioService;

  const AudioReactiveTab({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: audioService,
      builder: (context, _) {
        final isRunning = audioService.isRunning;
        final renderedColor = audioService.renderedColor;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MASTER AUDIO CONTROLLER BANNER
              GlowingCard(
                glowColor: renderedColor,
                isGlowing: isRunning,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning
                            ? renderedColor
                            : GlassColors.borderDefault,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: renderedColor.withValues(alpha: 0.65),
                                  blurRadius: 24,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: renderedColor.withValues(alpha: 0.9),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          isRunning
                              ? Icons.music_note_rounded
                              : Icons.music_off_rounded,
                          color: isRunning
                              ? (ThemeData.estimateBrightnessForColor(
                                          renderedColor,
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
                                    ? 'AUDIO VISUALIZER ACTIVE'
                                    : 'AUDIO VISUALIZER STANDBY',
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
                                width: 6,
                                height: 6,
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
                                ? 'Mode: ${audioService.mode.label} • Auto-Gain Dynamic'
                                : 'Pulse and animate lights in sync with music and game audio',
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
                      onPressed: () => audioService.toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. LIVE SPECTRUM TELEMETRY (3-BAND VERTICAL VISUALIZER + BAND METERS)
              GlowingCard(
                glowColor: GlassColors.cyan,
                isGlowing: isRunning && audioService.isBeat,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassSectionHeader(
                      icon: Icons.equalizer_rounded,
                      title: 'SPECTRUM TELEMETRY',
                      accentColor: GlassColors.cyan,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: audioService.isBeat
                              ? GlassColors.offline.withValues(alpha: 0.28)
                              : GlassColors.borderDefault,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: audioService.isBeat
                                ? GlassColors.offline
                                : GlassColors.borderRaised,
                          ),
                          boxShadow: audioService.isBeat
                              ? [
                                  BoxShadow(
                                    color: GlassColors.offline.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              size: 11,
                              color: audioService.isBeat
                                  ? GlassColors.offline
                                  : GlassColors.textSubtle,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              audioService.isBeat ? 'BEAT' : 'IDLE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: audioService.isBeat
                                    ? GlassColors.offlineLight
                                    : GlassColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Responsive 3-band Vertical Bars + Horizontal Detail Meters
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vertical Spectrum Bars (Bass / Mid / Treble)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: GlassColors.canvas.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: GlassColors.borderDefault,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildVerticalSpectrumBar(
                                'BASS',
                                audioService.bassLevel,
                                GlassColors.offline,
                              ),
                              const SizedBox(width: 10),
                              _buildVerticalSpectrumBar(
                                'MID',
                                audioService.midLevel,
                                GlassColors.violet,
                              ),
                              const SizedBox(width: 10),
                              _buildVerticalSpectrumBar(
                                'HIGH',
                                audioService.highLevel,
                                GlassColors.scanning,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Horizontal Band Level Meters
                        Expanded(
                          child: Column(
                            children: [
                              _buildBandMeter(
                                'BASS (20–250Hz)',
                                audioService.bassLevel,
                                GlassColors.offline,
                              ),
                              const SizedBox(height: 6),
                              _buildBandMeter(
                                'MIDS (250–2000Hz)',
                                audioService.midLevel,
                                GlassColors.connected,
                              ),
                              const SizedBox(height: 6),
                              _buildBandMeter(
                                'TREBLE (2–8kHz)',
                                audioService.highLevel,
                                GlassColors.scanning,
                              ),
                              const SizedBox(height: 6),
                              _buildBandMeter(
                                'OVERALL LOUDNESS',
                                audioService.overallLevel,
                                GlassColors.purple,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. REACTIVE MODE SELECTOR CARDS (SMALL MINIMAL GLASS CARDS)
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 850
                      ? 3
                      : constraints.maxWidth > 550
                          ? 2
                          : 1;
                  final childAspectRatio =
                      constraints.maxWidth > 850 ? 3.5 : 2.9;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: childAspectRatio,
                    children: AudioReactiveMode.values.map((mode) {
                      final isSelected = audioService.mode == mode;

                      return GlowingCard(
                        glowColor: GlassColors.cyan,
                        isGlowing: isSelected,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        onTap: () => audioService.setMode(mode),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? GlassColors.cyan.withValues(alpha: 0.25)
                                    : GlassColors.borderDefault,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? GlassColors.cyan.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                mode.icon,
                                size: 16,
                                color: isSelected
                                    ? GlassColors.cyan
                                    : GlassColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mode.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFE4E4E7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    mode.description,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFF8E8E93),
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: GlassColors.cyan,
                                  boxShadow: [
                                    BoxShadow(
                                      color: GlassColors.cyan,
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 4. TUNING SLIDERS
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
                      title: 'GAIN & RESPONSE CONTROLS',
                      accentColor: GlassColors.connecting,
                    ),
                    const SizedBox(height: 10),

                    _buildSliderRow(
                      context,
                      label: 'Microphone Sensitivity',
                      value: '${audioService.sensitivity.toInt()}%',
                      current: audioService.sensitivity,
                      min: 1.0,
                      max: 100.0,
                      activeColor: GlassColors.connecting,
                      onChanged: (v) => audioService.setSensitivity(v),
                    ),
                    const SizedBox(height: 6),

                    _buildSliderRow(
                      context,
                      label: 'Release Smoothing',
                      value: '${audioService.smoothing.toInt()}%',
                      current: audioService.smoothing,
                      min: 0.0,
                      max: 100.0,
                      activeColor: GlassColors.cyan,
                      onChanged: (v) => audioService.setSmoothing(v),
                    ),
                    const SizedBox(height: 6),

                    _buildSliderRow(
                      context,
                      label: 'Silence Floor Glow',
                      value: '${audioService.minGlowFloor.toInt()}%',
                      current: audioService.minGlowFloor,
                      min: 0.0,
                      max: 30.0,
                      activeColor: GlassColors.connected,
                      onChanged: (v) => audioService.setMinGlowFloor(v),
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

  Widget _buildVerticalSpectrumBar(String label, double level, Color accent) {
    final clamped = level.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${(clamped * 100).toInt()}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: 68,
          decoration: BoxDecoration(
            color: GlassColors.base,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: GlassColors.borderDefault),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: 20,
            height: 68 * clamped,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  accent.withValues(alpha: 0.45),
                  accent,
                ],
              ),
              boxShadow: clamped > 0.15
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: GlassColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required String label,
    required String value,
    required double current,
    required double min,
    required double max,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: buildNeonSliderTheme(context, activeColor),
          child: Slider(
            value: current,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBandMeter(String label, double level, Color color) {
    final clamped = level.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: GlassColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(clamped * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 4,
            backgroundColor: GlassColors.borderDefault,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
