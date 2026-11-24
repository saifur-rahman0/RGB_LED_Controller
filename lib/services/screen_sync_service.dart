import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'ble_led_service.dart';

// Win32 GDI FFI Signatures
typedef _GetDC = ffi.IntPtr Function(ffi.IntPtr hWnd);
typedef _GetDCDart = int Function(int hWnd);

typedef _ReleaseDC = ffi.Int32 Function(ffi.IntPtr hWnd, ffi.IntPtr hDC);
typedef _ReleaseDCDart = int Function(int hWnd, int hDC);

typedef _CreateCompatibleDC = ffi.IntPtr Function(ffi.IntPtr hDC);
typedef _CreateCompatibleDCDart = int Function(int hDC);

typedef _CreateCompatibleBitmap = ffi.IntPtr Function(ffi.IntPtr hDC, ffi.Int32 cx, ffi.Int32 cy);
typedef _CreateCompatibleBitmapDart = int Function(int hDC, int cx, int cy);

typedef _SelectObject = ffi.IntPtr Function(ffi.IntPtr hDC, ffi.IntPtr h);
typedef _SelectObjectDart = int Function(int hDC, int h);

typedef _BitBlt = ffi.Int32 Function(
  ffi.IntPtr hdc,
  ffi.Int32 x,
  ffi.Int32 y,
  ffi.Int32 cx,
  ffi.Int32 cy,
  ffi.IntPtr hdcSrc,
  ffi.Int32 x1,
  ffi.Int32 y1,
  ffi.Uint32 rop,
);
typedef _BitBltDart = int Function(
  int hdc,
  int x,
  int y,
  int cx,
  int cy,
  int hdcSrc,
  int x1,
  int y1,
  int rop,
);

typedef _DeleteDC = ffi.Int32 Function(ffi.IntPtr hdc);
typedef _DeleteDCDart = int Function(int hdc);

typedef _DeleteObject = ffi.Int32 Function(ffi.IntPtr ho);
typedef _DeleteObjectDart = int Function(int ho);

typedef _GetSystemMetrics = ffi.Int32 Function(ffi.Int32 nIndex);
typedef _GetSystemMetricsDart = int Function(int nIndex);

final class _BITMAPINFOHEADER extends ffi.Struct {
  @ffi.Uint32()
  external int biSize;
  @ffi.Int32()
  external int biWidth;
  @ffi.Int32()
  external int biHeight;
  @ffi.Uint16()
  external int biPlanes;
  @ffi.Uint16()
  external int biBitCount;
  @ffi.Uint32()
  external int biCompression;
  @ffi.Uint32()
  external int biSizeImage;
  @ffi.Int32()
  external int biXPelsPerMeter;
  @ffi.Int32()
  external int biYPelsPerMeter;
  @ffi.Uint32()
  external int biClrUsed;
  @ffi.Uint32()
  external int biClrImportant;
}

final class _BITMAPINFO extends ffi.Struct {
  external _BITMAPINFOHEADER bmiHeader;
  @ffi.Array(1)
  external ffi.Array<ffi.Uint32> bmiColors;
}

typedef _GetDIBits = ffi.Int32 Function(
  ffi.IntPtr hdc,
  ffi.IntPtr hbm,
  ffi.Uint32 start,
  ffi.Uint32 cLines,
  ffi.Pointer<ffi.Void> lpvBits,
  ffi.Pointer<_BITMAPINFO> lpbmi,
  ffi.Uint32 usage,
);
typedef _GetDIBitsDart = int Function(
  int hdc,
  int hbm,
  int start,
  int cLines,
  ffi.Pointer<ffi.Void> lpvBits,
  ffi.Pointer<_BITMAPINFO> lpbmi,
  int usage,
);

/// Screen Sampling Areas matching RGBZap
enum ScreenSyncArea {
  whole('Whole Screen', 'Analyzes the entire display'),
  edges('Edges (Bias Lighting)', 'Samples outer perimeter border ideal for TV/monitor backlighting'),
  center('Center Only', 'Samples middle focal point'),
  top('Top Edge', 'Top border bias'),
  bottom('Bottom Edge', 'Bottom border bias'),
  left('Left Edge', 'Left border bias'),
  right('Right Edge', 'Right border bias');

  final String label;
  final String description;
  const ScreenSyncArea(this.label, this.description);
}

/// Service managing low-latency, low-CPU Win32 Screen Sync (Ambilight)
class ScreenSyncService extends ChangeNotifier {
  final BleLedService bleService;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  ScreenSyncArea _area = ScreenSyncArea.whole;
  ScreenSyncArea get area => _area;

  bool _cropBlackBars = true;
  bool get cropBlackBars => _cropBlackBars;

  bool _keepDimGlow = true;
  bool get keepDimGlow => _keepDimGlow;

  double _saturationBoost = 1.4; // 1.0 .. 2.5
  double get saturationBoost => _saturationBoost;

  double _smoothingAlpha = 0.35; // 0.15 .. 0.8
  double get smoothingAlpha => _smoothingAlpha;

  Color _extractedColor = Colors.black;
  Color get extractedColor => _extractedColor;

  Color _smoothedColor = Colors.black;
  Color get smoothedColor => _smoothedColor;

  Uint8List? _previewThumbnailBytes;
  Uint8List? get previewThumbnailBytes => _previewThumbnailBytes;

  Timer? _captureTimer;

  // Win32 FFI pointers & bindings
  late final _GetDCDart _getDC;
  late final _ReleaseDCDart _releaseDC;
  late final _CreateCompatibleDCDart _createCompatibleDC;
  late final _CreateCompatibleBitmapDart _createCompatibleBitmap;
  late final _SelectObjectDart _selectObject;
  late final _BitBltDart _bitBlt;
  late final _DeleteDCDart _deleteDC;
  late final _DeleteObjectDart _deleteObject;
  late final _GetDIBitsDart _getDIBits;
  late final _GetSystemMetricsDart _getSystemMetrics;

  static const int sampleWidth = 64;
  static const int sampleHeight = 36;
  bool _ffiLoaded = false;

  ScreenSyncService({required this.bleService}) {
    _initFfi();
  }

  void _initFfi() {
    try {
      final user32 = ffi.DynamicLibrary.open('user32.dll');
      final gdi32 = ffi.DynamicLibrary.open('gdi32.dll');

      _getDC = user32.lookupFunction<_GetDC, _GetDCDart>('GetDC');
      _releaseDC = user32.lookupFunction<_ReleaseDC, _ReleaseDCDart>('ReleaseDC');
      _getSystemMetrics = user32.lookupFunction<_GetSystemMetrics, _GetSystemMetricsDart>('GetSystemMetrics');

      _createCompatibleDC = gdi32.lookupFunction<_CreateCompatibleDC, _CreateCompatibleDCDart>('CreateCompatibleDC');
      _createCompatibleBitmap = gdi32.lookupFunction<_CreateCompatibleBitmap, _CreateCompatibleBitmapDart>('CreateCompatibleBitmap');
      _selectObject = gdi32.lookupFunction<_SelectObject, _SelectObjectDart>('SelectObject');
      _bitBlt = gdi32.lookupFunction<_BitBlt, _BitBltDart>('BitBlt');
      _deleteDC = gdi32.lookupFunction<_DeleteDC, _DeleteDCDart>('DeleteDC');
      _deleteObject = gdi32.lookupFunction<_DeleteObject, _DeleteObjectDart>('DeleteObject');
      _getDIBits = gdi32.lookupFunction<_GetDIBits, _GetDIBitsDart>('GetDIBits');

      _ffiLoaded = true;
    } catch (e) {
      debugPrint('ScreenSync FFI load error: $e');
      _ffiLoaded = false;
    }
  }

  void setArea(ScreenSyncArea newArea) {
    _area = newArea;
    notifyListeners();
  }

  void setCropBlackBars(bool val) {
    _cropBlackBars = val;
    notifyListeners();
  }

  void setKeepDimGlow(bool val) {
    _keepDimGlow = val;
    notifyListeners();
  }

  void setSaturationBoost(double val) {
    _saturationBoost = val;
    notifyListeners();
  }

  void setSmoothingAlpha(double val) {
    _smoothingAlpha = val;
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
    if (_isRunning || !_ffiLoaded) return;
    _isRunning = true;
    bleService.stopScene();
    notifyListeners();

    // 15 FPS = ~66ms tick, feeds perfectly into 55ms coalescing BLE queue
    _captureTimer = Timer.periodic(const Duration(milliseconds: 66), (timer) {
      _captureFrame();
    });
  }

  void stop() {
    _isRunning = false;
    _captureTimer?.cancel();
    _captureTimer = null;
    notifyListeners();
  }

  void _captureFrame() {
    if (!_isRunning) return;

    try {
      final screenWidth = _getSystemMetrics(0); // SM_CXSCREEN
      final screenHeight = _getSystemMetrics(1); // SM_CYSCREEN

      if (screenWidth <= 0 || screenHeight <= 0) return;

      final hdcScreen = _getDC(0);
      final hdcMem = _createCompatibleDC(hdcScreen);
      final hBitmap = _createCompatibleBitmap(hdcScreen, sampleWidth, sampleHeight);
      final hOld = _selectObject(hdcMem, hBitmap);

      // BitBlt downsamples the screen in hardware during the blit
      _bitBlt(
        hdcMem,
        0,
        0,
        sampleWidth,
        sampleHeight,
        hdcScreen,
        0,
        0,
        0x00CC0020, // SRCCOPY
      );

      final bmiPtr = calloc<_BITMAPINFO>();
      bmiPtr.ref.bmiHeader.biSize = ffi.sizeOf<_BITMAPINFOHEADER>();
      bmiPtr.ref.bmiHeader.biWidth = sampleWidth;
      bmiPtr.ref.bmiHeader.biHeight = -sampleHeight; // Top-down
      bmiPtr.ref.bmiHeader.biPlanes = 1;
      bmiPtr.ref.bmiHeader.biBitCount = 32;
      bmiPtr.ref.bmiHeader.biCompression = 0; // BI_RGB

      final bufferSize = sampleWidth * sampleHeight * 4;
      final pPixels = calloc<ffi.Uint8>(bufferSize);

      _getDIBits(
        hdcMem,
        hBitmap,
        0,
        sampleHeight,
        pPixels.cast(),
        bmiPtr,
        0, // DIB_RGB_COLORS
      );

      final bgraBytes = pPixels.asTypedList(bufferSize);

      // Extract Dominant Color using RGBZap algorithm
      final extracted = _extractDominantColor(bgraBytes, sampleWidth, sampleHeight);

      // Free Win32 GDI structures
      calloc.free(pPixels);
      calloc.free(bmiPtr);
      _selectObject(hdcMem, hOld);
      _deleteObject(hBitmap);
      _deleteDC(hdcMem);
      _releaseDC(0, hdcScreen);

      _extractedColor = extracted;

      // Apply smoothing low-pass filter
      _smoothedColor = Color.lerp(_smoothedColor, extracted, _smoothingAlpha)!;

      // Transmit to LED strip via 55ms throttled queue
      bleService.sendRgb(_smoothedColor, fromScene: true, skipFade: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Screen sync capture error: $e');
    }
  }

  /// Saturation-weighted Dominant Color extraction (RGBZap formula)
  Color _extractDominantColor(Uint8List bgra, int width, int height) {
    int startY = 0;
    int endY = height;
    int startX = 0;
    int endX = width;

    // 1. Crop Black Bars if enabled
    if (_cropBlackBars) {
      // Find top/bottom bounds exceeding dark threshold
      for (int y = 0; y < height ~/ 4; y++) {
        if (!_isRowBlack(bgra, width, y)) {
          startY = y;
          break;
        }
      }
      for (int y = height - 1; y >= height * 3 ~/ 4; y--) {
        if (!_isRowBlack(bgra, width, y)) {
          endY = y + 1;
          break;
        }
      }
    }

    // 2. Select Sample Area
    switch (_area) {
      case ScreenSyncArea.edges:
        // Bias lighting border: outer 25% band
        break; // Handled per pixel in the loop below
      case ScreenSyncArea.center:
        startX = width ~/ 4;
        endX = width * 3 ~/ 4;
        startY = height ~/ 4;
        endY = height * 3 ~/ 4;
        break;
      case ScreenSyncArea.top:
        endY = height ~/ 3;
        break;
      case ScreenSyncArea.bottom:
        startY = height * 2 ~/ 3;
        break;
      case ScreenSyncArea.left:
        endX = width ~/ 3;
        break;
      case ScreenSyncArea.right:
        startX = width * 2 ~/ 3;
        break;
      case ScreenSyncArea.whole:
        break;
    }

    double totalWeight = 0.0;
    double sumR = 0.0;
    double sumG = 0.0;
    double sumB = 0.0;

    final edgeBorderX = width ~/ 4;
    final edgeBorderY = height ~/ 4;

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        // If Edges area, skip the inner rectangle
        if (_area == ScreenSyncArea.edges) {
          if (x >= edgeBorderX && x < (width - edgeBorderX) && y >= edgeBorderY && y < (height - edgeBorderY)) {
            continue;
          }
        }

        final idx = (y * width + x) * 4;
        final b = bgra[idx];
        final g = bgra[idx + 1];
        final r = bgra[idx + 2];

        // Per-pixel saturation
        final maxC = max(r, max(g, b));
        final minC = min(r, min(g, b));
        final sat = (maxC - minC) / (maxC + 0.001);

        // Saturation-weighting formula: colorful pixels dominate, grays/dulls receive low weight
        final weight = (sat * sat) + 0.05;

        sumR += r * weight;
        sumG += g * weight;
        sumB += b * weight;
        totalWeight += weight;
      }
    }

    if (totalWeight <= 0.001) {
      return _keepDimGlow ? const Color(0xFF221105) : Colors.black;
    }

    double r = sumR / totalWeight;
    double g = sumG / totalWeight;
    double b = sumB / totalWeight;

    // Saturation boost in HSV space
    if (_saturationBoost != 1.0) {
      final hsv = HSVColor.fromColor(Color.fromARGB(255, r.round().clamp(0, 255), g.round().clamp(0, 255), b.round().clamp(0, 255)));
      final boostedSat = (hsv.saturation * _saturationBoost).clamp(0.0, 1.0);
      final boostedColor = hsv.withSaturation(boostedSat).toColor();
      r = boostedColor.r * 255;
      g = boostedColor.g * 255;
      b = boostedColor.b * 255;
    }

    // Minimum dim glow on dark screens
    final luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    if (luma < 15.0 && _keepDimGlow) {
      return const Color(0xFF221105); // Dim warm glow
    }

    return Color.fromARGB(255, r.round().clamp(0, 255), g.round().clamp(0, 255), b.round().clamp(0, 255));
  }

  bool _isRowBlack(Uint8List bgra, int width, int y, {int thresh = 22}) {
    for (int x = 0; x < width; x += 4) {
      final idx = (y * width + x) * 4;
      if (bgra[idx] > thresh || bgra[idx + 1] > thresh || bgra[idx + 2] > thresh) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
