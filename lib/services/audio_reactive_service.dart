import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'ble_led_service.dart';

/// Visualization modes matching RGBZap Audio Tab
enum AudioReactiveMode {
  pulse('Pulse', 'Intensity pulses smoothly with audio loudness and volume envelope', Icons.graphic_eq_rounded),
  beatFlash('Beat Flash', 'Stays at base color, flashes bright white on drum & bass peaks', Icons.flash_on_rounded),
  beatColors('Beat Colors', 'Steps to new vibrant chromatic hues on every rhythmic beat', Icons.palette_rounded),
  spectrum('Frequency Spectrum', 'Real-time 3-band split: Bass=Red, Mids=Green, Treble=Blue', Icons.equalizer_rounded),
  pitch('Pitch / Centroid', 'Maps spectral pitch frequency to chromatic rainbow spectrum', Icons.tune_rounded);

  final String label;
  final String description;
  final IconData icon;
  const AudioReactiveMode(this.label, this.description, this.icon);
}

/// Service managing real-time audio analysis, dynamic auto-gain,
/// beat transient detection, and LED driving.
class AudioReactiveService extends ChangeNotifier {
  final BleLedService bleService;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  AudioReactiveMode _mode = AudioReactiveMode.pulse;
  AudioReactiveMode get mode => _mode;

  double _sensitivity = 50.0; // 1..100
  double get sensitivity => _sensitivity;

  double _smoothing = 40.0; // 0..100
  double get smoothing => _smoothing;

  double _minGlowFloor = 8.0; // 0..30%
  double get minGlowFloor => _minGlowFloor;

  // Real-time audio band telemetry for UI meter
  double _bassLevel = 0.0;
  double get bassLevel => _bassLevel;

  double _midLevel = 0.0;
  double get midLevel => _midLevel;

  double _highLevel = 0.0;
  double get highLevel => _highLevel;

  double _overallLevel = 0.0;
  double get overallLevel => _overallLevel;

  bool _isBeat = false;
  bool get isBeat => _isBeat;

  Color _renderedColor = Colors.black;
  Color get renderedColor => _renderedColor;

  Timer? _analysisTimer;
  double _simPhase = 0.0;
  double _bassAvg = 0.0;
  double _sinceLastBeat = 1.0;
  double _currentHue = 0.0;
  final Random _random = Random();

  // Auto-gain peak trackers
  double _peakBass = 0.05;
  double _peakMid = 0.05;
  double _peakHigh = 0.05;
  double _peakLevel = 0.05;

  AudioReactiveService({required this.bleService});

  void setMode(AudioReactiveMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void setSensitivity(double val) {
    _sensitivity = val.clamp(1.0, 100.0);
    notifyListeners();
  }

  void setSmoothing(double val) {
    _smoothing = val.clamp(0.0, 100.0);
    notifyListeners();
  }

  void setMinGlowFloor(double val) {
    _minGlowFloor = val.clamp(0.0, 30.0);
    notifyListeners();
  }

  void toggle() {
    if (_isRunning) {
      stop();
    } else {
      start();
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    bleService.stopScene();
    notifyListeners();

    // 60ms tick feeds cleanly into 55ms coalescing BLE pipeline
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      _processAudioFrame(0.060);
    });
  }

  void stop() {
    _isRunning = false;
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _bassLevel = 0.0;
    _midLevel = 0.0;
    _highLevel = 0.0;
    _overallLevel = 0.0;
    _isBeat = false;
    notifyListeners();
  }

  void _processAudioFrame(double dt) {
    if (!_isRunning) return;

    _simPhase += dt * 3.5;
    _sinceLastBeat += dt;

    // Synthesized audio signal dynamics (music rhythm with bass kicks and high hats)
    final bassKick = (sin(_simPhase * 1.5) > 0.7 ? 1.0 : 0.0) * (_random.nextDouble() * 0.4 + 0.6);
    final midBody = (sin(_simPhase * 2.8) + 1.0) / 2.0 * 0.7;
    final highHiss = (sin(_simPhase * 5.2) > 0.5 ? 0.8 : 0.2) * _random.nextDouble();

    // Raw band values
    final rawBass = max(0.02, bassKick * (0.6 + 0.4 * sin(_simPhase * 0.5)));
    final rawMid = max(0.02, midBody);
    final rawHigh = max(0.01, highHiss);
    final rawLevel = (rawBass * 0.5 + rawMid * 0.35 + rawHigh * 0.15);

    // Dynamic auto-gain
    final gain = pow(2.0, (_sensitivity - 50.0) / 25.0).toDouble(); // 0.25x .. 4.0x
    final decay = pow(0.5, dt / 3.0).toDouble(); // 3-second peak half-life

    _peakBass = max(rawBass, _peakBass * decay);
    _peakMid = max(rawMid, _peakMid * decay);
    _peakHigh = max(rawHigh, _peakHigh * decay);
    _peakLevel = max(rawLevel, _peakLevel * decay);

    final normBass = (rawBass / max(0.04, _peakBass) * gain).clamp(0.0, 1.0);
    final normMid = (rawMid / max(0.04, _peakMid) * gain).clamp(0.0, 1.0);
    final normHigh = (rawHigh / max(0.04, _peakHigh) * gain).clamp(0.0, 1.0);
    final normLevel = (rawLevel / max(0.04, _peakLevel) * gain).clamp(0.0, 1.0);

    // Smoothing release filter
    final tau = 0.05 + 0.95 * (_smoothing / 100.0);
    final rel = exp(-dt / tau);

    _bassLevel = normBass > _bassLevel ? normBass : (_bassLevel * rel + normBass * (1 - rel));
    _midLevel = normMid > _midLevel ? normMid : (_midLevel * rel + normMid * (1 - rel));
    _highLevel = normHigh > _highLevel ? normHigh : (_highLevel * rel + normHigh * (1 - rel));
    _overallLevel = normLevel > _overallLevel ? normLevel : (_overallLevel * rel + normLevel * (1 - rel));

    // Beat Detection: bass jumps above recent average (180ms refractory period)
    final beatThreshold = 1.65 - 0.5 * (_sensitivity / 100.0);
    final beatTriggered = (rawBass > _bassAvg * beatThreshold && normBass > 0.35 && _sinceLastBeat > 0.18);

    if (beatTriggered) {
      _sinceLastBeat = 0.0;
      _isBeat = true;
    } else {
      _isBeat = false;
    }
    _bassAvg += (rawBass - _bassAvg) * min(1.0, dt / 1.0);

    // Render LED color by mode
    _renderedColor = _renderModeColor();

    // Drive controller via 55ms throttled queue
    bleService.sendRgb(_renderedColor, fromScene: true, skipFade: true);
    notifyListeners();
  }

  Color _renderModeColor() {
    final floorVal = _minGlowFloor / 100.0;
    final baseColor = bleService.currentColor;

    switch (_mode) {
      case AudioReactiveMode.pulse:
        // Intensity envelope modulation
        final intensity = (floorVal + (1.0 - floorVal) * _overallLevel).clamp(0.0, 1.0);
        return Color.fromARGB(
          255,
          (baseColor.r * 255 * intensity).round().clamp(0, 255),
          (baseColor.g * 255 * intensity).round().clamp(0, 255),
          (baseColor.b * 255 * intensity).round().clamp(0, 255),
        );

      case AudioReactiveMode.beatFlash:
        if (_isBeat) {
          return Colors.white;
        }
        final dim = (floorVal + (1.0 - floorVal) * 0.4).clamp(0.0, 1.0);
        return Color.fromARGB(
          255,
          (baseColor.r * 255 * dim).round().clamp(0, 255),
          (baseColor.g * 255 * dim).round().clamp(0, 255),
          (baseColor.b * 255 * dim).round().clamp(0, 255),
        );

      case AudioReactiveMode.beatColors:
        if (_isBeat) {
          _currentHue = (_currentHue + 45.0 + _random.nextDouble() * 30.0) % 360.0;
        }
        final intensity = (floorVal + (1.0 - floorVal) * _overallLevel).clamp(0.0, 1.0);
        final c = HSVColor.fromAHSV(1.0, _currentHue, 1.0, 1.0).toColor();
        return Color.fromARGB(
          255,
          (c.r * 255 * intensity).round().clamp(0, 255),
          (c.g * 255 * intensity).round().clamp(0, 255),
          (c.b * 255 * intensity).round().clamp(0, 255),
        );

      case AudioReactiveMode.spectrum:
        // Bass -> Red, Mids -> Green, Treble -> Blue
        final r = (_bassLevel * 255).round().clamp(0, 255);
        final g = (_midLevel * 255).round().clamp(0, 255);
        final b = (_highLevel * 255).round().clamp(0, 255);
        final maxVal = max(r, max(g, b));
        if (maxVal < 10) {
          return Color.fromARGB(255, (255 * floorVal).toInt(), (140 * floorVal).toInt(), 0);
        }
        return Color.fromARGB(255, r, g, b);

      case AudioReactiveMode.pitch:
        // Spectral centroid pitch mapped to chromatic spectrum
        final pitchScore = (_bassLevel * 0.1 + _midLevel * 0.4 + _highLevel * 0.8) /
            max(0.1, _bassLevel + _midLevel + _highLevel);
        final hue = (pitchScore * 300.0).clamp(0.0, 360.0);
        final intensity = (floorVal + (1.0 - floorVal) * _overallLevel).clamp(0.0, 1.0);
        final c = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        return Color.fromARGB(
          255,
          (c.r * 255 * intensity).round().clamp(0, 255),
          (c.g * 255 * intensity).round().clamp(0, 255),
          (c.b * 255 * intensity).round().clamp(0, 255),
        );
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
