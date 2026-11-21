import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../protocol/elk_protocol.dart';
import '../services/ble_led_service.dart';
import 'tabs/effects_tab.dart';
import 'tabs/light_tab.dart';
import 'tabs/scenes_tab.dart';
import 'tabs/system_tab.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> with SingleTickerProviderStateMixin, WindowListener {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final ble = Provider.of<BleLedService>(context, listen: false);
    await ble.handleAppClose();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BleLedService>(context);
    final accentGlow = ble.isPoweredOn && ble.status == BleLedStatus.connected
        ? ble.currentColor
        : const Color(0xFF6366F1); // Indigo fallback

    return Scaffold(
      backgroundColor: const Color(0xFF111114), // Deep Zinc
      body: Column(
        children: [
          // 1. DESKTOP HEADER & DRAG AREA
          DragToMoveArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                border: const Border(bottom: BorderSide(color: Color(0xFF27272A))),
                boxShadow: [
                  BoxShadow(
                    color: accentGlow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // App Logo & Title
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentGlow, const Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: accentGlow.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RGBZap Flutter Console',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'ELK-BLEDOM Controller [FF:FF:10:C5:29:1F]',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // Live Status Pill
                    _buildStatusPill(ble.status),

                    const Spacer(),

                    // Device Selector Dropdown
                    _buildDeviceSelector(ble),
                    const SizedBox(width: 8),

                    // Refresh / Scan Button
                    IconButton(
                      icon: ble.status == BleLedStatus.scanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: ble.status == BleLedStatus.scanning ? 'Scanning in progress...' : 'Scan for Devices',
                      color: const Color(0xFFA1A1AA),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (ble.status == BleLedStatus.scanning) {
                          ble.stopScan();
                        } else {
                          ble.startScan();
                        }
                      },
                    ),
                    const SizedBox(width: 12),

                    // Master Connection Toggle Switch
                    _buildMasterConnectionSwitch(ble),
                  ],
                ),
              ),
            ),
          ),

          // 2. NAVIGATION TAB BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF141417),
              border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Row(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentGlow.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF71717A),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('LIGHT'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('EFFECTS'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.motion_photos_on_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('SCENES'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.terminal_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('SYSTEM'),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Quick Power Indicator Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ble.isPoweredOn ? 'POWER ON' : 'POWER OFF',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LightTab(bleService: ble),
                EffectsTab(bleService: ble),
                ScenesTab(bleService: ble),
                SystemTab(bleService: ble),
              ],
            ),
          ),

          // 4. BOTTOM STATUS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F12),
              border: Border(top: BorderSide(color: Color(0xFF1F1F23))),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_audio_rounded, size: 13, color: Color(0xFF71717A)),
                const SizedBox(width: 6),
                Text(
                  ble.selectedDevice != null
                      ? 'Target: ${ble.selectedDevice!.name ?? 'ELK-BLEDOM'} (${ble.selectedDevice!.deviceId})'
                      : 'No BLE peripheral connected',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF71717A)),
                ),
                const Spacer(),
                Text(
                  'Protocol: 0x7E...0xEF 55ms Rate Limiting • WinRT BleOutputProperty.withoutResponse',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: Colors.white.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(BleLedStatus status) {
    Color dotColor;
    Color bgColor;
    String label;

    switch (status) {
      case BleLedStatus.connected:
        dotColor = const Color(0xFF10B981); // Emerald
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        label = 'CONNECTED';
        break;
      case BleLedStatus.connecting:
        dotColor = const Color(0xFFFBBF24); // Amber
        bgColor = const Color(0xFFFBBF24).withValues(alpha: 0.15);
        label = 'CONNECTING...';
        break;
      case BleLedStatus.scanning:
        dotColor = const Color(0xFF38BDF8); // Sky
        bgColor = const Color(0xFF38BDF8).withValues(alpha: 0.15);
        label = 'SCANNING...';
        break;
      case BleLedStatus.reconnecting:
        dotColor = const Color(0xFFFB923C); // Orange
        bgColor = const Color(0xFFFB923C).withValues(alpha: 0.15);
        label = 'RECONNECTING...';
        break;
      case BleLedStatus.offline:
        dotColor = const Color(0xFFEF4444); // Red
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
        label = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dotColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(BleLedService ble) {
    final devices = ble.scannedDevices;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E2E33)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF1C1C20),
          value: ble.selectedDevice?.deviceId,
          hint: const Text(
            'Select BLE Device',
            style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFA1A1AA)),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          items: devices.isEmpty && ble.selectedDevice == null
              ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text('Scanning for devices...', style: TextStyle(color: Color(0xFF71717A))),
                  )
                ]
              : {
                  if (ble.selectedDevice != null && !devices.any((d) => d.deviceId == ble.selectedDevice!.deviceId))
                    ble.selectedDevice!,
                  ...devices,
                }.map((device) {
                  final isTarget = device.deviceId.toUpperCase() == ElkProtocol.targetDeviceAddress;
                  final isElk = (device.name ?? '').toUpperCase().contains(ElkProtocol.targetDeviceNamePrefix);

                  return DropdownMenuItem<String>(
                    value: device.deviceId,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTarget ? Icons.star_rounded : Icons.bluetooth_rounded,
                          size: 15,
                          color: isTarget ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          device.name != null && device.name!.isNotEmpty ? device.name! : 'Unknown Device',
                          style: TextStyle(
                            fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                            color: isTarget ? const Color(0xFFFBBF24) : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${device.deviceId})',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF71717A)),
                        ),
                        if (isTarget || isElk) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TARGET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
          onChanged: (selectedId) {
            if (selectedId != null) {
              final chosen = devices.firstWhere(
                (d) => d.deviceId == selectedId,
                orElse: () => ble.selectedDevice!,
              );
              ble.selectDevice(chosen);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMasterConnectionSwitch(BleLedService ble) {
    final isConnected = ble.status == BleLedStatus.connected;
    final isBusy = ble.status == BleLedStatus.connecting || ble.status == BleLedStatus.reconnecting;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected
            ? const Color(0xFF10B981).withValues(alpha: 0.2)
            : const Color(0xFF27272A),
        foregroundColor: isConnected ? const Color(0xFF34D399) : const Color(0xFFA1A1AA),
        side: BorderSide(
          color: isConnected ? const Color(0xFF10B981) : const Color(0xFF3F3F46),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(
        isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
        size: 16,
      ),
      label: Text(
        isConnected
            ? 'DISCONNECT'
            : isBusy
                ? 'CONNECTING...'
                : 'CONNECT',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
      ),
      onPressed: isBusy
          ? null
          : () {
              if (isConnected) {
                ble.disconnectDevice();
              } else {
                if (ble.selectedDevice != null) {
                  ble.connectDevice(ble.selectedDevice!);
                } else {
                  ble.startScan();
                }
              }
            },
    );
  }
}
