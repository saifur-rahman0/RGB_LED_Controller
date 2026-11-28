import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ble_led_service.dart';
import '../theme/glass_theme.dart';

class HexLogViewer extends StatelessWidget {
  final BleLedService bleService;
  final double height;

  const HexLogViewer({
    super.key,
    required this.bleService,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    final logs = bleService.hexLogs;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF09090B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GlassColors.borderRaised.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: GlassColors.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: GlassColors.borderDefault),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 15,
                  color: GlassColors.connected,
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE BLE GATT LOG (9-BYTE 0x7E...0xEF)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: GlassColors.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: GlassColors.borderDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${logs.length} pkts',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: GlassColors.textSubtle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  tooltip: 'Copy Raw Log',
                  visualDensity: VisualDensity.compact,
                  color: GlassColors.textMuted,
                  onPressed: () {
                    final text = bleService.getAllLogsAsText();
                    Clipboard.setData(ClipboardData(text: text));
                    showNeonToast(
                      context,
                      'Raw packet log copied to clipboard',
                      icon: Icons.copy_rounded,
                      accentColor: GlassColors.scanning,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 15),
                  tooltip: 'Clear Log',
                  visualDensity: VisualDensity.compact,
                  color: GlassColors.textMuted,
                  onPressed: () {
                    bleService.clearLogs();
                    showNeonToast(
                      context,
                      'Cleared BLE packet log',
                      icon: Icons.delete_sweep_rounded,
                      accentColor: GlassColors.textMuted,
                    );
                  },
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
                        color: GlassColors.textPlaceholder,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return _LogRow(entry: logs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatefulWidget {
  final BleHexLogEntry entry;

  const _LogRow({required this.entry});

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    Color dirColor;
    switch (entry.direction) {
      case 'TX':
        dirColor = GlassColors.connected;
        break;
      case 'ERR':
        dirColor = GlassColors.offline;
        break;
      case 'INFO':
        dirColor = GlassColors.scanning;
        break;
      default:
        dirColor = GlassColors.purple;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.timeFormatted,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                color: GlassColors.textPlaceholder,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: dirColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: dirColor.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                entry.direction,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: dirColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5),
                  children: [
                    if (entry.hexPayload.isNotEmpty) ...[
                      TextSpan(
                        text: '${entry.hexPayload} ',
                        style: const TextStyle(
                          color: GlassColors.scanning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '→ ${entry.description}',
                        style: const TextStyle(color: GlassColors.textMuted),
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
      ),
    );
  }
}
