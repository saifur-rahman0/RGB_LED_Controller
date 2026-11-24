import 'package:flutter/material.dart';
import '../../protocol/elk_protocol.dart';
import '../../services/ble_led_service.dart';
import '../widgets/glowing_card.dart';
import '../widgets/hex_log_viewer.dart';

class SystemTab extends StatelessWidget {
  final BleLedService bleService;

  const SystemTab({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. FLASH ALERT NOTIFICATION SIMULATOR
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text(
                      'NOTIFICATION FLASH ALERT SIMULATOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trigger a visual flash pulse on your LED strip. The comfort engine pulses 3 times and gracefully restores your previous color and power state.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
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
                      color: const Color(0xFFEF4444),
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
          const SizedBox(height: 20),

          // 2. PREFERENCES & BEHAVIOR
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: Color(0xFF38BDF8)),
                    SizedBox(width: 8),
                    Text(
                      'PREFERENCES & BEHAVIOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Auto-connect toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF10B981),
                  title: const Text(
                    'Auto-connect on launch',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Automatically initiates BLE scan and connects to FF:FF:10:C5:29:1F / ELK-BLEDOM upon startup.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                  ),
                  value: bleService.autoConnectOnLaunch,
                  onChanged: (val) => bleService.setAutoConnectOnLaunch(val),
                ),
                const Divider(color: Color(0xFF27272A)),

                // Turn OFF on close toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFEF4444),
                  title: const Text(
                    'Turn lights OFF when app closes',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Transmits 0x00 power standby packet before window destruction to avoid leaving strip lit.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                  ),
                  value: bleService.turnOffOnClose,
                  onChanged: (val) => bleService.setTurnOffOnClose(val),
                ),
                const Divider(color: Color(0xFF27272A)),

                // Show all Bluetooth devices toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF8B5CF6),
                  title: const Text(
                    'Show all Bluetooth devices in selector',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  subtitle: const Text(
                    'When disabled, only known ELK-BLEDOM, duoCo, and LED strip peripherals are listed. Enable if your controller uses an unlisted manufacturer name.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                  ),
                  value: bleService.showAllDevices,
                  onChanged: (val) => bleService.setShowAllDevices(val),
                ),
                const Divider(color: Color(0xFF27272A)),

                // Reduce Flashing (comfort safety limiter)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF06B6D4),
                  title: const Text(
                    'Reduce Flashing (Comfort Safety Limiter)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Applies an exponential low-pass filter to clamp rapid color oscillation and minimize visual fatigue.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                  ),
                  value: bleService.reduceFlashing,
                  onChanged: (val) => bleService.setReduceFlashing(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. HARDWARE & BLE PROTOCOL SPECIFICATIONS
          GlowingCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.memory_rounded, size: 18, color: Color(0xFFA855F7)),
                    SizedBox(width: 8),
                    Text(
                      'VERIFIED HARDWARE & GATT SPECIFICATIONS',
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

                _buildSpecRow('Target Hardware MAC', ElkProtocol.targetDeviceAddress, isHighlight: true),
                const SizedBox(height: 8),
                _buildSpecRow('Primary Service UUID', bleService.activeServiceUuid),
                const SizedBox(height: 8),
                _buildSpecRow('Active Write Char UUID', '${bleService.activeCharUuid} (writeWithoutResponse)'),
                const SizedBox(height: 8),
                _buildSpecRow('Init Handshake Packet', '7E 07 83 02 01 01 01 00 EF (300ms post-connect)'),
                const SizedBox(height: 8),
                _buildSpecRow('Rate Throttling Queue', '55ms (~18 Hz) Coalescing / Stale Frame Dropping'),
                const SizedBox(height: 8),
                _buildSpecRow('Comfort Engine', 'Smoothstep fade curve • RGB balance gains: ${bleService.colorBalance.redGain.toStringAsFixed(2)}R, ${bleService.colorBalance.greenGain.toStringAsFixed(2)}G, ${bleService.colorBalance.blueGain.toStringAsFixed(2)}B'),
                const SizedBox(height: 8),
                _buildSpecRow('Packet Structure', '9-byte fixed width: 0x7E [LEN] [CMD] ... 0xEF'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. LIVE BLE HEX PACKET LOG
          HexLogViewer(
            bleService: bleService,
            height: 320,
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
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        bleService.flashAlert(color);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Triggered $label 3-pulse flash alert'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF18181B),
          ),
        );
      },
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? const Color(0xFFA855F7).withValues(alpha: 0.4) : const Color(0xFF27272A),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
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
