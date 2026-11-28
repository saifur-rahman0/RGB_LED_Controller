import 'dart:ui';
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
import 'theme/glass_theme.dart';

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

    final isLive = ble.isPoweredOn && ble.status == BleLedStatus.connected;
    final accentGlow = isLive ? ble.currentColor : GlassColors.indigo;

    final tabPages = [
      LightTab(bleService: ble),
      EffectsTab(bleService: ble),
      ScreenSyncTab(screenSync: screenSync),
      AudioReactiveTab(audioService: audio),
      ToolsTab(apiService: api, obsService: obs),
      SystemTab(bleService: ble),
    ];

    return Scaffold(
      backgroundColor: GlassColors.voidBg,
      body: Stack(
        children: [
          // Ambient reactive subsurface glow orbs for Glassmorphism depth
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GlassColors.base,
                gradient: RadialGradient(
                  center: const Alignment(0.65, -0.75),
                  radius: 1.5,
                  colors: [
                    accentGlow.withValues(alpha: isLive ? 0.10 : 0.03),
                    GlassColors.voidBg,
                  ],
                  stops: const [0.0, 0.78],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, 0.8),
                  radius: 1.35,
                  colors: [
                    GlassColors.cyan.withValues(alpha: isLive ? 0.045 : 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),

          // Main Shell Column
          Column(
            children: [
              // 1. CUSTOM WINDOWS TITLEBAR & CONTROL DECK
              _buildWindowsTitleBar(ble, accentGlow, isLive),

              // 2. RESPONSIVE WORKSPACE (SIDEBAR ON >= 920px, TABS ON < 920px)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 920;

                    if (isWide) {
                      return Row(
                        children: [
                          _buildDesktopSidebar(ble, accentGlow, isLive),
                          Expanded(
                            child: Container(
                              color: Colors.transparent,
                              child: tabPages[_selectedNavIndex],
                            ),
                          ),
                        ],
                      );
                    }

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
        ],
      ),
    );
  }

  /// Custom Frameless TitleBar with Frosted Glass, BLE Controls, and Win32 Buttons
  Widget _buildWindowsTitleBar(
    BleLedService ble,
    Color accentGlow,
    bool isLive,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: GlassColors.canvas.withValues(alpha: 0.88),
            border: const Border(
              bottom: BorderSide(color: GlassColors.borderDefault),
            ),
            boxShadow: [
              BoxShadow(
                color: accentGlow.withValues(alpha: isLive ? 0.1 : 0.05),
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
                              colors: [accentGlow, GlassColors.cyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: accentGlow.withValues(alpha: 0.45),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RGB LED Console',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ELK-BLEDOM • FF:FF:10:C5:29:1F',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Live Pulsing Status Pill
                        _PulsingStatusPill(status: ble.status),
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
                              valueColor: AlwaysStoppedAnimation(
                                GlassColors.scanning,
                              ),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 17),
                    tooltip: ble.status == BleLedStatus.scanning
                        ? 'Scanning...'
                        : 'Scan for BLE Devices',
                    color: GlassColors.textMuted,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (ble.status == BleLedStatus.scanning) {
                        ble.stopScan();
                      } else {
                        ble.startScan();
                      }
                    },
                  ),
                  const SizedBox(width: 4),

                  // Master Connect/Disconnect Switch
                  _buildMasterConnectionSwitch(ble),
                  const SizedBox(width: 4),

                  // Keyboard Shortcuts Cheatsheet Trigger
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    tooltip: 'Keyboard Shortcuts & Hotkeys',
                    color: GlassColors.textSubtle,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showShortcutsDialog(context),
                  ),
                  const SizedBox(width: 6),
                ],
              ),

              // Native Windows TitleBar Buttons (Min, Max/Restore, Close)
              _buildWindowControls(),
            ],
          ),
        ),
      ),
    );
  }

  void _showShortcutsDialog(BuildContext context) {
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
            Icon(Icons.keyboard_rounded, size: 22, color: GlassColors.cyan),
            SizedBox(width: 10),
            Text(
              'Global Shortcuts & Cheatsheet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shortcutRow('Master Power Toggle', 'Ctrl + Alt + Home'),
              _shortcutRow('Increase Brightness', 'Ctrl + Alt + PageUp'),
              _shortcutRow('Decrease Brightness', 'Ctrl + Alt + PageDown'),
              _shortcutRow('Toggle Screen Sync', 'Ctrl + Alt + End'),
              _shortcutRow('Toggle Audio Reactive', 'Ctrl + Alt + Insert'),
              _shortcutRow('Cycle Scenes', 'Ctrl + Alt + Shift + ←/→'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassColors.scanning,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcutRow(String action, String keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: const TextStyle(
              fontSize: 11.5,
              color: GlassColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GlassColors.borderDefault,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GlassColors.borderRaised),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: GlassColors.cyan,
              ),
            ),
          ),
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
          icon: _isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
          iconSize: _isMaximized ? 12 : 14,
          tooltip: _isMaximized ? 'Restore Window' : 'Maximize',
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
  Widget _buildDesktopSidebar(
    BleLedService ble,
    Color accentGlow,
    bool isLive,
  ) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: GlassColors.canvas.withValues(alpha: 0.85),
        border: const Border(
          right: BorderSide(color: GlassColors.borderDefault),
        ),
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

          // Navigation Links with hover & neon states
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                return _SidebarNavItem(
                  title: item.title,
                  icon: item.icon,
                  isSelected: _selectedNavIndex == index,
                  accentGlow: accentGlow,
                  onTap: () => _switchTab(index),
                );
              },
            ),
          ),

          // Sidebar Footer with Quick Power Pill and Active Color Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: GlassColors.abyss,
              border: Border(
                top: BorderSide(color: GlassColors.borderDefault),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Power Pill Button
                _PowerPillButton(
                  isPoweredOn: ble.isPoweredOn,
                  onTap: () => ble.togglePower(),
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
                        color: ble.isPoweredOn
                            ? ble.currentColor
                            : GlassColors.borderDefault,
                        border: Border.all(color: Colors.white30, width: 1.5),
                        boxShadow: ble.isPoweredOn
                            ? [
                                BoxShadow(
                                  color: ble.currentColor.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: GlassColors.textSubtle,
                            ),
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
      decoration: BoxDecoration(
        color: GlassColors.canvas.withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: GlassColors.borderDefault),
        ),
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
                color: GlassColors.borderDefault,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentGlow.withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: GlassColors.textSubtle,
              labelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
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
                color: GlassColors.glass,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ble.isPoweredOn
                      ? GlassColors.connected.withValues(alpha: 0.45)
                      : GlassColors.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
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
                  const SizedBox(width: 6),
                  Text(
                    ble.isPoweredOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ble.isPoweredOn
                          ? GlassColors.connected
                          : GlassColors.textSubtle,
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

  /// Bottom Protocol & Peripheral Status Bar (28px)
  Widget _buildBottomStatusBar(BleLedService ble) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: GlassColors.abyss,
        border: Border(top: BorderSide(color: GlassColors.borderSubtle)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bluetooth_audio_rounded,
            size: 13,
            color: GlassColors.textSubtle,
          ),
          const SizedBox(width: 6),
          SelectableText(
            ble.selectedDevice != null
                ? 'Target: ${ble.selectedDevice!.name ?? 'ELK-BLEDOM'} (${ble.selectedDevice!.deviceId})'
                : 'No BLE peripheral connected',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: GlassColors.textSubtle,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              'Active Char: ${ble.activeCharUuid} • 55ms Queue • Comfort Engine',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        color: GlassColors.elevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GlassColors.borderMuted),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: GlassColors.elevated,
          value: ble.selectedDevice?.deviceId,
          hint: const Text(
            'Select Device',
            style: TextStyle(fontSize: 11.5, color: GlassColors.textSubtle),
          ),
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: GlassColors.textMuted,
            size: 18,
          ),
          style: const TextStyle(fontSize: 11.5, color: Colors.white),
          items: devices.isEmpty && ble.selectedDevice == null
              ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text(
                      'Scanning for devices...',
                      style: TextStyle(color: GlassColors.textSubtle),
                    ),
                  ),
                ]
              : {
                  if (ble.selectedDevice != null &&
                      !devices.any(
                        (d) => d.deviceId == ble.selectedDevice!.deviceId,
                      ))
                    ble.selectedDevice!,
                  ...devices,
                }.map((device) {
                  final isTarget =
                      device.deviceId.toUpperCase() ==
                      ElkProtocol.targetDeviceAddress;
                  final isElk = (device.name ?? '').toUpperCase().contains(
                    ElkProtocol.targetDeviceNamePrefix,
                  );

                  return DropdownMenuItem<String>(
                    value: device.deviceId,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTarget
                              ? Icons.star_rounded
                              : Icons.bluetooth_rounded,
                          size: 14,
                          color: isTarget
                              ? GlassColors.connecting
                              : GlassColors.scanning,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            device.name != null && device.name!.isNotEmpty
                                ? device.name!
                                : 'Unknown Device',
                            style: TextStyle(
                              fontWeight: isTarget
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isTarget
                                  ? GlassColors.connecting
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${device.deviceId})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: GlassColors.textSubtle,
                          ),
                        ),
                        if (isTarget || isElk) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: GlassColors.connecting.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TARGET',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: GlassColors.connecting,
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
    final isBusy =
        ble.status == BleLedStatus.connecting ||
        ble.status == BleLedStatus.reconnecting;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected
            ? GlassColors.connected.withValues(alpha: 0.2)
            : GlassColors.borderDefault,
        foregroundColor: isConnected
            ? GlassColors.connectedLight
            : GlassColors.textMuted,
        side: BorderSide(
          color: isConnected
              ? GlassColors.connected
              : GlassColors.borderRaised,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(
        isConnected
            ? Icons.bluetooth_connected_rounded
            : Icons.bluetooth_disabled_rounded,
        size: 15,
      ),
      label: Text(
        isConnected
            ? 'DISCONNECT'
            : isBusy
            ? 'CONNECTING...'
            : 'CONNECT',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
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

/// Pulsing Neon Status Pill for the title bar
class _PulsingStatusPill extends StatefulWidget {
  final BleLedStatus status;

  const _PulsingStatusPill({required this.status});

  @override
  State<_PulsingStatusPill> createState() => _PulsingStatusPillState();
}

class _PulsingStatusPillState extends State<_PulsingStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Color bgColor;
    final String label;
    final bool shouldPulse;

    switch (widget.status) {
      case BleLedStatus.connected:
        dotColor = GlassColors.connected;
        bgColor = GlassColors.connected.withValues(alpha: 0.15);
        label = 'CONNECTED';
        shouldPulse = false;
        break;
      case BleLedStatus.connecting:
        dotColor = GlassColors.connecting;
        bgColor = GlassColors.connecting.withValues(alpha: 0.15);
        label = 'CONNECTING...';
        shouldPulse = true;
        break;
      case BleLedStatus.scanning:
        dotColor = GlassColors.scanning;
        bgColor = GlassColors.scanning.withValues(alpha: 0.15);
        label = 'SCANNING...';
        shouldPulse = true;
        break;
      case BleLedStatus.reconnecting:
        dotColor = GlassColors.reconnecting;
        bgColor = GlassColors.reconnecting.withValues(alpha: 0.15);
        label = 'RECONNECTING...';
        shouldPulse = true;
        break;
      case BleLedStatus.offline:
        dotColor = GlassColors.offline;
        bgColor = GlassColors.offline.withValues(alpha: 0.12);
        label = 'OFFLINE';
        shouldPulse = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final pulse = shouldPulse ? _pulseController.value : 0.4;
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(
                        alpha: shouldPulse ? (0.4 + 0.45 * pulse) : 0.7,
                      ),
                      blurRadius: shouldPulse ? (4 + 5 * pulse) : 5,
                      spreadRadius: shouldPulse ? (pulse * 1.5) : 1,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar Navigation Item with hover & active neon indicator
class _SidebarNavItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color accentGlow;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.accentGlow,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.accentGlow.withValues(alpha: 0.14)
        : (_isHovered
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.transparent);

    final borderColor = widget.isSelected
        ? widget.accentGlow.withValues(alpha: 0.5)
        : (_isHovered
              ? GlassColors.borderRaised.withValues(alpha: 0.5)
              : Colors.transparent);

    final iconColor = widget.isSelected
        ? widget.accentGlow
        : (_isHovered ? GlassColors.textPrimary : GlassColors.textMuted);

    final textColor = widget.isSelected || _isHovered
        ? GlassColors.textPrimary
        : GlassColors.textMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: Duration(milliseconds: widget.isSelected ? 180 : 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.6,
                  color: textColor,
                ),
              ),
              if (widget.isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentGlow,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentGlow.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Power Pill Button in sidebar footer
class _PowerPillButton extends StatefulWidget {
  final bool isPoweredOn;
  final VoidCallback onTap;

  const _PowerPillButton({required this.isPoweredOn, required this.onTap});

  @override
  State<_PowerPillButton> createState() => _PowerPillButtonState();
}

class _PowerPillButtonState extends State<_PowerPillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isPoweredOn;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? GlassColors.connected.withValues(alpha: _isHovered ? 0.24 : 0.16)
                : (_isHovered
                      ? GlassColors.borderRaised.withValues(alpha: 0.5)
                      : GlassColors.borderDefault),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? GlassColors.connected.withValues(alpha: _isHovered ? 0.7 : 0.45)
                  : (_isHovered
                        ? GlassColors.borderHover
                        : GlassColors.borderRaised),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: GlassColors.connected.withValues(alpha: 0.18),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.power_settings_new_rounded,
                size: 16,
                color: active ? GlassColors.connected : GlassColors.textSubtle,
              ),
              const SizedBox(width: 8),
              Text(
                active ? 'STRIP POWER ON' : 'STRIP POWER OFF',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: active ? GlassColors.connected : GlassColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final hoverBg =
        widget.isClose ? GlassColors.offline : GlassColors.borderRaised;
    final iconColor = _isHovered ? Colors.white : GlassColors.textMuted;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 46,
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
