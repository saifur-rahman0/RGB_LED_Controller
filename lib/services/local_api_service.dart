import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_reactive_service.dart';
import 'ble_led_service.dart';
import 'screen_sync_service.dart';

/// Local HTTP REST API server on 127.0.0.1:49732 matching RGBZap.
/// Enables Stream Deck, AutoHotkey, CLI, and MCP AI assistants to drive the lights.
class LocalApiService extends ChangeNotifier {
  final BleLedService bleService;
  final ScreenSyncService screenSyncService;
  final AudioReactiveService audioReactiveService;

  static const int port = 49732;
  HttpServer? _server;
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  String _token = '';
  String get token => _token;

  String _lastStatusMessage = 'API Server Standby';
  String get lastStatusMessage => _lastStatusMessage;

  LocalApiService({
    required this.bleService,
    required this.screenSyncService,
    required this.audioReactiveService,
  }) {
    _initApi();
  }

  Future<void> _initApi() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('api_enabled') ?? false;
    _token = prefs.getString('api_token') ?? _generateSecretToken();
    await prefs.setString('api_token', _token);

    if (_isEnabled) {
      startServer();
    }
  }

  String _generateSecretToken() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('api_enabled', enabled);

    if (enabled) {
      await startServer();
    } else {
      await stopServer();
    }
    notifyListeners();
  }

  Future<void> regenerateToken() async {
    _token = _generateSecretToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', _token);
    notifyListeners();
  }

  Future<void> startServer() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _server!.listen(_handleRequest);
      _lastStatusMessage = 'Listening on http://127.0.0.1:$port';
      debugPrint('Local API started on http://127.0.0.1:$port');
      notifyListeners();
    } catch (e) {
      _lastStatusMessage = 'Error starting server: $e';
      debugPrint('Local API start error: $e');
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _lastStatusMessage = 'Server Stopped';
    notifyListeners();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Security 1: Reject web page origins to block DNS rebinding
    if (request.headers.value('origin') != null) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write(jsonEncode({'error': 'Origin header prohibited'}))
        ..close();
      return;
    }

    // Security 2: Verify Bearer Token
    final authHeader = request.headers.value('authorization') ?? '';
    final expectedHeader = 'Bearer $_token';
    if (authHeader.trim() != expectedHeader) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Unauthorized. Provide Authorization: Bearer <token>'}))
        ..close();
      return;
    }

    final path = request.uri.path.toLowerCase();
    final method = request.method.toUpperCase();

    try {
      if (method == 'GET' && path == '/status') {
        _respondJson(request, {
          'power': bleService.isPoweredOn,
          'color': '#${(bleService.currentColor.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          'brightness': bleService.currentBrightness,
          'connected': bleService.status == BleLedStatus.connected,
          'screenSync': screenSyncService.isRunning,
          'audioReactive': audioReactiveService.isRunning,
          'device': bleService.selectedDevice?.deviceId,
        });
        return;
      }

      if (method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        final Map<String, dynamic> body = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : {};

        switch (path) {
          case '/power':
            final power = body['power'] as bool? ?? !bleService.isPoweredOn;
            if (power) {
              bleService.powerOn();
            } else {
              bleService.powerOff();
            }
            _respondJson(request, {'success': true, 'power': bleService.isPoweredOn});
            return;

          case '/color':
            final colorVal = body['color'];
            final parsedColor = _parseColor(colorVal);
            if (parsedColor != null) {
              bleService.sendRgb(parsedColor);
              _respondJson(request, {'success': true, 'color': '#${(parsedColor.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}'});
            } else {
              _respondError(request, 400, 'Invalid color. Provide "#RRGGBB", [r,g,b], or named color.');
            }
            return;

          case '/brightness':
            final level = body['level'] as int? ?? body['brightness'] as int?;
            if (level != null && level >= 1 && level <= 100) {
              bleService.sendBrightness(level);
              _respondJson(request, {'success': true, 'brightness': level});
            } else {
              _respondError(request, 400, 'Invalid brightness level (1..100).');
            }
            return;

          case '/scene':
            final name = body['name'] as String? ?? '';
            final match = bleService.userScenes.firstWhere(
              (s) => s.name.toLowerCase() == name.toLowerCase(),
              orElse: () => throw Exception('Scene not found: $name'),
            );
            bleService.applyUserScene(match);
            _respondJson(request, {'success': true, 'scene': match.name});
            return;

          case '/sync':
            final enable = body['enable'] as bool? ?? !screenSyncService.isRunning;
            if (enable) {
              screenSyncService.start();
            } else {
              screenSyncService.stop();
            }
            _respondJson(request, {'success': true, 'screenSync': screenSyncService.isRunning});
            return;

          case '/audio':
            final enable = body['enable'] as bool? ?? !audioReactiveService.isRunning;
            if (enable) {
              audioReactiveService.start();
            } else {
              audioReactiveService.stop();
            }
            _respondJson(request, {'success': true, 'audioReactive': audioReactiveService.isRunning});
            return;

          case '/flash':
            final colorVal = body['color'];
            final color = _parseColor(colorVal) ?? const Color(0xFF00FF88);
            final count = body['count'] as int? ?? 2;
            bleService.flashAlert(color, flashes: count);
            _respondJson(request, {'success': true, 'flashed': true});
            return;

          default:
            _respondError(request, 404, 'Endpoint not found. Valid: /status, /power, /color, /brightness, /scene, /sync, /audio, /flash');
            return;
        }
      }

      _respondError(request, 405, 'Method not allowed.');
    } catch (e) {
      _respondError(request, 500, 'Internal Server Error: $e');
    }
  }

  void _respondJson(HttpRequest request, Map<String, dynamic> data) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store')
      ..write(jsonEncode(data))
      ..close();
  }

  void _respondError(HttpRequest request, int code, String message) {
    request.response
      ..statusCode = code
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store')
      ..write(jsonEncode({'error': message}))
      ..close();
  }

  Color? _parseColor(dynamic val) {
    if (val is List && val.length == 3) {
      return Color.fromARGB(255, val[0] as int, val[1] as int, val[2] as int);
    }
    if (val is String) {
      final s = val.trim().toLowerCase();
      const named = {
        'red': Color(0xFFFF0000),
        'green': Color(0xFF00FF00),
        'blue': Color(0xFF0000FF),
        'white': Color(0xFFFFFFFF),
        'yellow': Color(0xFFFFFF00),
        'cyan': Color(0xFF00FFFF),
        'magenta': Color(0xFFFF00FF),
        'orange': Color(0xFFFF8800),
        'purple': Color(0xFF7C4DFF),
        'pink': Color(0xFFFF007F),
      };
      if (named.containsKey(s)) return named[s];
      final clean = s.replaceAll('#', '');
      if (clean.length == 6) {
        final parsed = int.tryParse(clean, radix: 16);
        if (parsed != null) return Color(0xFF000000 | parsed);
      }
    }
    return null;
  }

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}
