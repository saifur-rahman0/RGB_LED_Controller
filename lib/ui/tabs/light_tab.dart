import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../services/ble_led_service.dart';
import '../widgets/glowing_card.dart';

class LightTab extends StatefulWidget {
  final BleLedService bleService;

  const LightTab({super.key, required this.bleService});

  @override
  State<LightTab> createState() => _LightTabState();
}

class _LightTabState extends State<LightTab> {
  // Curated standard swatches
  static const List<Color> _standardPresets = [
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFFFE4B5), // Warm White / Moccasin
    Color(0xFFFF0000), // Red
    Color(0xFFFF5722), // Deep Orange
    Color(0xFFFF9800), // Amber
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF8BC34A), // Lime
    Color(0xFF4CAF50), // Green
    Color(0xFF00E676), // Spring Mint
    Color(0xFF00E5FF), // Cyan
    Color(0xFF2979FF), // Electric Blue
    Color(0xFF0000FF), // Deep Blue
    Color(0xFF7C4DFF), // Deep Purple
    Color(0xFFE040FB), // Magenta
    Color(0xFFFF4081), // Neon Pink
  ];

  final TextEditingController _hexTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateHexText();
  }

  @override
  void didUpdateWidget(covariant LightTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bleService.currentColor != widget.bleService.currentColor) {
      _updateHexText();
    }
  }

  void _updateHexText() {
    final c = widget.bleService.currentColor;
    final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
    _hexTextController.text = '#$r$g$b'.toUpperCase();
  }

  @override
  void dispose() {
    _hexTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = widget.bleService;
    final currentColor = ble.currentColor;
    final isOnline = ble.status == BleLedStatus.connected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. LIVE GLOWING PREVIEW & POWER CONTROLS
          GlowingCard(
            glowColor: currentColor,
            isGlowing: ble.isPoweredOn && isOnline,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Glowing circular bulb / preview
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ble.isPoweredOn ? currentColor : const Color(0xFF27272A),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: ble.isPoweredOn
                        ? [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.65),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      ble.isPoweredOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                      color: ble.isPoweredOn
                          ? (ThemeData.estimateBrightnessForColor(currentColor) == Brightness.dark
                              ? Colors.white
                              : Colors.black87)
                          : const Color(0xFF71717A),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Color Hex & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ble.isPoweredOn ? 'ACTIVE ILLUMINATION' : 'LIGHT STANDBY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF3F3F46)),
                            ),
                            child: Text(
                              _hexTextController.text,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            tooltip: 'Copy HEX code',
                            color: const Color(0xFFA1A1AA),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _hexTextController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied ${_hexTextController.text} to clipboard'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Turn ON / Turn OFF Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ble.isPoweredOn
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : const Color(0xFF27272A),
                        foregroundColor: ble.isPoweredOn ? const Color(0xFF34D399) : const Color(0xFFA1A1AA),
                        side: BorderSide(
                          color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF3F3F46),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                      label: const Text('Turn ON', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => ble.powerOn(),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !ble.isPoweredOn
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : const Color(0xFF27272A),
                        foregroundColor: !ble.isPoweredOn ? const Color(0xFFF87171) : const Color(0xFFA1A1AA),
                        side: BorderSide(
                          color: !ble.isPoweredOn ? const Color(0xFFEF4444) : const Color(0xFF3F3F46),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.power_off_rounded, size: 18),
                      label: const Text('Turn OFF', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => ble.powerOff(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. BRIGHTNESS SLIDER CARD
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.brightness_6_rounded, size: 18, color: Color(0xFFFBBF24)),
                        SizedBox(width: 8),
                        Text(
                          'HARDWARE BRIGHTNESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ble.currentBrightness}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.brightness_low_rounded, size: 18, color: Color(0xFF71717A)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFBBF24),
                          inactiveTrackColor: const Color(0xFF27272A),
                          thumbColor: const Color(0xFFFBBF24),
                          overlayColor: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                          trackHeight: 5,
                        ),
                        child: Slider(
                          value: ble.currentBrightness.toDouble(),
                          min: 1,
                          max: 100,
                          onChanged: (val) {
                            ble.sendBrightness(val.round());
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.brightness_high_rounded, size: 20, color: Color(0xFFFBBF24)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. INTERACTIVE COLOR WHEEL CARD
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_rounded, size: 18, color: Color(0xFF38BDF8)),
                        SizedBox(width: 8),
                        Text(
                          'INTERACTIVE CHROMATIC WHEEL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    // Manual Hex Dialog Trigger
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA1A1AA),
                        side: const BorderSide(color: Color(0xFF3F3F46)),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Edit HEX', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showHexEditDialog(context, ble),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Responsive Color Wheel
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: ColorPicker(
                      pickerColor: currentColor,
                      onColorChanged: (newColor) {
                        ble.sendRgb(newColor);
                      },
                      paletteType: PaletteType.hueWheel,
                      enableAlpha: false,
                      displayThumbColor: true,
                      hexInputBar: false,
                      colorPickerWidth: 320,
                      pickerAreaHeightPercent: 0.85,
                      labelTypes: const [],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. QUICK PRESETS & CUSTOM SWATCHES CARD
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standard Swatches
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFA855F7)),
                    SizedBox(width: 8),
                    Text(
                      'STANDARD PRESETS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _standardPresets.map((color) {
                    final isSelected = currentColor.toARGB32() == color.toARGB32();
                    return _buildSwatchTile(
                      color: color,
                      isSelected: isSelected,
                      onTap: () => ble.sendRgb(color),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFF27272A)),
                const SizedBox(height: 12),

                // User Saved Swatches
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bookmark_rounded, size: 16, color: Color(0xFFEC4899)),
                        SizedBox(width: 8),
                        Text(
                          'SAVED CUSTOM SWATCHES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEC4899),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Save Current Color', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        ble.saveCustomSwatch(currentColor);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved active color to custom swatches!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (ble.customSwatches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No custom swatches saved. Click "Save Current Color" to store your favorite tones.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ble.customSwatches.map((color) {
                      final isSelected = currentColor.toARGB32() == color.toARGB32();
                      return _buildSwatchTile(
                        color: color,
                        isSelected: isSelected,
                        onTap: () => ble.sendRgb(color),
                        onLongPress: () {
                          _confirmDeleteSwatch(context, ble, color);
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchTile({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}${onLongPress != null ? ' (Long press to delete)' : ''}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.4),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                )
              : null,
        ),
      ),
    );
  }

  void _confirmDeleteSwatch(BuildContext context, BleLedService ble, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete Custom Swatch', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove #${color.toARGB32().toRadixString(16).substring(2).toUpperCase()} from your saved swatches?',
          style: const TextStyle(color: Color(0xFFA1A1AA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              ble.removeCustomSwatch(color);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHexEditDialog(BuildContext context, BleLedService ble) {
    final textController = TextEditingController(text: _hexTextController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Enter Hex Color Code', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
          decoration: const InputDecoration(
            hintText: '#RRGGBB (e.g. #00FF88)',
            hintStyle: TextStyle(color: Color(0xFF71717A)),
            filled: true,
            fillColor: Color(0xFF27272A),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              final raw = textController.text.trim().replaceAll('#', '');
              if (raw.length == 6) {
                final val = int.tryParse(raw, radix: 16);
                if (val != null) {
                  ble.sendRgb(Color(0xFF000000 | val));
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
