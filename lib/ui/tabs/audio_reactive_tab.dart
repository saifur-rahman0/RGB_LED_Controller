import 'package:flutter/material.dart';
import '../../services/audio_reactive_service.dart';
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
              // 1. MASTER AUDIO CONTROLLER BANNER (MINIMAL)
              GlowingCard(
                glowColor: renderedColor,
                isGlowing: isRunning,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? renderedColor : const Color(0xFF27272A),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: renderedColor.withValues(alpha: 0.65),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          isRunning ? Icons.music_note_rounded : Icons.music_off_rounded,
                          color: isRunning
                              ? (ThemeData.estimateBrightnessForColor(renderedColor) == Brightness.dark
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
                                isRunning ? 'AUDIO VISUALIZER ACTIVE' : 'AUDIO VISUALIZER STANDBY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
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
                          const SizedBox(height: 1),
                          Text(
                            isRunning
                                ? 'Mode: ${audioService.mode.label} • Auto-Gain Dynamic'
                                : 'Pulse and animate lights in sync with music and game audio',
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
                      onPressed: () => audioService.toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. LIVE SPECTRUM TELEMETRY (COMPACT)
              GlowingCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.equalizer_rounded, size: 16, color: Color(0xFF06B6D4)),
                            SizedBox(width: 6),
                            Text(
                              'SPECTRUM TELEMETRY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                          ],
                        ),
                        // Beat Indicator Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: audioService.isBeat
                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                : const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: audioService.isBeat ? const Color(0xFFEF4444) : const Color(0xFF3F3F46),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                size: 11,
                                color: audioService.isBeat ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                audioService.isBeat ? 'BEAT' : 'IDLE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: audioService.isBeat ? const Color(0xFFF87171) : const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4 Band Level Meters
                    _buildBandMeter('BASS (20-250Hz)', audioService.bassLevel, const Color(0xFFEF4444)),
                    const SizedBox(height: 6),
                    _buildBandMeter('MIDS (250-2000Hz)', audioService.midLevel, const Color(0xFF10B981)),
                    const SizedBox(height: 6),
                    _buildBandMeter('TREBLE (2-8kHz)', audioService.highLevel, const Color(0xFF38BDF8)),
                    const SizedBox(height: 6),
                    _buildBandMeter('OVERALL LOUDNESS', audioService.overallLevel, const Color(0xFFA855F7)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. REACTIVE MODE SELECTOR CARDS (SMALL MINIMAL CARDS)
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 850
                      ? 3
                      : constraints.maxWidth > 550
                          ? 2
                          : 1;
                  final childAspectRatio = constraints.maxWidth > 850 ? 3.5 : 2.9;

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
                        glowColor: const Color(0xFF06B6D4),
                        isGlowing: isSelected,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        onTap: () => audioService.setMode(mode),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                                    : const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                mode.icon,
                                size: 16,
                                color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFA1A1AA),
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
                                      color: isSelected ? Colors.white : const Color(0xFFE4E4E7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    mode.description,
                                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF8E8E93), height: 1.2),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF06B6D4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF06B6D4),
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

              // 4. TUNING SLIDERS (COMPACT)
              GlowingCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 16, color: Color(0xFFFBBF24)),
                        SizedBox(width: 6),
                        Text(
                          'GAIN & RESPONSE CONTROLS',
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

                    // Sensitivity Slider
                    _buildSliderRow(
                      context,
                      label: 'Microphone Sensitivity',
                      value: '${audioService.sensitivity.toInt()}%',
                      current: audioService.sensitivity,
                      min: 1.0,
                      max: 100.0,
                      activeColor: const Color(0xFFFBBF24),
                      onChanged: (v) => audioService.setSensitivity(v),
                    ),
                    const SizedBox(height: 8),

                    // Smoothing Slider
                    _buildSliderRow(
                      context,
                      label: 'Release Smoothing',
                      value: '${audioService.smoothing.toInt()}%',
                      current: audioService.smoothing,
                      min: 0.0,
                      max: 100.0,
                      activeColor: const Color(0xFF06B6D4),
                      onChanged: (v) => audioService.setSmoothing(v),
                    ),
                    const SizedBox(height: 8),

                    // Minimum Glow Floor Slider
                    _buildSliderRow(
                      context,
                      label: 'Silence Floor Glow',
                      value: '${audioService.minGlowFloor.toInt()}%',
                      current: audioService.minGlowFloor,
                      min: 0.0,
                      max: 30.0,
                      activeColor: const Color(0xFF10B981),
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
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: activeColor),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: const Color(0xFF27272A),
            thumbColor: activeColor,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
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
              style: const TextStyle(fontSize: 10, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500),
            ),
            Text(
              '${(clamped * 100).toInt()}%',
              style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 4,
            backgroundColor: const Color(0xFF27272A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
