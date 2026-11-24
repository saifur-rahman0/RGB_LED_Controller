import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../services/ble_led_service.dart';
import '../../services/comfort_engine.dart';
import '../widgets/glowing_card.dart';

class LightTab extends StatefulWidget {
  final BleLedService bleService;

  const LightTab({super.key, required this.bleService});

  @override
  State<LightTab> createState() => _LightTabState();
}

class _LightTabState extends State<LightTab> {
  static const List<Color> _standardPresets = [
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFFFE4B5), // Warm White
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

          // 2. HARDWARE BRIGHTNESS SLIDER
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

          // 3. USER CUSTOM NAMED SCENES (RGBZap Core Feature)
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
                        Icon(Icons.movie_filter_rounded, size: 18, color: Color(0xFF38BDF8)),
                        SizedBox(width: 8),
                        Text(
                          'CUSTOM NAMED SCENES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                      label: const Text('Save Current as Scene', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showSaveSceneDialog(context, ble),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scenes Grid
                if (ble.userScenes.isEmpty)
                  const Text('No custom scenes saved yet.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A)))
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ble.userScenes.map((scene) {
                      return InkWell(
                        onTap: () => ble.applyUserScene(scene),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scene.color.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scene.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scene.color.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                scene.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${scene.brightness}%',
                                style: const TextStyle(fontSize: 10, color: Color(0xFFA1A1AA)),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => ble.deleteUserScene(scene.id),
                                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF71717A)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. INTERACTIVE CHROMATIC WHEEL CARD
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

          // 5. COMFORT ENGINE (SMOOTH FADING & COLOR BALANCE)
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.spa_rounded, size: 18, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text(
                      'COMFORT ENGINE (SMOOTH FADING & COLOR BALANCE)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Smooth Fades Selector
                Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text('Color Transition Fade:', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    Wrap(
                      spacing: 8,
                      children: FadeSpeed.values.map((fs) {
                        final isSel = ble.fadeSpeed == fs;
                        return ChoiceChip(
                          label: Text(fs.label),
                          selected: isSel,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFF27272A),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSel ? Colors.white : const Color(0xFFA1A1AA),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) ble.setFadeSpeed(fs);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF27272A)),
                const SizedBox(height: 8),

                // Color Balance calibration
                const Text(
                  'White Balance / Channel Gain Calibration (Fixes bluish/pinkish LED tints)',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
                ),
                const SizedBox(height: 8),
                _buildGainSlider('Red Gain', ble.colorBalance.redGain, const Color(0xFFEF4444), (v) {
                  ble.setColorBalance(ble.colorBalance.copyWith(redGain: v));
                }),
                _buildGainSlider('Green Gain', ble.colorBalance.greenGain, const Color(0xFF10B981), (v) {
                  ble.setColorBalance(ble.colorBalance.copyWith(greenGain: v));
                }),
                _buildGainSlider('Blue Gain', ble.colorBalance.blueGain, const Color(0xFF38BDF8), (v) {
                  ble.setColorBalance(ble.colorBalance.copyWith(blueGain: v));
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. QUICK PRESETS & CUSTOM SWATCHES CARD
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          ble.removeCustomSwatch(color);
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

  Widget _buildGainSlider(String label, double val, Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF27272A),
              thumbColor: color,
              trackHeight: 3,
            ),
            child: Slider(
              value: val,
              min: 0.2,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 45,
          child: Text('${(val * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA))),
        ),
      ],
    );
  }

  Widget _buildSwatchTile({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
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
                : [],
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

  void _showSaveSceneDialog(BuildContext context, BleLedService ble) {
    final nameCtrl = TextEditingController(text: 'My Scene');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Save Current Lighting as Scene', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Scene Name',
            labelStyle: TextStyle(color: Color(0xFFA1A1AA)),
            filled: true,
            fillColor: Color(0xFF27272A),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              ble.saveUserScene(nameCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            hintText: '#RRGGBB',
            filled: true,
            fillColor: Color(0xFF27272A),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
