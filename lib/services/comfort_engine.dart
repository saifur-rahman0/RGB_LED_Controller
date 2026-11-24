import 'dart:math';
import 'package:flutter/material.dart';

/// Eased smoothstep interpolation curve: 3t^2 - 2t^3
/// Starts gentle, moves faster in the middle, and eases smoothly into the target.
double smoothstep(double t) {
  final clamped = t.clamp(0.0, 1.0);
  return clamped * clamped * (3.0 - 2.0 * clamped);
}

/// Color transition fade speed options matching RGBZap
enum FadeSpeed {
  off(0, 'Off (Instant)'),
  quick(300, 'Quick (300ms)'),
  smooth(700, 'Smooth (700ms)'),
  slow(1500, 'Slow (1.5s)');

  final int durationMs;
  final String label;
  const FadeSpeed(this.durationMs, this.label);

  Duration get duration => Duration(milliseconds: durationMs);

  static FadeSpeed fromDurationMs(int ms) {
    return FadeSpeed.values.firstWhere(
      (f) => f.durationMs == ms,
      orElse: () => FadeSpeed.smooth,
    );
  }
}

/// Calculates discrete smoothstep transition color frames from start to target.
List<Color> calculateFadeSteps(Color start, Color end, Duration duration, {int intervalMs = 55}) {
  if (duration.inMilliseconds <= intervalMs) {
    return [end];
  }

  final stepsCount = max(1, duration.inMilliseconds ~/ intervalMs);
  final List<Color> frames = [];

  for (int i = 1; i < stepsCount; i++) {
    final t = smoothstep(i / stepsCount);
    frames.add(Color.lerp(start, end, t)!);
  }
  frames.add(end);
  return frames;
}

/// Low-pass color filter for "Reduce Flashing" mode.
/// Softens rapid strobes, alternating cuts, and sudden flashes to under 3 flashes/second.
class FlashLimiter {
  final double tau;
  List<double>? _prev;

  FlashLimiter({this.tau = 0.45});

  void reset() {
    _prev = null;
  }

  Color step(Color c, double dt) {
    final r = c.r * 255.0;
    final g = c.g * 255.0;
    final b = c.b * 255.0;

    if (_prev == null) {
      _prev = [r, g, b];
    } else {
      final a = 1.0 - exp(-dt / tau);
      _prev![0] = _prev![0] + (r - _prev![0]) * a;
      _prev![1] = _prev![1] + (g - _prev![1]) * a;
      _prev![2] = _prev![2] + (b - _prev![2]) * a;
    }

    return Color.fromARGB(
      255,
      _prev![0].round().clamp(0, 255),
      _prev![1].round().clamp(0, 255),
      _prev![2].round().clamp(0, 255),
    );
  }
}

/// RGB Color Balance Calibration multipliers (0.0 .. 1.0)
/// Corrects hardware LED variations where "white" appears pinkish, bluish, or greenish.
class ColorBalance {
  final double redGain;
  final double greenGain;
  final double blueGain;

  const ColorBalance({
    this.redGain = 1.0,
    this.greenGain = 1.0,
    this.blueGain = 1.0,
  });

  Color apply(Color c) {
    if (redGain == 1.0 && greenGain == 1.0 && blueGain == 1.0) {
      return c;
    }
    final r = (c.r * 255 * redGain).round().clamp(0, 255);
    final g = (c.g * 255 * greenGain).round().clamp(0, 255);
    final b = (c.b * 255 * blueGain).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  ColorBalance copyWith({double? redGain, double? greenGain, double? blueGain}) {
    return ColorBalance(
      redGain: redGain ?? this.redGain,
      greenGain: greenGain ?? this.greenGain,
      blueGain: blueGain ?? this.blueGain,
    );
  }
}
