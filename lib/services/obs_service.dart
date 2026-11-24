import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ble_led_service.dart';

/// OBS Studio 28+ WebSocket v5 Tally & Scene Link Service
class ObsService extends ChangeNotifier {
  final BleLedService bleService;

  WebSocket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  String _host = '127.0.0.1';
  String get host => _host;

  int _port = 4455;
  int get port => _port;

  String _password = '';
  String get password => _password;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _redOnLive = true;
  bool get redOnLive => _redOnLive;

  bool _redOnRecord = true;
  bool get redOnRecord => _redOnRecord;

  String _statusMessage = 'OBS Standby';
  String get statusMessage => _statusMessage;

  Color? _prevColor;

  ObsService({required this.bleService}) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('obs_enabled') ?? false;
    _host = prefs.getString('obs_host') ?? '127.0.0.1';
    _port = prefs.getInt('obs_port') ?? 4455;
    _password = prefs.getString('obs_password') ?? '';
    _redOnLive = prefs.getBool('obs_red_live') ?? true;
    _redOnRecord = prefs.getBool('obs_red_record') ?? true;

    if (_isEnabled) {
      connect();
    }
  }

  Future<void> setEnabled(bool val) async {
    _isEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('obs_enabled', val);

    if (val) {
      connect();
    } else {
      disconnect();
    }
    notifyListeners();
  }

  Future<void> updateConfig({String? host, int? port, String? password, bool? redOnLive, bool? redOnRecord}) async {
    if (host != null) _host = host;
    if (port != null) _port = port;
    if (password != null) _password = password;
    if (redOnLive != null) _redOnLive = redOnLive;
    if (redOnRecord != null) _redOnRecord = redOnRecord;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('obs_host', _host);
    await prefs.setInt('obs_port', _port);
    await prefs.setString('obs_password', _password);
    await prefs.setBool('obs_red_live', _redOnLive);
    await prefs.setBool('obs_red_record', _redOnRecord);

    if (_isEnabled) {
      connect();
    }
    notifyListeners();
  }

  Future<void> connect() async {
    disconnect();
    _statusMessage = 'Connecting to ws://$_host:$_port...';
    notifyListeners();

    try {
      _socket = await WebSocket.connect('ws://$_host:$_port').timeout(const Duration(seconds: 4));
      _isConnected = true;
      _statusMessage = 'Connected to OBS Studio';
      notifyListeners();

      _socket!.listen(
        _handleMessage,
        onError: (e) {
          _isConnected = false;
          _statusMessage = 'OBS connection error: $e';
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          _statusMessage = 'OBS disconnected';
          notifyListeners();
        },
      );
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Failed to connect to OBS: $e';
      notifyListeners();
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _isStreaming = false;
    _isRecording = false;
    notifyListeners();
  }

  void _handleMessage(dynamic data) {
    try {
      final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
      final op = msg['op'] as int?;

      // Hello OpCode = 0 -> Send Identify OpCode = 1
      if (op == 0) {
        _socket?.add(jsonEncode({
          'op': 1,
          'd': {
            'rpcVersion': 1,
            'eventSubscriptions': 1 | 2 | 4, // General, Config, Scenes
          }
        }));
        return;
      }

      // Event OpCode = 5
      if (op == 5) {
        final d = msg['d'] as Map<String, dynamic>? ?? {};
        final eventType = d['eventType'] as String? ?? '';
        final eventData = d['eventData'] as Map<String, dynamic>? ?? {};

        if (eventType == 'StreamStateChanged') {
          _isStreaming = eventData['outputActive'] as bool? ?? false;
          _evaluateTally();
        } else if (eventType == 'RecordStateChanged') {
          _isRecording = eventData['outputActive'] as bool? ?? false;
          _evaluateTally();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void _evaluateTally() {
    final shouldBeRed = (_redOnLive && _isStreaming) || (_redOnRecord && _isRecording);
    if (shouldBeRed) {
      _prevColor ??= bleService.currentColor;
      bleService.sendRgb(const Color(0xFFFF0000), skipFade: true, fromScene: true);
    } else if (_prevColor != null) {
      bleService.sendRgb(_prevColor!, skipFade: false);
      _prevColor = null;
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
