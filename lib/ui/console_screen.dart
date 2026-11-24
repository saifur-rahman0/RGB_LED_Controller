import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../protocol/elk_protocol.dart';
import '../services/audio_reactive_service.dart';
import '../services/ble_led_service.dart';
import '../services/local_api_service.dart';
import '../services/obs_service.dart';
import '../services/screen_sync_service.dart';
import 'tabs/audio_reactive_tab.dart';
import 'tabs/effects_tab.dart';
import 'tabs/light_tab.dart';
import 'tabs/screen_sync_tab.dart';
import 'tabs/system_tab.dart';
import 'tabs/tools_tab.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen>
    with SingleTickerProviderStateMixin, WindowListener {
  late TabController _tabController;
  bool _isMaximized = false;
  int _selectedNavIndex = 0;

  static const List<({String title, IconData icon})> _navItems = [
    (title: 'LIGHT', icon: Icons.lightbulb_rounded),
    (title: 'EFFECTS', icon: Icons.auto_awesome_rounded),
    (title: 'SCREEN', icon: Icons.screen_search_desktop_rounded),
    (title: 'AUDIO', icon: Icons.graphic_eq_rounded),
    (title: 'TOOLS', icon: Icons.construction_rounded),
    (title: 'SYSTEM', icon: Icons.terminal_rounded),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
    _tabController = TabController(length: _navItems.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _selectedNavIndex = _tabController.index;
        });
      }
    });
  }

  void _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = max);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
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

  void _switchTab(int index) {
    if (index >= 0 && index < _navItems.length) {
      _tabController.animateTo(index);
      setState(() {
        _selectedNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BleLedService>(context);
    final screenSync = Provider.of<ScreenSyncService>(context);
    final audio = Provider.of<AudioReactiveService>(context);
    final api = Provider.of<LocalApiService>(context);
    final obs = Provider.of<ObsService>(context);

    final accentGlow = ble.isPoweredOn && ble.status == BleLedStatus.connected
        ? ble.currentColor
        : const Color(0xFF6366F1); // Indigo fallback

    final tabPages = [
      LightTab(bleService: ble),
      EffectsTab(bleService: ble),
      ScreenSyncTab(screenSync: screenSync),
      AudioReactiveTab(audioService: audio),
      ToolsTab(apiService: api, obsService: obs),
      SystemTab(bleService: ble),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF111114), // Deep Zinc
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111114),
          gradient: RadialGradient(
            center: const Alignment(0.65, -0.75),
            radius: 1.5,
            colors: [
              accentGlow.withValues(
                alpha: ble.isPoweredOn && ble.status == BleLedStatus.connected ? 0.08 : 0.02,
              ),
              const Color(0xFF111114),
            ],
            stops: const [0.0, 0.75],
          ),
        ),
        child: Column(
          children: [
            // 1. CUSTOM WINDOWS TITLEBAR & CONTROL DECK
            _buildWindowsTitleBar(ble, accentGlow),

            // 2. RESPONSIVE WORKSPACE (SIDEBAR ON >= 920px, TABS ON < 920px)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;

                  if (isWide) {
                    return Row(
                      children: [
                        // Left Desktop Navigation Sidebar
                        _buildDesktopSidebar(ble, accentGlow),

                        // Main Content Area
                        Expanded(
                          child: Container(
                            color: const Color(0xFF111114),
                            child: tabPages[_selectedNavIndex],
                          ),
                        ),
                      ],
                    );
                  }

                  // Compact Mobile / Narrow Window View with Top TabBar
                  return Column(
                    children: [
                      _buildCompactTabBar(ble, accentGlow),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: tabPages,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. BOTTOM HARDWARE STATUS BAR
            _buildBottomStatusBar(ble),
          ],
        ),
      ),
    );
  }

  /// Custom Frameless TitleBar with Drag Area, BLE Controls, and Windows Min/Max/Close Buttons
  Widget _buildWindowsTitleBar(BleLedService ble, Color accentGlow) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        border: const Border(bottom: BorderSide(color: Color(0xFF27272A))),
        boxShadow: [
          BoxShadow(
            color: accentGlow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag Window Title Region
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: Colors.transparent,
                child: Row(
                  children: [
                    // Glowing App Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentGlow, const Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: accentGlow.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RGBZap LED Console',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'ELK-BLEDOM • FF:FF:10:C5:29:1F',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Live Status Pill
                    _buildStatusPill(ble.status),
                  ],
                ),
              ),
            ),
          ),

          // BLE Device Controls (Non-drag clickable region)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDeviceSelector(ble),
              const SizedBox(width: 6),

              // Refresh / Scan Button
              IconButton(
                icon: ble.status == BleLedStatus.scanning
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 17),
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
              const SizedBox(width: 8),

              // Master Connect/Disconnect Switch
              _buildMasterConnectionSwitch(ble),
              const SizedBox(width: 12),
            ],
          ),

          // Native Windows TitleBar Buttons (Min, Max/Restore, Close)
          _buildWindowControls(),
        ],
      ),
    );
  }

  /// Native Windows 11 style minimize, maximize/restore, and close buttons
  Widget _buildWindowControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleBarButton(
          icon: Icons.remove_rounded,
          tooltip: 'Minimize',
          onPressed: () => windowManager.minimize(),
        ),
        _TitleBarButton(
          icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
          iconSize: _isMaximized ? 12 : 14,
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _TitleBarButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          isClose: true,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }

  /// Left Sidebar Navigation Rail for Wide Displays (>= 920px)
  Widget _buildDesktopSidebar(BleLedService ble, Color accentGlow) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF141417),
        border: Border(right: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'CONSOLE SECTIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;

                return InkWell(
                  onTap: () => _switchTab(index),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentGlow.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? accentGlow.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: isSelected ? accentGlow : const Color(0xFFA1A1AA),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: 0.6,
                            color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentGlow,
                              boxShadow: [
                                BoxShadow(
                                  color: accentGlow.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Sidebar Footer with Quick Power and Active Color Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F12),
              border: Border(top: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Power Pill Button
                InkWell(
                  onTap: () => ble.togglePower(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: ble.isPoweredOn
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ble.isPoweredOn
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : const Color(0xFF3F3F46),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 16,
                          color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ble.isPoweredOn ? 'STRIP POWER ON' : 'STRIP POWER OFF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Active Color preview badge
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ble.currentColor,
                        border: Border.all(color: Colors.white30, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: ble.currentColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${ble.currentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${ble.currentBrightness}% Brightness',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Horizontal TabBar for Narrow Windows (< 920px)
  Widget _buildCompactTabBar(BleLedService ble, Color accentGlow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF141417),
        border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
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
              labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
              dividerColor: Colors.transparent,
              tabs: _navItems.map((item) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 15),
                      const SizedBox(width: 6),
                      Text(item.title),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),

          // Quick Power indicator
          InkWell(
            onTap: () => ble.togglePower(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ble.isPoweredOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ble.isPoweredOn ? const Color(0xFF10B981) : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Protocol & Peripheral Status Bar
  Widget _buildBottomStatusBar(BleLedService ble) {
    return Container(
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
            'Active Char: ${ble.activeCharUuid} • 55ms Rate Queue • Comfort Engine Active',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.35),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dotColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.7),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(BleLedService ble) {
    final devices = ble.visibleDevices;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E2E33)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF1C1C20),
          value: ble.selectedDevice?.deviceId,
          hint: const Text(
            'Select Device',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF71717A)),
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFA1A1AA), size: 18),
          style: const TextStyle(fontSize: 11.5, color: Colors.white),
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
                          size: 14,
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
                        const SizedBox(width: 6),
                        Text(
                          '(${device.deviceId})',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: Color(0xFF71717A)),
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
                                fontSize: 8.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(
        isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
        size: 15,
      ),
      label: Text(
        isConnected
            ? 'DISCONNECT'
            : isBusy
                ? 'CONNECTING...'
                : 'CONNECT',
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

/// Helper button for Windows frameless title bar with hover states
class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool isClose;
  final VoidCallback onPressed;

  const _TitleBarButton({
    required this.icon,
    this.iconSize = 14,
    required this.tooltip,
    this.isClose = false,
    required this.onPressed,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color hoverBg = widget.isClose ? const Color(0xFFE81123) : const Color(0xFF27272A);
    Color iconColor = _isHovered && widget.isClose ? Colors.white : const Color(0xFFA1A1AA);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 48,
            color: _isHovered ? hoverBg : Colors.transparent,
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
