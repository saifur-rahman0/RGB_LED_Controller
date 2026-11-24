import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';
import '../models/user_scene.dart';
import '../protocol/elk_protocol.dart';
import 'comfort_engine.dart';

/// Connection states for the BLE controller
enum BleLedStatus {
  offline,
  scanning,
  connecting,
  reconnecting,
  connected,
}

/// Active software animated scenes
enum ActiveScene {
  none,
  cozyFire,
  cyberpunkPulse,
  oceanBreathe,
  rgbCycle,
  aurora,
  lavaLamp,
  vaporwave,
  sunset,
  forest,
  galaxy,
  ice,
  candle,
  torch,
  fire,
  breathe,
  breath478,
  heartbeat,
  neonFlicker,
  lightning,
  fireworks,
  police,
  party,
}

/// Log entry for live hex packet inspection
class BleHexLogEntry {
  final DateTime timestamp;
  final String direction; // 'TX', 'RX', 'INFO', 'ERR'
  final String hexPayload;
  final String description;

  const BleHexLogEntry({
    required this.timestamp,
    required this.direction,
    required this.hexPayload,
    required this.description,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

/// Internal queued packet wrapper
class _QueuedBlePacket {
  final Uint8List bytes;
  final String description;

  _QueuedBlePacket(this.bytes, this.description);
}

/// Primary BLE LED controller service managing scan, connection,
/// 55ms coalescing throttling queue, hardware effects, software scenes,
/// comfort engine (fades, color balance, flash limiter), and live hex telemetry.
class BleLedService extends ChangeNotifier {
  // Connection and device state
  BleLedStatus _status = BleLedStatus.offline;
  BleLedStatus get status => _status;

  final List<BleDevice> _scannedDevices = [];
  List<BleDevice> get scannedDevices => List.unmodifiable(_scannedDevices);

  bool _showAllDevices = false;
  bool get showAllDevices => _showAllDevices;

  /// Returns devices visible to the user (filtered by known strip criteria unless showAllDevices is true)
  List<BleDevice> get visibleDevices {
    if (_showAllDevices) return List.unmodifiable(_scannedDevices);
    return List.unmodifiable(_scannedDevices.where((d) =>
        ElkProtocol.isKnownStripDevice(d.name, d.deviceId) ||
        d.deviceId.toLowerCase() == _lastConnectedDeviceId?.toLowerCase() ||
        d.deviceId.toLowerCase() == _selectedDevice?.deviceId.toLowerCase()));
  }

  BleDevice? _selectedDevice;
  BleDevice? get selectedDevice => _selectedDevice;

  String? _lastConnectedDeviceId;
  String? get lastConnectedDeviceId => _lastConnectedDeviceId;
  bool _isUserDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Active GATT UUIDs
  String _activeServiceUuid = ElkProtocol.serviceUuid;
  String get activeServiceUuid => _activeServiceUuid;

  String _activeCharUuid = ElkProtocol.writeCharacteristicUuid;
  String get activeCharUuid => _activeCharUuid;

  // LED Light Controls
  bool _isPoweredOn = true;
  bool get isPoweredOn => _isPoweredOn;

  Color _currentColor = const Color(0xFFFF0055);
  Color get currentColor => _currentColor;
  Color? _lastSentColor;

  int _currentBrightness = 100; // 1..100
  int get currentBrightness => _currentBrightness;

  int _currentEffectMode = 0x87; // 7-Color Crossfade
  int get currentEffectMode => _currentEffectMode;

  int _currentEffectSpeed = 50; // 1..100
  int get currentEffectSpeed => _currentEffectSpeed;

  // Comfort Engine: Smooth transitions, Color balance, Flash limiter
  FadeSpeed _fadeSpeed = FadeSpeed.smooth;
  FadeSpeed get fadeSpeed => _fadeSpeed;

  ColorBalance _colorBalance = const ColorBalance();
  ColorBalance get colorBalance => _colorBalance;

  bool _reduceFlashing = false;
  bool get reduceFlashing => _reduceFlashing;

  final FlashLimiter _flashLimiter = FlashLimiter(tau: 0.45);
  Timer? _fadeTimer;

  // User Custom Named Scenes
  List<UserScene> _userScenes = [];
  List<UserScene> get userScenes => List.unmodifiable(_userScenes);

  // Software Scene Engine
  ActiveScene _activeScene = ActiveScene.none;
  ActiveScene get activeScene => _activeScene;
  Timer? _sceneTimer;
  double _sceneStep = 0.0;
  final Random _random = Random();

  // Custom User Swatches
  List<Color> _customSwatches = [
    const Color(0xFFFF0000), // Red
    const Color(0xFF00FF00), // Green
    const Color(0xFF0000FF), // Blue
    const Color(0xFFFF007F), // Neon Pink
    const Color(0xFF00F0FF), // Neon Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFF8A2BE2), // Violet
    const Color(0xFFFFFFFF), // Pure White
  ];
  List<Color> get customSwatches => List.unmodifiable(_customSwatches);

  // System settings
  bool _autoConnectOnLaunch = true;
  bool get autoConnectOnLaunch => _autoConnectOnLaunch;

  bool _turnOffOnClose = false;
  bool get turnOffOnClose => _turnOffOnClose;

  // Throttled 55ms packet queue
  final Queue<_QueuedBlePacket> _discreteQueue = Queue<_QueuedBlePacket>();
  _QueuedBlePacket? _pendingStreamPacket;
  Timer? _throttleTimer;
  bool _isSending = false;
  static const Duration throttleDuration = Duration(milliseconds: 55);

  // Hex packet log
  final List<BleHexLogEntry> _hexLogs = [];
  List<BleHexLogEntry> get hexLogs => List.unmodifiable(_hexLogs);

  BleLedService() {
    _initService();
  }

  Future<void> _initService() async {
    _setupBleListeners();
    await _loadPreferences();

    if (_autoConnectOnLaunch) {
      logInfo('Auto-connect on launch enabled. Starting device scan...');
      startScan();
    }
  }

  // -------------------------------------------------------------
  // PREFERENCES PERSISTENCE
  // -------------------------------------------------------------
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoConnectOnLaunch = prefs.getBool('autoConnectOnLaunch') ?? true;
      _turnOffOnClose = prefs.getBool('turnOffOnClose') ?? false;
      _showAllDevices = prefs.getBool('showAllDevices') ?? false;

      // Comfort settings
      final fadeDurationMs = prefs.getInt('fadeDurationMs') ?? 700;
      _fadeSpeed = FadeSpeed.fromDurationMs(fadeDurationMs);

      final rGain = prefs.getDouble('colorBalance_r') ?? 1.0;
      final gGain = prefs.getDouble('colorBalance_g') ?? 1.0;
      final bGain = prefs.getDouble('colorBalance_b') ?? 1.0;
      _colorBalance = ColorBalance(redGain: rGain, greenGain: gGain, blueGain: bGain);

      _reduceFlashing = prefs.getBool('reduceFlashing') ?? false;

      // Color & Brightness
      final savedColorHex = prefs.getString('lastColorHex');
      if (savedColorHex != null && savedColorHex.isNotEmpty) {
        final parsed = int.tryParse(savedColorHex.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          _currentColor = Color(0xFF000000 | parsed);
        }
      }

      _currentBrightness = (prefs.getInt('lastBrightness') ?? 100).clamp(1, 100);
      _lastConnectedDeviceId = prefs.getString('lastConnectedDeviceId');

      // Custom Swatches
      final savedSwatches = prefs.getStringList('customSwatches');
      if (savedSwatches != null && savedSwatches.isNotEmpty) {
        final loaded = <Color>[];
        for (final hex in savedSwatches) {
          final val = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
          if (val != null) {
            loaded.add(Color(0xFF000000 | val));
          }
        }
        if (loaded.isNotEmpty) {
          _customSwatches = loaded;
        }
      }

      // User Named Scenes
      final scenesJsonList = prefs.getStringList('userCustomScenes');
      if (scenesJsonList != null && scenesJsonList.isNotEmpty) {
        _userScenes = scenesJsonList
            .map((s) => UserScene.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
      } else {
        // Default built-in starter scenes
        _userScenes = [
          const UserScene(
            id: 'scene_movie',
            name: 'Movie Night',
            color: Color(0xFFFF8800),
            brightness: 40,
            iconName: 'movie',
          ),
          const UserScene(
            id: 'scene_gaming',
            name: 'Vivid Cyber',
            color: Color(0xFF00F0FF),
            brightness: 100,
            iconName: 'sports_esports',
          ),
          const UserScene(
            id: 'scene_reading',
            name: 'Warm Reading',
            color: Color(0xFFFFE4B5),
            brightness: 75,
            iconName: 'menu_book',
          ),
          const UserScene(
            id: 'scene_cozy',
            name: 'Cozy Fireplace',
            color: Color(0xFFFF3A00),
            brightness: 60,
            iconName: 'local_fire_department',
          ),
          const UserScene(
            id: 'scene_relax',
            name: 'Deep Relax',
            color: Color(0xFF7C4DFF),
            brightness: 50,
            iconName: 'nightlife',
          ),
        ];
      }

      notifyListeners();
    } catch (e) {
      logError('Failed to load preferences: $e');
    }
  }

  Future<void> setShowAllDevices(bool value) async {
    _showAllDevices = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAllDevices', value);
  }

  Future<void> setFadeSpeed(FadeSpeed speed) async {
    _fadeSpeed = speed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fadeDurationMs', speed.durationMs);
  }

  Future<void> setColorBalance(ColorBalance balance) async {
    _colorBalance = balance;
    notifyListeners();
    // Re-apply to active strip color
    if (_isPoweredOn) {
      sendRgb(_currentColor, skipFade: true);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('colorBalance_r', balance.redGain);
    await prefs.setDouble('colorBalance_g', balance.greenGain);
    await prefs.setDouble('colorBalance_b', balance.blueGain);
  }

  Future<void> setReduceFlashing(bool value) async {
    _reduceFlashing = value;
    if (value) {
      _flashLimiter.reset();
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduceFlashing', value);
  }

  Future<void> setAutoConnectOnLaunch(bool value) async {
    _autoConnectOnLaunch = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoConnectOnLaunch', value);
  }

  Future<void> setTurnOffOnClose(bool value) async {
    _turnOffOnClose = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('turnOffOnClose', value);
  }

  Future<void> saveCustomSwatch(Color color) async {
    if (_customSwatches.any((c) => c.toARGB32() == color.toARGB32())) return;
    _customSwatches.insert(0, color);
    if (_customSwatches.length > 24) {
      _customSwatches.removeLast();
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final hexList = _customSwatches.map((c) {
      final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
      return '#$r$g$b'.toUpperCase();
    }).toList();
    await prefs.setStringList('customSwatches', hexList);
  }

  Future<void> removeCustomSwatch(Color color) async {
    _customSwatches.removeWhere((c) => c.toARGB32() == color.toARGB32());
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final hexList = _customSwatches.map((c) {
      final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
      return '#$r$g$b'.toUpperCase();
    }).toList();
    await prefs.setStringList('customSwatches', hexList);
  }

  // -------------------------------------------------------------
  // USER NAMED SCENES MANAGEMENT
  // -------------------------------------------------------------
  Future<void> saveUserScene(String name, {Color? color, int? brightness, int? effectMode, int? effectSpeed}) async {
    final newScene = UserScene(
      id: 'scene_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Scene ${_userScenes.length + 1}' : name.trim(),
      color: color ?? _currentColor,
      brightness: brightness ?? _currentBrightness,
      effectMode: effectMode,
      effectSpeed: effectSpeed,
    );
    _userScenes.add(newScene);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final list = _userScenes.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('userCustomScenes', list);
  }

  Future<void> deleteUserScene(String id) async {
    _userScenes.removeWhere((s) => s.id == id);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final list = _userScenes.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('userCustomScenes', list);
  }

  void applyUserScene(UserScene scene) {
    stopScene();
    _isPoweredOn = true;
    _currentBrightness = scene.brightness;
    _currentColor = scene.color;

    // Send brightness
    sendBrightness(scene.brightness);

    if (scene.effectMode != null) {
      sendHardwareEffect(scene.effectMode!);
      if (scene.effectSpeed != null) {
        sendEffectSpeed(scene.effectSpeed!);
      }
    } else {
      sendRgb(scene.color);
    }

    logInfo('Applied Scene: ${scene.name} (Brightness: ${scene.brightness}%)');
    notifyListeners();
  }

  Future<void> _persistLastColor(Color c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
      await prefs.setString('lastColorHex', '#$r$g$b'.toUpperCase());
    } catch (_) {}
  }

  Future<void> _persistLastBrightness(int b) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastBrightness', b);
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // BLE SCANNING & SETUP
  // -------------------------------------------------------------
  void _setupBleListeners() {
    UniversalBle.onScanResult = (BleDevice device) {
      final existingIndex = _scannedDevices.indexWhere((d) => d.deviceId == device.deviceId);
      if (existingIndex >= 0) {
        _scannedDevices[existingIndex] = device;
      } else {
        _scannedDevices.add(device);
      }

      // Check if target device FF:FF:10:C5:29:1F, last connected device, or recognized strip
      final isTargetMac = device.deviceId.toUpperCase() == ElkProtocol.targetDeviceAddress;
      final isLastDevice = _lastConnectedDeviceId != null &&
          device.deviceId.toLowerCase() == _lastConnectedDeviceId!.toLowerCase();
      final isKnownStrip = ElkProtocol.isKnownStripDevice(device.name, device.deviceId);

      if (isTargetMac || (_selectedDevice == null && (isKnownStrip || isLastDevice))) {
        _selectedDevice = device;
        logInfo('Identified Compatible BLE Strip: ${device.name ?? 'Unnamed'} [${device.deviceId}]');

        if (_autoConnectOnLaunch && _status != BleLedStatus.connected && _status != BleLedStatus.connecting) {
          logInfo('Auto-connecting to target peripheral [${device.deviceId}]...');
          connectDevice(device);
        }
      }

      notifyListeners();
    };

    UniversalBle.onConnectionChange = (BleConnectionChange change) {
      logInfo('BLE Connection Event: device=${change.deviceId}, connected=${change.isConnected}, error=${change.error ?? 'none'}');

      if (_selectedDevice != null && _selectedDevice!.deviceId.toLowerCase() == change.deviceId.toLowerCase()) {
        if (!change.isConnected) {
          if (!_isUserDisconnect) {
            _status = BleLedStatus.reconnecting;
            logError('Connection lost unexpectedly to ${change.deviceId}. Scheduling auto-reconnect...');
            _scheduleReconnect();
          } else {
            _status = BleLedStatus.offline;
          }
          notifyListeners();
        }
      }
    };
  }

  Future<void> startScan() async {
    try {
      _scannedDevices.clear();
      _status = BleLedStatus.scanning;
      logInfo('Starting WinRT BLE Scan for LED strip controllers...');
      notifyListeners();

      await UniversalBle.startScan();

      // Stop scan after 12 seconds automatically to save radio resources
      Future.delayed(const Duration(seconds: 12), () {
        if (_status == BleLedStatus.scanning) {
          stopScan();
        }
      });
    } catch (e) {
      logError('Failed to start scan: $e');
      _status = BleLedStatus.offline;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
      if (_status == BleLedStatus.scanning) {
        _status = BleLedStatus.offline;
      }
      logInfo('BLE Scan stopped. ${_scannedDevices.length} peripherals located.');
      notifyListeners();
    } catch (e) {
      logError('Failed to stop scan: $e');
    }
  }

  void selectDevice(BleDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // CONNECTION, AUTO-DETECTION & HANDSHAKE
  // -------------------------------------------------------------
  Future<void> connectDevice(BleDevice device) async {
    _reconnectTimer?.cancel();
    _isUserDisconnect = false;
    _selectedDevice = device;
    _status = BleLedStatus.connecting;
    notifyListeners();

    try {
      logInfo('Stopping active scan prior to connection...');
      await UniversalBle.stopScan();

      logInfo('Connecting to BLE peripheral [${device.deviceId}]...');
      await UniversalBle.connect(device.deviceId);

      logInfo('Discovering GATT services and characteristics...');
      final services = await UniversalBle.discoverServices(device.deviceId);

      // Robust Multi-Candidate Characteristic Resolution
      String? matchedServiceUuid;
      String? matchedCharUuid;

      // First pass: Match known services and write characteristics
      for (final service in services) {
        if (ElkProtocol.isServiceMatch(service.uuid)) {
          matchedServiceUuid = service.uuid;
          for (final char in service.characteristics) {
            if (ElkProtocol.isWriteCharMatch(char.uuid)) {
              matchedCharUuid = char.uuid;
              break;
            }
          }
          if (matchedCharUuid != null) break;
        }
      }

      // Second pass: Check if any characteristic matches known write UUID regardless of service
      if (matchedCharUuid == null) {
        for (final service in services) {
          for (final char in service.characteristics) {
            if (ElkProtocol.isWriteCharMatch(char.uuid)) {
              matchedServiceUuid = service.uuid;
              matchedCharUuid = char.uuid;
              break;
            }
          }
          if (matchedCharUuid != null) break;
        }
      }

      // Third pass: Fallback to any characteristic advertising writeWithoutResponse or write
      if (matchedCharUuid == null) {
        for (final service in services) {
          for (final char in service.characteristics) {
            if (char.properties.contains(CharacteristicProperty.writeWithoutResponse) ||
                char.properties.contains(CharacteristicProperty.write)) {
              matchedServiceUuid = service.uuid;
              matchedCharUuid = char.uuid;
              break;
            }
          }
          if (matchedCharUuid != null) break;
        }
      }

      _activeServiceUuid = matchedServiceUuid ?? ElkProtocol.serviceUuid;
      _activeCharUuid = matchedCharUuid ?? ElkProtocol.writeCharacteristicUuid;

      logInfo('Resolved GATT: Service=$_activeServiceUuid, WriteChar=$_activeCharUuid');

      // Mandatory 300ms delay prior to Handshake packet
      logInfo('Waiting 300ms mandatory handshake delay...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Mandatory Handshake: 7E 07 83 02 01 01 01 00 EF
      final handshakePacket = ElkProtocol.handshake();
      logInfo('Sending mandatory initialization handshake: 7E 07 83 02 01 01 01 00 EF');
      await UniversalBle.write(
        device.deviceId,
        _activeServiceUuid,
        _activeCharUuid,
        handshakePacket,
        withoutResponse: true,
      );
      _logPacket(handshakePacket, 'Handshake (0x83 Init)');

      _status = BleLedStatus.connected;
      _reconnectAttempts = 0;
      logInfo('Successfully connected and authenticated with ${device.name ?? 'LED Controller'}!');

      // Save as last connected device in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastConnectedDeviceId', device.deviceId);

      // Restore last known light state
      if (_isPoweredOn) {
        sendRgb(_currentColor, skipFade: true);
        sendBrightness(_currentBrightness);
      }

      notifyListeners();
    } catch (e) {
      logError('Failed to connect to ${device.deviceId}: $e');
      _status = BleLedStatus.offline;
      notifyListeners();
    }
  }

  Future<void> disconnectDevice() async {
    _isUserDisconnect = true;
    _reconnectTimer?.cancel();
    stopScene();

    if (_selectedDevice != null) {
      try {
        logInfo('Disconnecting from [${_selectedDevice!.deviceId}]...');
        await UniversalBle.disconnect(_selectedDevice!.deviceId);
      } catch (e) {
        logError('Disconnect error: $e');
      }
    }

    _status = BleLedStatus.offline;
    _clearQueues();
    notifyListeners();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_isUserDisconnect || _selectedDevice == null) return;

    _reconnectAttempts++;
    final delaySeconds = _reconnectAttempts < 3 ? 2 : 4;
    logInfo('Auto-reconnect attempt #$_reconnectAttempts in $delaySeconds seconds...');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_status == BleLedStatus.reconnecting && _selectedDevice != null) {
        await connectDevice(_selectedDevice!);
      }
    });
  }

  // -------------------------------------------------------------
  // 55MS RATE-LIMITED / COALESCING PACKET QUEUE
  // -------------------------------------------------------------
  void enqueuePacket(Uint8List packet, String description, {bool isContinuous = false}) {
    if (isContinuous) {
      _pendingStreamPacket = _QueuedBlePacket(packet, description);
    } else {
      _discreteQueue.add(_QueuedBlePacket(packet, description));
    }

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _processNextPacket();
    }
  }

  void _processNextPacket() async {
    if (_isSending || _status != BleLedStatus.connected || _selectedDevice == null) {
      return;
    }

    _QueuedBlePacket? packetToSend;

    // Discrete critical commands take FIFO priority
    if (_discreteQueue.isNotEmpty) {
      packetToSend = _discreteQueue.removeFirst();
    } else if (_pendingStreamPacket != null) {
      packetToSend = _pendingStreamPacket;
      _pendingStreamPacket = null;
    }

    if (packetToSend == null) return;

    _isSending = true;
    try {
      await UniversalBle.write(
        _selectedDevice!.deviceId,
        _activeServiceUuid,
        _activeCharUuid,
        packetToSend.bytes,
        withoutResponse: true,
      );
      _logPacket(packetToSend.bytes, packetToSend.description);
    } catch (e) {
      logError('Write error: $e');
    } finally {
      _isSending = false;
    }

    // Schedule next dispatch after 55ms throttle window
    _throttleTimer = Timer(throttleDuration, () {
      _processNextPacket();
    });
  }

  void _clearQueues() {
    _discreteQueue.clear();
    _pendingStreamPacket = null;
    _throttleTimer?.cancel();
    _isSending = false;
  }

  // -------------------------------------------------------------
  // CONTROLLER COMMANDS
  // -------------------------------------------------------------
  /// Master Power ON
  void powerOn() {
    _isPoweredOn = true;
    final packet = ElkProtocol.powerOn();
    enqueuePacket(packet, 'Power ON', isContinuous: false);
    notifyListeners();
  }

  /// Master Power OFF
  void powerOff() {
    stopScene();
    _fadeTimer?.cancel();
    _isPoweredOn = false;
    final packet = ElkProtocol.powerOff();
    enqueuePacket(packet, 'Power OFF', isContinuous: false);
    notifyListeners();
  }

  /// Toggle Master Power
  void togglePower() {
    if (_isPoweredOn) {
      powerOff();
    } else {
      powerOn();
    }
  }

  /// Set Solid RGB Color with optional Smoothstep Comfort Fading
  void sendRgb(Color targetColor, {bool fromScene = false, bool skipFade = false}) {
    if (!fromScene) {
      stopScene();
    }

    _currentColor = targetColor;
    _isPoweredOn = true;

    Color processed = targetColor;

    // Apply "Reduce Flashing" low-pass filter if active
    if (_reduceFlashing) {
      processed = _flashLimiter.step(processed, 0.055);
    }

    // Apply RGB color balance calibration
    final balancedColor = _colorBalance.apply(processed);

    // If smooth fading is active and not from a scene, calculate smoothstep interpolation
    if (!skipFade && !fromScene && _fadeSpeed != FadeSpeed.off && _lastSentColor != null) {
      _fadeTimer?.cancel();
      final steps = calculateFadeSteps(_lastSentColor!, balancedColor, _fadeSpeed.duration);
      int stepIndex = 0;

      _fadeTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
        if (stepIndex >= steps.length) {
          timer.cancel();
          _lastSentColor = balancedColor;
          return;
        }
        _sendRgbDirect(steps[stepIndex]);
        stepIndex++;
      });
    } else {
      _sendRgbDirect(balancedColor);
      _lastSentColor = balancedColor;
    }

    if (!fromScene) {
      _persistLastColor(targetColor);
    }
    notifyListeners();
  }

  void _sendRgbDirect(Color c) {
    final r = (c.r * 255).round().clamp(0, 255);
    final g = (c.g * 255).round().clamp(0, 255);
    final b = (c.b * 255).round().clamp(0, 255);

    final hexStr =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
    final packet = ElkProtocol.setRgb(r, g, b);
    enqueuePacket(packet, 'Solid RGB: $hexStr', isContinuous: true);
  }

  /// Flash Alert (e.g. for notifications, OBS stream event, incoming calls)
  Future<void> flashAlert(Color alertColor, {int flashes = 2, Duration onDuration = const Duration(milliseconds: 250)}) async {
    final prevColor = _currentColor;
    final prevPower = _isPoweredOn;

    for (int i = 0; i < flashes; i++) {
      sendRgb(alertColor, skipFade: true, fromScene: true);
      await Future.delayed(onDuration);
      if (prevPower) {
        sendRgb(prevColor, skipFade: true, fromScene: true);
      } else {
        powerOff();
      }
      if (i < flashes - 1) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  /// Set Brightness (1-100%, coalesced 55ms)
  void sendBrightness(int level) {
    _currentBrightness = level.clamp(1, 100);
    final packet = ElkProtocol.setBrightness(_currentBrightness);
    enqueuePacket(packet, 'Brightness: $_currentBrightness%', isContinuous: true);
    _persistLastBrightness(_currentBrightness);
    notifyListeners();
  }

  /// Set Built-in Hardware Effect Mode (0x80..0x9C, discrete FIFO)
  void sendHardwareEffect(int modeId) {
    stopScene();
    _currentEffectMode = modeId.clamp(0x80, 0x9C);
    _isPoweredOn = true;

    final effect = ElkEffectCatalog.getById(_currentEffectMode);
    final packet = ElkProtocol.setEffect(_currentEffectMode);
    enqueuePacket(packet, 'HW Effect: ${effect.name} (${effect.hexId})', isContinuous: false);
    notifyListeners();
  }

  /// Set Hardware Effect Speed (1-100%, coalesced 55ms)
  void sendEffectSpeed(int speed) {
    _currentEffectSpeed = speed.clamp(1, 100);
    final packet = ElkProtocol.setEffectSpeed(_currentEffectSpeed);
    enqueuePacket(packet, 'HW Effect Speed: $_currentEffectSpeed%', isContinuous: true);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // SOFTWARE ANIMATION SCENES (RGBZap Suite)
  // -------------------------------------------------------------
  void startScene(ActiveScene scene) {
    stopScene();
    _activeScene = scene;
    _sceneStep = 0.0;
    _isPoweredOn = true;

    _sceneTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      _tickScene();
    });

    logInfo('Started software effect: ${_sceneName(scene)}');
    notifyListeners();
  }

  void stopScene() {
    if (_activeScene != ActiveScene.none) {
      _sceneTimer?.cancel();
      _sceneTimer = null;
      _activeScene = ActiveScene.none;
      logInfo('Software animation effect stopped.');
      notifyListeners();
    }
  }

  void _tickScene() {
    _sceneStep += 0.04;
    Color generatedColor;

    switch (_activeScene) {
      case ActiveScene.cozyFire:
      case ActiveScene.fire:
        final flicker = _random.nextDouble() * 0.25;
        final r = (240 + (_random.nextDouble() * 15)).clamp(200, 255).toInt();
        final g = (45 + (_random.nextDouble() * 45) + (sin(_sceneStep * 2.5) * 15)).clamp(30, 110).toInt();
        final b = (_random.nextDouble() * 12).clamp(0, 15).toInt();
        generatedColor = Color.fromARGB(255, r, (g * (1.0 - flicker)).toInt(), b);
        break;

      case ActiveScene.candle:
        final flicker = _random.nextDouble() * 0.15;
        final r = 255;
        final g = (140 + (_random.nextDouble() * 20)).toInt();
        final b = 20;
        final intensity = (1.0 - flicker) * (0.85 + sin(_sceneStep * 1.5) * 0.15);
        generatedColor = Color.fromARGB(255, (r * intensity).round(), (g * intensity).round(), (b * intensity).round());
        break;

      case ActiveScene.torch:
        final r = (220 + (_random.nextDouble() * 35)).toInt();
        final g = (70 + (_random.nextDouble() * 40)).toInt();
        final b = 5;
        generatedColor = Color.fromARGB(255, r, g, b);
        break;

      case ActiveScene.aurora:
        final t = (sin(_sceneStep * 0.8) + 1.0) / 2.0;
        generatedColor = Color.lerp(
          const Color(0xFF00FF88), // Green
          const Color(0xFF7C4DFF), // Purple
          t,
        )!;
        break;

      case ActiveScene.lavaLamp:
        final t = (sin(_sceneStep * 0.6) + 1.0) / 2.0;
        generatedColor = Color.lerp(
          const Color(0xFFFF2200), // Lava Red
          const Color(0xFFFF8800), // Hot Orange
          t,
        )!;
        break;

      case ActiveScene.vaporwave:
        final t = (sin(_sceneStep * 1.1) + 1.0) / 2.0;
        generatedColor = Color.lerp(
          const Color(0xFFFF007F), // Neon Magenta
          const Color(0xFF00F0FF), // Neon Cyan
          t,
        )!;
        break;

      case ActiveScene.sunset:
        final t = (sin(_sceneStep * 0.7) + 1.0) / 2.0;
        if (t < 0.5) {
          generatedColor = Color.lerp(const Color(0xFF4A0E4E), const Color(0xFFFF5722), t * 2)!;
        } else {
          generatedColor = Color.lerp(const Color(0xFFFF5722), const Color(0xFFFFC107), (t - 0.5) * 2)!;
        }
        break;

      case ActiveScene.forest:
        final t = (sin(_sceneStep * 0.9) + 1.0) / 2.0;
        generatedColor = Color.lerp(const Color(0xFF1B5E20), const Color(0xFF00E676), t)!;
        break;

      case ActiveScene.galaxy:
        final t = (sin(_sceneStep * 0.75) + 1.0) / 2.0;
        generatedColor = Color.lerp(const Color(0xFF0D083B), const Color(0xFFE040FB), t)!;
        break;

      case ActiveScene.ice:
        final t = (sin(_sceneStep * 1.0) + 1.0) / 2.0;
        generatedColor = Color.lerp(const Color(0xFFE0F7FA), const Color(0xFF00E5FF), t)!;
        break;

      case ActiveScene.breathe:
        final t = (sin(_sceneStep * 1.2) + 1.0) / 2.0;
        generatedColor = Color.lerp(const Color(0xFF001122), const Color(0xFF00D2FF), t)!;
        break;

      case ActiveScene.breath478:
        // 4-7-8 Breathing Guide (19-second cycle)
        final cycle = (_sceneStep * 1.5) % 19.0;
        if (cycle < 4.0) {
          // Inhale 4s: Cyan swells
          final t = cycle / 4.0;
          generatedColor = Color.lerp(const Color(0xFF002233), const Color(0xFF00F0FF), t)!;
        } else if (cycle < 11.0) {
          // Hold 7s: Deep soothing indigo
          generatedColor = const Color(0xFF3F51B5);
        } else {
          // Exhale 8s: Warm gentle purple/amber fading down
          final t = (cycle - 11.0) / 8.0;
          generatedColor = Color.lerp(const Color(0xFF9C27B0), const Color(0xFF002233), t)!;
        }
        break;

      case ActiveScene.heartbeat:
        final beat = (_sceneStep * 3.0) % 3.0;
        if (beat < 0.25 || (beat > 0.4 && beat < 0.65)) {
          generatedColor = const Color(0xFFFF0033);
        } else {
          generatedColor = const Color(0xFF220005);
        }
        break;

      case ActiveScene.neonFlicker:
        final isOff = _random.nextDouble() < 0.12;
        generatedColor = isOff ? const Color(0xFF110011) : const Color(0xFFFF007F);
        break;

      case ActiveScene.lightning:
        final isBurst = _random.nextDouble() < 0.06;
        generatedColor = isBurst ? const Color(0xFFFFFFFF) : const Color(0xFF050510);
        break;

      case ActiveScene.fireworks:
        final isBang = _random.nextDouble() < 0.1;
        if (isBang) {
          final hue = _random.nextDouble() * 360.0;
          generatedColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        } else {
          generatedColor = const Color(0xFF050508);
        }
        break;

      case ActiveScene.police:
        final step = (_sceneStep * 8.0).toInt() % 4;
        generatedColor = (step == 0 || step == 1) ? const Color(0xFFFF0000) : const Color(0xFF0000FF);
        break;

      case ActiveScene.party:
        final hue = (_random.nextDouble() * 360.0);
        generatedColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        break;

      case ActiveScene.cyberpunkPulse:
        final t = (sin(_sceneStep * 1.8) + 1.0) / 2.0;
        if (t < 0.5) {
          generatedColor = Color.lerp(const Color(0xFFFF007F), const Color(0xFF00F0FF), t * 2.0)!;
        } else {
          generatedColor = Color.lerp(const Color(0xFF00F0FF), const Color(0xFF9D00FF), (t - 0.5) * 2.0)!;
        }
        break;

      case ActiveScene.oceanBreathe:
        final t = (sin(_sceneStep * 1.2) + 1.0) / 2.0;
        generatedColor = Color.lerp(const Color(0xFF001F3F), const Color(0xFF00D2FF), t)!;
        break;

      case ActiveScene.rgbCycle:
        final hue = (_sceneStep * 60.0) % 360.0;
        generatedColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        break;

      case ActiveScene.none:
        return;
    }

    sendRgb(generatedColor, fromScene: true, skipFade: true);
  }

  String _sceneName(ActiveScene s) {
    return s.name;
  }

  // -------------------------------------------------------------
  // HEX TELEMETRY LOGGING
  // -------------------------------------------------------------
  void _logPacket(Uint8List bytes, String description) {
    final entry = BleHexLogEntry(
      timestamp: DateTime.now(),
      direction: 'TX',
      hexPayload: ElkProtocol.formatHex(bytes),
      description: description,
    );
    _appendLog(entry);
  }

  void logInfo(String message) {
    final entry = BleHexLogEntry(
      timestamp: DateTime.now(),
      direction: 'INFO',
      hexPayload: '',
      description: message,
    );
    _appendLog(entry);
  }

  void logError(String message) {
    final entry = BleHexLogEntry(
      timestamp: DateTime.now(),
      direction: 'ERR',
      hexPayload: '',
      description: message,
    );
    _appendLog(entry);
  }

  void _appendLog(BleHexLogEntry entry) {
    _hexLogs.insert(0, entry);
    if (_hexLogs.length > 250) {
      _hexLogs.removeLast();
    }
    notifyListeners();
  }

  void clearLogs() {
    _hexLogs.clear();
    notifyListeners();
  }

  String getAllLogsAsText() {
    final buffer = StringBuffer();
    for (final log in _hexLogs.reversed) {
      if (log.hexPayload.isNotEmpty) {
        buffer.writeln('[${log.timeFormatted}] [${log.direction}] ${log.hexPayload} -- ${log.description}');
      } else {
        buffer.writeln('[${log.timeFormatted}] [${log.direction}] ${log.description}');
      }
    }
    return buffer.toString();
  }

  /// Called when the desktop window is closing
  Future<void> handleAppClose() async {
    if (_turnOffOnClose && _status == BleLedStatus.connected && _selectedDevice != null) {
      try {
        final offPacket = ElkProtocol.powerOff();
        await UniversalBle.write(
          _selectedDevice!.deviceId,
          _activeServiceUuid,
          _activeCharUuid,
          offPacket,
          withoutResponse: true,
        );
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _throttleTimer?.cancel();
    _sceneTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }
}
