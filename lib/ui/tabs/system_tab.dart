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
          // 1. SYSTEM SETTINGS & PREFERENCES
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. HARDWARE & BLE PROTOCOL SPECIFICATIONS
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
                _buildSpecRow('Primary Service UUID', ElkProtocol.serviceUuid),
                const SizedBox(height: 8),
                _buildSpecRow('Write Char UUID', '${ElkProtocol.writeCharacteristicUuid} (writeWithoutResponse)'),
                const SizedBox(height: 8),
                _buildSpecRow('Init Handshake Packet', '7E 07 83 02 01 01 01 00 EF (300ms post-connect)'),
                const SizedBox(height: 8),
                _buildSpecRow('Rate Throttling Queue', '55ms (~18 Hz) Coalescing / Stale Frame Dropping'),
                const SizedBox(height: 8),
                _buildSpecRow('Packet Structure', '9-byte fixed width: 0x7E [LEN] [CMD] ... 0xEF'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. LIVE BLE HEX PACKET LOG
          HexLogViewer(
            bleService: bleService,
            height: 300,
          ),
        ],
      ),
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
