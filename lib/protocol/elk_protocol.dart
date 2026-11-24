import 'dart:typed_data';

/// BLE Protocol specification and packet generator for duoCo Strip / ELK-BLEDOM RGB LED Controllers.
/// Specifically configured for hardware revision FF:FF:10:C5:29:1F.
class ElkProtocol {
  // Primary 128-bit & 16-bit Service and Characteristic UUIDs
  static const String serviceUuid = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String writeCharacteristicUuid = '0000fff3-0000-1000-8000-00805f9b34fb';
  
  // Shorthand 16-bit equivalents (UniversalBle or WinRT sometimes report lower 16-bit string)
  static const String shortServiceUuid = 'fff0';
  static const String shortWriteCharacteristicUuid = 'fff3';

  // Specific target hardware address
  static const String targetDeviceAddress = 'FF:FF:10:C5:29:1F';
  static const String targetDeviceNamePrefix = 'ELK-BLEDOM';

  // Common strip naming prefixes encountered across clone hardware
  static const List<String> knownDevicePrefixes = [
    'ELK-BLEDOM',
    'ELK-BULB',
    'ELK-',
    'MELK',
    'duoCo',
    'Lotus',
    'LED',
    'XSL-',
    'Triones',
    'BT-LED',
    'BleStrip',
  ];

  // Common candidate GATT Services across duoCo / ELK / Nordic clones
  static const List<String> candidateServiceUuids = [
    '0000fff0-0000-1000-8000-00805f9b34fb',
    'fff0',
    '0000ffe0-0000-1000-8000-00805f9b34fb',
    'ffe0',
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
  ];

  // Common candidate GATT Write Characteristics across duoCo / ELK / Nordic clones
  static const List<String> candidateWriteCharUuids = [
    '0000fff3-0000-1000-8000-00805f9b34fb',
    'fff3',
    '0000ffe1-0000-1000-8000-00805f9b34fb',
    'ffe1',
    '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  ];

  /// Packet header and terminator
  static const int headerByte = 0x7E;
  static const int endByte = 0xEF;

  /// Connection Handshake: Sent 300ms after connecting & discovering services.
  /// 7E 07 83 02 01 01 01 00 EF
  static Uint8List handshake() {
    return Uint8List.fromList([
      0x7E, 0x07, 0x83, 0x02, 0x01, 0x01, 0x01, 0x00, 0xEF,
    ]);
  }

  /// Power ON command
  /// 7E 04 04 F0 00 01 FF 00 EF
  static Uint8List powerOn() {
    return Uint8List.fromList([
      0x7E, 0x04, 0x04, 0xF0, 0x00, 0x01, 0xFF, 0x00, 0xEF,
    ]);
  }

  /// Power OFF command
  /// 7E 04 04 00 00 00 FF 00 EF
  static Uint8List powerOff() {
    return Uint8List.fromList([
      0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF,
    ]);
  }

  /// Set Solid RGB Color
  /// 7E 07 05 03 [R] [G] [B] 10 EF
  /// r, g, b in range [0..255]
  static Uint8List setRgb(int r, int g, int b) {
    final clampedR = r.clamp(0, 255);
    final clampedG = g.clamp(0, 255);
    final clampedB = b.clamp(0, 255);
    return Uint8List.fromList([
      0x7E, 0x07, 0x05, 0x03, clampedR, clampedG, clampedB, 0x10, 0xEF,
    ]);
  }

  /// Set Brightness
  /// 7E 04 01 [level] 01 FF FF 00 EF
  /// level in range [1..100]
  static Uint8List setBrightness(int level) {
    final clampedLevel = level.clamp(1, 100);
    return Uint8List.fromList([
      0x7E, 0x04, 0x01, clampedLevel, 0x01, 0xFF, 0xFF, 0x00, 0xEF,
    ]);
  }

  /// Set Hardware Effect Mode
  /// 7E 05 03 [modeId] 03 FF FF 00 EF
  /// modeId in range [0x80..0x9C]
  static Uint8List setEffect(int modeId) {
    final clampedMode = modeId.clamp(0x80, 0x9C);
    return Uint8List.fromList([
      0x7E, 0x05, 0x03, clampedMode, 0x03, 0xFF, 0xFF, 0x00, 0xEF,
    ]);
  }

  /// Set Hardware Effect Speed
  /// 7E 04 02 [speed] 00 00 00 00 EF
  /// speed in range [1..100]
  static Uint8List setEffectSpeed(int speed) {
    final clampedSpeed = speed.clamp(1, 100);
    return Uint8List.fromList([
      0x7E, 0x04, 0x02, clampedSpeed, 0x00, 0x00, 0x00, 0x00, 0xEF,
    ]);
  }

  /// Formats byte array to space-separated hex string for debugging (e.g. "7E 07 05 03 FF 00 00 10 EF")
  static String formatHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  /// Matching helper to check if a UUID is a known compatible RGB LED service
  static bool isServiceMatch(String uuid) {
    final clean = uuid.toLowerCase().replaceAll('-', '');
    for (final candidate in candidateServiceUuids) {
      if (clean == candidate.toLowerCase().replaceAll('-', '')) {
        return true;
      }
    }
    return clean.contains('fff0') || clean.contains('ffe0');
  }

  /// Matching helper to check if a UUID is a known compatible write characteristic
  static bool isWriteCharMatch(String uuid) {
    final clean = uuid.toLowerCase().replaceAll('-', '');
    for (final candidate in candidateWriteCharUuids) {
      if (clean == candidate.toLowerCase().replaceAll('-', '')) {
        return true;
      }
    }
    return clean.contains('fff3') || clean.contains('ffe1') || clean.contains('6e400002');
  }

  /// Checks if a device is recognized as a compatible strip by address or name
  static bool isKnownStripDevice(String? name, String address) {
    if (address.toUpperCase() == targetDeviceAddress) {
      return true;
    }
    if (name == null || name.trim().isEmpty) {
      return false;
    }
    final upperName = name.toUpperCase();
    for (final prefix in knownDevicePrefixes) {
      if (upperName.contains(prefix.toUpperCase())) {
        return true;
      }
    }
    return false;
  }
}

/// Hardware Effect Mode Definition with descriptive category and labels
class ElkEffectMode {
  final int id;
  final String name;
  final String category;
  final String description;

  const ElkEffectMode({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
  });

  String get hexId => '0x${id.toRadixString(16).toUpperCase()}';
}

/// Catalog of all 29 built-in hardware effects (0x80 through 0x9C)
class ElkEffectCatalog {
  static const List<ElkEffectMode> modes = [
    // Fades / Gradients (0x80 - 0x86)
    ElkEffectMode(id: 0x80, name: 'Red Fade', category: 'Fade', description: 'Monochrome Red smooth pulsation'),
    ElkEffectMode(id: 0x81, name: 'Green Fade', category: 'Fade', description: 'Monochrome Green smooth pulsation'),
    ElkEffectMode(id: 0x82, name: 'Blue Fade', category: 'Fade', description: 'Monochrome Blue smooth pulsation'),
    ElkEffectMode(id: 0x83, name: 'Yellow Fade', category: 'Fade', description: 'Monochrome Yellow smooth pulsation'),
    ElkEffectMode(id: 0x84, name: 'Cyan Fade', category: 'Fade', description: 'Monochrome Cyan smooth pulsation'),
    ElkEffectMode(id: 0x85, name: 'Magenta Fade', category: 'Fade', description: 'Monochrome Magenta smooth pulsation'),
    ElkEffectMode(id: 0x86, name: 'White Fade', category: 'Fade', description: 'Monochrome White smooth pulsation'),

    // Crossfades (0x87 - 0x8A)
    ElkEffectMode(id: 0x87, name: '7-Color Crossfade', category: 'Crossfade', description: 'Full spectrum rainbow crossfade transition'),
    ElkEffectMode(id: 0x88, name: 'Red/Green Crossfade', category: 'Crossfade', description: 'Smooth crossfade between Red and Green'),
    ElkEffectMode(id: 0x89, name: 'Red/Blue Crossfade', category: 'Crossfade', description: 'Smooth crossfade between Red and Blue'),
    ElkEffectMode(id: 0x8A, name: 'Green/Blue Crossfade', category: 'Crossfade', description: 'Smooth crossfade between Green and Blue'),

    // Strobes (0x8B - 0x92)
    ElkEffectMode(id: 0x8B, name: '7-Color Strobe (Fast)', category: 'Strobe', description: 'Rapid high-intensity 7-color strobe flash'),
    ElkEffectMode(id: 0x8C, name: 'Red Strobe', category: 'Strobe', description: 'High-frequency Red pulse flash'),
    ElkEffectMode(id: 0x8D, name: 'Green Strobe', category: 'Strobe', description: 'High-frequency Green pulse flash'),
    ElkEffectMode(id: 0x8E, name: 'Blue Strobe', category: 'Strobe', description: 'High-frequency Blue pulse flash'),
    ElkEffectMode(id: 0x8F, name: 'Yellow Strobe', category: 'Strobe', description: 'High-frequency Yellow pulse flash'),
    ElkEffectMode(id: 0x90, name: 'Cyan Strobe', category: 'Strobe', description: 'High-frequency Cyan pulse flash'),
    ElkEffectMode(id: 0x91, name: 'Purple Strobe', category: 'Strobe', description: 'High-frequency Purple pulse flash'),
    ElkEffectMode(id: 0x92, name: 'White Strobe', category: 'Strobe', description: 'High-frequency White pulse flash'),

    // Jumps & Cycles (0x93 - 0x99)
    ElkEffectMode(id: 0x93, name: '7-Color Jumping Flash', category: 'Jump', description: 'Immediate sharp step transitions across 7 colors'),
    ElkEffectMode(id: 0x94, name: '3-Color RGB Jump', category: 'Jump', description: 'Fast stepping between Red, Green, and Blue'),
    ElkEffectMode(id: 0x95, name: '7-Color Strobe', category: 'Strobe', description: 'Dynamic 7-color strobe cycle'),
    ElkEffectMode(id: 0x96, name: '3-Color Strobe', category: 'Strobe', description: '3-color RGB strobe sequence'),
    ElkEffectMode(id: 0x97, name: '7-Color Gradual Flow', category: 'Smooth', description: 'Smooth rolling multi-color gradient'),
    ElkEffectMode(id: 0x98, name: '3-Color Gradual Flow', category: 'Smooth', description: 'Gentle gradient between Red, Green, and Blue'),
    ElkEffectMode(id: 0x99, name: '7-Color Jump', category: 'Jump', description: 'Classic 7-color disco jump switch'),

    // Flashes (0x9A - 0x9C)
    ElkEffectMode(id: 0x9A, name: 'Red Flash', category: 'Flash', description: 'Intermittent single-color Red flash bursts'),
    ElkEffectMode(id: 0x9B, name: 'Green Flash', category: 'Flash', description: 'Intermittent single-color Green flash bursts'),
    ElkEffectMode(id: 0x9C, name: 'Blue Flash', category: 'Flash', description: 'Intermittent single-color Blue flash bursts'),
  ];

  static ElkEffectMode getById(int id) {
    return modes.firstWhere(
      (m) => m.id == id,
      orElse: () => ElkEffectMode(
        id: id,
        name: 'Effect 0x${id.toRadixString(16).toUpperCase()}',
        category: 'Custom',
        description: 'Hardware Effect 0x${id.toRadixString(16).toUpperCase()}',
      ),
    );
  }
}
