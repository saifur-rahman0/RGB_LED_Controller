import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../services/ble_led_service.dart';
import '../../services/comfort_engine.dart';
import '../theme/glass_theme.dart';
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
  bool _comfortExpanded = true;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. LIVE GLOWING PREVIEW & POWER CONTROLS
          GlowingCard(
            glowColor: currentColor,
            isGlowing: ble.isPoweredOn && isOnline,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Dual-halo Neon Preview Circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ble.isPoweredOn
                        ? currentColor
                        : GlassColors.borderDefault,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: ble.isPoweredOn
                        ? [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.65),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.9),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      ble.isPoweredOn
                          ? Icons.lightbulb_rounded
                          : Icons.lightbulb_outline_rounded,
                      color: ble.isPoweredOn
                          ? (ThemeData.estimateBrightnessForColor(
                                      currentColor,
                                    ) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87)
                          : GlassColors.textSubtle,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Color Hex & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ble.isPoweredOn
                                ? 'ACTIVE ILLUMINATION'
                                : 'LIGHT STANDBY',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: ble.isPoweredOn
                                  ? GlassColors.connected
                                  : GlassColors.textSubtle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ble.isPoweredOn
                                  ? GlassColors.connected
                                  : GlassColors.textSubtle,
                              boxShadow: ble.isPoweredOn
                                  ? [
                                      const BoxShadow(
                                        color: GlassColors.connected,
                                        blurRadius: 5,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GlassColors.borderDefault,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: GlassColors.borderRaised,
                              ),
                            ),
                            child: SelectableText(
                              _hexTextController.text,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            tooltip: 'Copy hex code to clipboard',
                            color: GlassColors.textMuted,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _hexTextController.text),
                              );
                              showNeonToast(
                                context,
                                'Copied ${_hexTextController.text} to clipboard',
                                icon: Icons.copy_rounded,
                                accentColor: currentColor,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ble.isPoweredOn
                            ? GlassColors.connected.withValues(alpha: 0.2)
                            : GlassColors.borderDefault,
                        foregroundColor: ble.isPoweredOn
                            ? GlassColors.connectedLight
                            : GlassColors.textMuted,
                        side: BorderSide(
                          color: ble.isPoweredOn
                              ? GlassColors.connected
                              : GlassColors.borderRaised,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.power_settings_new_rounded, size: 15),
                      label: const Text(
                        'ON',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () => ble.powerOn(),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !ble.isPoweredOn
                            ? GlassColors.offline.withValues(alpha: 0.2)
                            : GlassColors.borderDefault,
                        foregroundColor: !ble.isPoweredOn
                            ? GlassColors.offlineLight
                            : GlassColors.textMuted,
                        side: BorderSide(
                          color: !ble.isPoweredOn
                              ? GlassColors.offline
                              : GlassColors.borderRaised,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.power_off_rounded, size: 15),
                      label: const Text(
                        'OFF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () => ble.powerOff(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. HARDWARE BRIGHTNESS SLIDER
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassSectionHeader(
                  icon: Icons.brightness_6_rounded,
                  title: 'HARDWARE BRIGHTNESS',
                  accentColor: GlassColors.connecting,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: GlassColors.connecting.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GlassColors.connecting.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '${ble.currentBrightness}%',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: GlassColors.connecting,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.brightness_low_rounded,
                      size: 15,
                      color: GlassColors.textSubtle,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: buildNeonSliderTheme(
                          context,
                          GlassColors.connecting,
                        ),
                        child: Slider(
                          value: ble.currentBrightness.toDouble(),
                          min: 1,
                          max: 100,
                          onChanged: (val) => ble.sendBrightness(val.round()),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.brightness_high_rounded,
                      size: 16,
                      color: GlassColors.connecting,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. USER CUSTOM NAMED SCENES
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassSectionHeader(
                  icon: Icons.movie_filter_rounded,
                  title: 'CUSTOM NAMED SCENES',
                  accentColor: GlassColors.scanning,
                  trailing: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: GlassColors.scanning,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_add_rounded, size: 14),
                    label: const Text(
                      'Save Current',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _showSaveSceneDialog(context, ble),
                  ),
                ),
                const SizedBox(height: 8),
                if (ble.userScenes.isEmpty)
                  const GlassEmptyState(
                    icon: Icons.movie_filter_outlined,
                    title: 'No scenes saved yet',
                    subtitle: 'Tap "Save Current" to bookmark color & brightness',
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ble.userScenes.map((scene) {
                      return InkWell(
                        onTap: () => ble.applyUserScene(scene),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: GlassColors.borderDefault.withValues(
                              alpha: 0.75,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: scene.color.withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scene.color.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scene.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scene.color.withValues(alpha: 0.85),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                scene.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${scene.brightness}%',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: GlassColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Delete scene',
                                child: InkWell(
                                  onTap: () => ble.deleteUserScene(scene.id),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: GlassColors.textSubtle,
                                  ),
                                ),
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
          const SizedBox(height: 12),

          // 4. INTERACTIVE CHROMATIC WHEEL CARD (ZERO OVERFLOW + AMBIENT HALO)
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                GlassSectionHeader(
                  icon: Icons.palette_rounded,
                  title: 'INTERACTIVE CHROMATIC WHEEL',
                  accentColor: GlassColors.scanning,
                  trailing: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GlassColors.textMuted,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                      side: const BorderSide(color: GlassColors.borderRaised),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 13),
                    label: const Text(
                      'Edit HEX',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _showHexEditDialog(context, ble),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle reactive halo behind the hue wheel
                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(
                                alpha: ble.isPoweredOn ? 0.16 : 0.04,
                              ),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 280,
                          child: ColorPicker(
                            pickerColor: currentColor,
                            onColorChanged: (newColor) => ble.sendRgb(newColor),
                            portraitOnly: true,
                            paletteType: PaletteType.hueWheel,
                            enableAlpha: false,
                            displayThumbColor: true,
                            hexInputBar: false,
                            colorPickerWidth: 260,
                            pickerAreaHeightPercent: 0.82,
                            labelTypes: const [],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. COMFORT ENGINE (COLLAPSIBLE SMOOTH FADING & COLOR BALANCE)
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () =>
                      setState(() => _comfortExpanded = !_comfortExpanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: GlassSectionHeader(
                      icon: Icons.spa_rounded,
                      title: 'COMFORT ENGINE (SMOOTH FADING & BALANCE)',
                      accentColor: GlassColors.connected,
                      trailing: Icon(
                        _comfortExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: GlassColors.textMuted,
                      ),
                    ),
                  ),
                ),
                if (_comfortExpanded) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Fade Speed:',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      ...FadeSpeed.values.map((fs) {
                        final isSel = ble.fadeSpeed == fs;
                        return ChoiceChip(
                          label: Text(fs.label),
                          selected: isSel,
                          selectedColor: GlassColors.connected,
                          backgroundColor: GlassColors.borderDefault,
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isSel
                                ? GlassColors.connected
                                : GlassColors.borderRaised,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 1,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 10.5,
                            color: isSel
                                ? Colors.black
                                : GlassColors.textMuted,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) ble.setFadeSpeed(fs);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: GlassColors.borderDefault),
                  const SizedBox(height: 6),
                  const Text(
                    'White Balance / Channel Gain Calibration',
                    style: TextStyle(fontSize: 10.5, color: GlassColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  _buildGainSlider(
                    'Red Gain',
                    ble.colorBalance.redGain,
                    GlassColors.offline,
                    (v) => ble.setColorBalance(
                      ble.colorBalance.copyWith(redGain: v),
                    ),
                  ),
                  _buildGainSlider(
                    'Green Gain',
                    ble.colorBalance.greenGain,
                    GlassColors.connected,
                    (v) => ble.setColorBalance(
                      ble.colorBalance.copyWith(greenGain: v),
                    ),
                  ),
                  _buildGainSlider(
                    'Blue Gain',
                    ble.colorBalance.blueGain,
                    GlassColors.scanning,
                    (v) => ble.setColorBalance(
                      ble.colorBalance.copyWith(blueGain: v),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 6. QUICK PRESETS & CUSTOM SWATCHES CARD
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassSectionHeader(
                  icon: Icons.auto_awesome_rounded,
                  title: 'STANDARD PRESETS',
                  accentColor: GlassColors.purple,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _standardPresets.map((color) {
                    final isSelected =
                        currentColor.toARGB32() == color.toARGB32();
                    return _GlassSwatchTile(
                      color: color,
                      isSelected: isSelected,
                      onTap: () => ble.sendRgb(color),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(color: GlassColors.borderDefault),
                const SizedBox(height: 8),

                // User Saved Swatches
                GlassSectionHeader(
                  icon: Icons.bookmark_rounded,
                  title: 'SAVED CUSTOM SWATCHES',
                  accentColor: GlassColors.pink,
                  trailing: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: GlassColors.pink,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text(
                      'Save Current',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      ble.saveCustomSwatch(currentColor);
                      showNeonToast(
                        context,
                        'Saved active color to custom swatches',
                        icon: Icons.bookmark_added_rounded,
                        accentColor: GlassColors.pink,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (ble.customSwatches.isEmpty)
                  const GlassEmptyState(
                    icon: Icons.palette_outlined,
                    title: 'No custom swatches saved',
                    subtitle: 'Save colors above • Long-press a swatch to delete',
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ble.customSwatches.map((color) {
                      final isSelected =
                          currentColor.toARGB32() == color.toARGB32();
                      return _GlassSwatchTile(
                        color: color,
                        isSelected: isSelected,
                        onTap: () => ble.sendRgb(color),
                        onLongPress: () {
                          ble.removeCustomSwatch(color);
                          showNeonToast(
                            context,
                            'Removed custom swatch',
                            icon: Icons.delete_outline_rounded,
                            accentColor: GlassColors.textMuted,
                          );
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

  Widget _buildGainSlider(
    String label,
    double val,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: buildNeonSliderTheme(context, color),
            child: Slider(
              value: val,
              min: 0.2,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '${(val * 100).toInt()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: GlassColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  void _showSaveSceneDialog(BuildContext context, BleLedService ble) {
    final nameCtrl = TextEditingController(text: 'My Scene');
    void submit(BuildContext ctx) {
      ble.saveUserScene(nameCtrl.text);
      Navigator.pop(ctx);
      showNeonToast(
        context,
        'Saved scene "${nameCtrl.text.trim()}"',
        icon: Icons.movie_filter_rounded,
        accentColor: GlassColors.scanning,
      );
    }

    showGlassDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassColors.overlay.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: GlassColors.borderRaised.withValues(alpha: 0.6),
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.bookmark_add_rounded,
              size: 20,
              color: GlassColors.scanning,
            ),
            SizedBox(width: 8),
            Text(
              'Save Current Lighting as Scene',
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (_) => submit(ctx),
          decoration: InputDecoration(
            labelText: 'Scene Name',
            labelStyle: const TextStyle(color: GlassColors.textMuted),
            filled: true,
            fillColor: GlassColors.borderDefault,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassColors.scanning,
            ),
            onPressed: () => submit(ctx),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHexEditDialog(BuildContext context, BleLedService ble) {
    final textController = TextEditingController(
      text: _hexTextController.text,
    );

    void submit(BuildContext ctx) {
      final raw = textController.text.trim().replaceAll('#', '');
      if (raw.length == 6) {
        final val = int.tryParse(raw, radix: 16);
        if (val != null) {
          ble.sendRgb(Color(0xFF000000 | val));
        }
      }
      Navigator.pop(ctx);
    }

    showGlassDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassColors.overlay.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: GlassColors.borderRaised.withValues(alpha: 0.6),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.palette_rounded, size: 20, color: GlassColors.scanning),
            SizedBox(width: 8),
            Text(
              'Enter Hex Color Code',
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
          onSubmitted: (_) => submit(ctx),
          decoration: InputDecoration(
            hintText: '#RRGGBB',
            filled: true,
            fillColor: GlassColors.borderDefault,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassColors.scanning,
            ),
            onPressed: () => submit(ctx),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Glass Swatch Tile with hover scale + glow
class _GlassSwatchTile extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _GlassSwatchTile({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_GlassSwatchTile> createState() => _GlassSwatchTileState();
}

class _GlassSwatchTileState extends State<_GlassSwatchTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hexLabel =
        '#${widget.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Tooltip(
      message: widget.onLongPress != null
          ? '$hexLabel (Long-press to remove)'
          : hexLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: widget.isSelected
                      ? Colors.white
                      : (_isHovered
                            ? Colors.white.withValues(alpha: 0.65)
                            : Colors.black.withValues(alpha: 0.45)),
                  width: widget.isSelected ? 2.0 : (_isHovered ? 1.5 : 1.0),
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 1.5,
                        ),
                      ]
                    : (_isHovered
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.45),
                                blurRadius: 7,
                              ),
                            ]
                          : []),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color:
                            ThemeData.estimateBrightnessForColor(widget.color) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
