import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ble_led_service.dart';

class HexLogViewer extends StatelessWidget {
  final BleLedService bleService;
  final double height;

  const HexLogViewer({
    super.key,
    required this.bleService,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    final logs = bleService.hexLogs;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF09090B), // Zinc-950
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF141417),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                const Text(
                  'LIVE BLE GATTLOG (9-BYTE 0x7E...0xEF)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} packets',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF71717A),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  tooltip: 'Copy Raw Log',
                  visualDensity: VisualDensity.compact,
                  color: const Color(0xFFA1A1AA),
                  onPressed: () {
                    final text = bleService.getAllLogsAsText();
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Raw packet log copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 15),
                  tooltip: 'Clear Log',
                  visualDensity: VisualDensity.compact,
                  color: const Color(0xFFA1A1AA),
                  onPressed: () => bleService.clearLogs(),
                ),
              ],
            ),
          ),

          // Log List
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No packets transmitted yet. Connect controller to observe traffic.',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF52525B),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      return _buildLogRow(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(BleHexLogEntry entry) {
    Color dirColor;
    switch (entry.direction) {
      case 'TX':
        dirColor = const Color(0xFF10B981); // Emerald
        break;
      case 'ERR':
        dirColor = const Color(0xFFEF4444); // Red
        break;
      case 'INFO':
        dirColor = const Color(0xFF38BDF8); // Sky blue
        break;
      default:
        dirColor = const Color(0xFFA855F7); // Purple
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            entry.timeFormatted,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(width: 8),

          // Direction Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: dirColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: dirColor.withValues(alpha: 0.4), width: 0.8),
            ),
            child: Text(
              entry.direction,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: dirColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Payload / Description
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                children: [
                  if (entry.hexPayload.isNotEmpty) ...[
                    TextSpan(
                      text: '${entry.hexPayload} ',
                      style: const TextStyle(
                        color: Color(0xFFF4F4F5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '(${entry.description})',
                      style: const TextStyle(color: Color(0xFFA1A1AA)),
                    ),
                  ] else ...[
                    TextSpan(
                      text: entry.description,
                      style: TextStyle(color: dirColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
