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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MASTER AUDIO CONTROLLER BANNER
              GlowingCard(
                glowColor: renderedColor,
                isGlowing: isRunning,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? renderedColor : const Color(0xFF27272A),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: renderedColor.withValues(alpha: 0.65),
                                  blurRadius: 24,
                                  spreadRadius: 3,
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
                                isRunning ? 'AUDIO REACTIVE VISUALIZER ACTIVE' : 'AUDIO VISUALIZER STANDBY',
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
                                ? 'Mode: ${audioService.mode.label} • Dynamic Auto-Gain Active'
                                : 'Pulse and animate lights in sync with music and game audio',
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
                        isRunning ? 'Stop Visualizer' : 'Start Visualizer',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => audioService.toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. LIVE EQUALIZER & VU LEVEL TELEMETRY
              GlowingCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.equalizer_rounded, size: 18, color: Color(0xFF06B6D4)),
                            SizedBox(width: 8),
                            Text(
                              'REAL-TIME SPECTRUM TELEMETRY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                          ],
                        ),
                        // Beat Indicator Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: audioService.isBeat
                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                : const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: audioService.isBeat ? const Color(0xFFEF4444) : const Color(0xFF3F3F46),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                size: 12,
                                color: audioService.isBeat ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                audioService.isBeat ? 'DRUM BEAT PEAK' : 'RHYTHM IDLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: audioService.isBeat ? const Color(0xFFF87171) : const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3 Band Level Meters (Bass, Mid, High)
                    _buildBandMeter('BASS (20-250Hz)', audioService.bassLevel, const Color(0xFFEF4444)),
                    const SizedBox(height: 8),
                    _buildBandMeter('MIDS (250-2000Hz)', audioService.midLevel, const Color(0xFF10B981)),
                    const SizedBox(height: 8),
                    _buildBandMeter('TREBLE (2-8kHz)', audioService.highLevel, const Color(0xFF38BDF8)),
                    const SizedBox(height: 8),
                    _buildBandMeter('OVERALL LOUDNESS', audioService.overallLevel, const Color(0xFFA855F7)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. REACTIVE MODE SELECTOR CARDS
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.2,
                children: AudioReactiveMode.values.map((mode) {
                  final isSelected = audioService.mode == mode;
                  return GlowingCard(
                    glowColor: const Color(0xFF06B6D4),
                    isGlowing: isSelected,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => audioService.setMode(mode),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                                : const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            mode.icon,
                            size: 22,
                            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFA1A1AA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFFE4E4E7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mode.description,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFFA1A1AA), height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 4. TUNING SLIDERS (SENSITIVITY, SMOOTHING, FLOOR)
              GlowingCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: Color(0xFFFBBF24)),
                        SizedBox(width: 8),
                        Text(
                          'DYNAMIC GAIN & RESPONSE CONTROLS',
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

                    // Sensitivity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Microphone / Loopback Sensitivity',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${audioService.sensitivity.toInt()}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFBBF24),
                        inactiveTrackColor: const Color(0xFF27272A),
                        thumbColor: const Color(0xFFFBBF24),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: audioService.sensitivity,
                        min: 1.0,
                        max: 100.0,
                        onChanged: (val) => audioService.setSensitivity(val),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Smoothing Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Release Smoothing (Snappy vs Calm)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${audioService.smoothing.toInt()}%',
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
                        value: audioService.smoothing,
                        min: 0.0,
                        max: 100.0,
                        onChanged: (val) => audioService.setSmoothing(val),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minimum Glow Floor Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Silence Ambient Floor Glow',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${audioService.minGlowFloor.toInt()}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveTrackColor: const Color(0xFF27272A),
                        thumbColor: const Color(0xFF10B981),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: audioService.minGlowFloor,
                        min: 0.0,
                        max: 30.0,
                        onChanged: (val) => audioService.setMinGlowFloor(val),
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

  Widget _buildBandMeter(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF71717A))),
            Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF27272A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
