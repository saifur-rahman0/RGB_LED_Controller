import 'package:flutter/material.dart';
import '../../protocol/elk_protocol.dart';
import '../../services/ble_led_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glowing_card.dart';
import '../widgets/hex_log_viewer.dart';

class SystemTab extends StatefulWidget {
  final BleLedService bleService;

  const SystemTab({super.key, required this.bleService});

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> {
  bool _specsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bleService = widget.bleService;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. FLASH ALERT NOTIFICATION SIMULATOR
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassSectionHeader(
                  icon: Icons.notifications_active_rounded,
                  title: 'NOTIFICATION FLASH ALERT SIMULATOR',
                  accentColor: GlassColors.connected,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Trigger a visual flash pulse on your strip. The comfort engine pulses 3 times and restores previous state.',
                  style: TextStyle(fontSize: 10.5, color: GlassColors.textMuted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAlertButton(
                      context,
                      label: 'Success (Green)',
                      color: const Color(0xFF00FF88),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _buildAlertButton(
                      context,
                      label: 'Critical Alert (Red)',
                      color: GlassColors.offline,
                      icon: Icons.error_outline_rounded,
                    ),
                    _buildAlertButton(
                      context,
                      label: 'Notice (Cyan)',
                      color: const Color(0xFF00E5FF),
                      icon: Icons.info_outline_rounded,
                    ),
                    _buildAlertButton(
                      context,
                      label: 'Warning (Amber)',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. PREFERENCES & BEHAVIOR
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassSectionHeader(
                  icon: Icons.tune_rounded,
                  title: 'PREFERENCES & BEHAVIOR',
                  accentColor: GlassColors.scanning,
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: GlassColors.connected,
                  title: const Text(
                    'Auto-connect on launch',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 11.5,
                    ),
                  ),
                  subtitle: const Text(
                    'Automatically scans and connects to target ELK-BLEDOM upon startup.',
                    style: TextStyle(
                      fontSize: 10,
                      color: GlassColors.textMuted,
                    ),
                  ),
                  value: bleService.autoConnectOnLaunch,
                  onChanged: (val) => bleService.setAutoConnectOnLaunch(val),
                ),
                const Divider(color: GlassColors.borderDefault, height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: GlassColors.offline,
                  title: const Text(
                    'Turn lights OFF when app closes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 11.5,
                    ),
                  ),
                  subtitle: const Text(
                    'Transmits 0x00 power standby packet before window destruction.',
                    style: TextStyle(
                      fontSize: 10,
                      color: GlassColors.textMuted,
                    ),
                  ),
                  value: bleService.turnOffOnClose,
                  onChanged: (val) => bleService.setTurnOffOnClose(val),
                ),
                const Divider(color: GlassColors.borderDefault, height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: GlassColors.violet,
                  title: const Text(
                    'Show all Bluetooth devices in selector',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 11.5,
                    ),
                  ),
                  subtitle: const Text(
                    'When disabled, only known ELK-BLEDOM / duoCo peripherals are listed.',
                    style: TextStyle(
                      fontSize: 10,
                      color: GlassColors.textMuted,
                    ),
                  ),
                  value: bleService.showAllDevices,
                  onChanged: (val) => bleService.setShowAllDevices(val),
                ),
                const Divider(color: GlassColors.borderDefault, height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: GlassColors.cyan,
                  title: const Text(
                    'Reduce Flashing (Comfort Safety Limiter)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 11.5,
                    ),
                  ),
                  subtitle: const Text(
                    'Low-pass filter that clamps rapid color jumps and locks strobe effects.',
                    style: TextStyle(
                      fontSize: 10,
                      color: GlassColors.textMuted,
                    ),
                  ),
                  value: bleService.reduceFlashing,
                  onChanged: (val) => bleService.setReduceFlashing(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. HARDWARE & BLE PROTOCOL SPECIFICATIONS (COLLAPSIBLE)
          GlowingCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () =>
                      setState(() => _specsExpanded = !_specsExpanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: GlassSectionHeader(
                      icon: Icons.memory_rounded,
                      title: 'HARDWARE & GATT SPECIFICATIONS',
                      accentColor: GlassColors.purple,
                      trailing: Icon(
                        _specsExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: GlassColors.textMuted,
                      ),
                    ),
                  ),
                ),
                if (_specsExpanded) ...[
                  const SizedBox(height: 10),
                  _buildSpecRow(
                    'Target Hardware MAC',
                    ElkProtocol.targetDeviceAddress,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 6),
                  _buildSpecRow(
                    'Primary Service UUID',
                    bleService.activeServiceUuid,
                  ),
                  const SizedBox(height: 6),
                  _buildSpecRow(
                    'Active Write Char UUID',
                    '${bleService.activeCharUuid} (withoutResponse)',
                  ),
                  const SizedBox(height: 6),
                  _buildSpecRow(
                    'Init Handshake Packet',
                    '7E 07 83 02 01 01 01 00 EF (300ms post-connect)',
                  ),
                  const SizedBox(height: 6),
                  _buildSpecRow(
                    'Rate Throttling Queue',
                    '55ms (~18 Hz) Coalescing Queue',
                  ),
                  const SizedBox(height: 6),
                  _buildSpecRow(
                    'Comfort Engine',
                    'Smoothstep fade • Gains: ${bleService.colorBalance.redGain.toStringAsFixed(2)}R, ${bleService.colorBalance.greenGain.toStringAsFixed(2)}G, ${bleService.colorBalance.blueGain.toStringAsFixed(2)}B',
                  ),
                  const SizedBox(height: 6),
                  _buildSpecRow(
                    'Packet Structure',
                    '9-byte fixed width: 0x7E [LEN] [CMD] ... 0xEF',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. LIVE BLE HEX PACKET LOG
          HexLogViewer(
            bleService: bleService,
            height: 260,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertButton(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        widget.bleService.flashAlert(color);
        showNeonToast(
          context,
          'Triggered $label 3-pulse flash alert',
          icon: icon,
          accentColor: color,
        );
      },
    );
  }

  Widget _buildSpecRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GlassColors.canvas.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight
              ? GlassColors.purple.withValues(alpha: 0.45)
              : GlassColors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: GlassColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? const Color(0xFFC4B5FD) : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
