import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/local_api_service.dart';
import '../../services/obs_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glowing_card.dart';

class ToolsTab extends StatefulWidget {
  final LocalApiService apiService;
  final ObsService obsService;

  const ToolsTab({
    super.key,
    required this.apiService,
    required this.obsService,
  });

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {
  late final TextEditingController _obsHostController;
  late final TextEditingController _obsPortController;
  late final TextEditingController _obsPasswordController;

  @override
  void initState() {
    super.initState();
    _obsHostController = TextEditingController(text: widget.obsService.host);
    _obsPortController =
        TextEditingController(text: widget.obsService.port.toString());
    _obsPasswordController =
        TextEditingController(text: widget.obsService.password);
  }

  @override
  void dispose() {
    _obsHostController.dispose();
    _obsPortController.dispose();
    _obsPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.apiService;
    final obs = widget.obsService;

    return ListenableBuilder(
      listenable: Listenable.merge([api, obs]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOCAL HTTP REST API & CLI
              GlowingCard(
                glowColor: GlassColors.connected,
                isGlowing: api.isEnabled,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: GlassColors.connected.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GlassColors.connected.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.http_rounded,
                            size: 20,
                            color: GlassColors.connected,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCAL HTTP CONTROL API & CLI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: GlassColors.textMuted,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Enables external scripts, Stream Deck, and terminal CLI control',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: GlassColors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: api.isEnabled,
                          activeThumbColor: GlassColors.connected,
                          onChanged: (val) => api.setEnabled(val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Endpoint & Port
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GlassColors.canvas.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlassColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lan_rounded,
                            size: 15,
                            color: GlassColors.scanning,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Endpoint URL:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: GlassColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SelectableText(
                            'http://127.0.0.1:49732',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: api.isEnabled
                                  ? GlassColors.connected.withValues(alpha: 0.2)
                                  : GlassColors.borderDefault,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              api.isEnabled ? 'LISTENING' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: api.isEnabled
                                    ? GlassColors.connected
                                    : GlassColors.textSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Secret Bearer Token
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GlassColors.canvas.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlassColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.key_rounded,
                            size: 15,
                            color: GlassColors.connecting,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Bearer Token:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: GlassColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              api.token,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFFFDE68A),
                              ),
                              maxLines: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            tooltip: 'Copy Bearer Token',
                            visualDensity: VisualDensity.compact,
                            color: GlassColors.textMuted,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: api.token));
                              showNeonToast(
                                context,
                                'Bearer token copied to clipboard',
                                icon: Icons.copy_rounded,
                                accentColor: GlassColors.connecting,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 15),
                            tooltip: 'Regenerate Token',
                            visualDensity: VisualDensity.compact,
                            color: GlassColors.textMuted,
                            onPressed: () {
                              api.regenerateToken();
                              showNeonToast(
                                context,
                                'Generated new Bearer token',
                                icon: Icons.key_rounded,
                                accentColor: GlassColors.connected,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. AI ASSISTANT (MCP) INTEGRATION
              GlowingCard(
                glowColor: GlassColors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassSectionHeader(
                      icon: Icons.smart_toy_rounded,
                      title: 'AI ASSISTANT (MCP) INTEGRATION',
                      accentColor: GlassColors.purple,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Allow AI assistants like Claude, Cursor, or ChatGPT to set ambient lighting, switch scenes, or flash alerts upon task completion.',
                      style: TextStyle(
                        fontSize: 11,
                        color: GlassColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC4B5FD),
                        backgroundColor: GlassColors.purple.withValues(
                          alpha: 0.08,
                        ),
                        side: BorderSide(
                          color: GlassColors.purple.withValues(alpha: 0.7),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.terminal_rounded, size: 15),
                      label: const Text(
                        'Copy CLI Verification Command',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        final cmd =
                            'curl -X POST http://127.0.0.1:49732/status -H "Authorization: Bearer ${api.token}"';
                        Clipboard.setData(ClipboardData(text: cmd));
                        showNeonToast(
                          context,
                          'Copied CLI verification command',
                          icon: Icons.terminal_rounded,
                          accentColor: GlassColors.purple,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. OBS STUDIO TALLY & SCENE LINK
              GlowingCard(
                glowColor: GlassColors.offline,
                isGlowing: obs.isConnected,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: GlassColors.offline.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GlassColors.offline.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            size: 19,
                            color: GlassColors.offline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OBS STUDIO 28+ WEBSOCKET TALLY LINK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: GlassColors.textMuted,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Lights strip Red automatically while streaming or recording in OBS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: GlassColors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: obs.isEnabled,
                          activeThumbColor: GlassColors.offline,
                          onChanged: (val) => obs.setEnabled(val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _obsHostController,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                            decoration: InputDecoration(
                              labelText: 'WebSocket Host',
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                color: GlassColors.textMuted,
                              ),
                              filled: true,
                              fillColor: GlassColors.canvas,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _obsPortController,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                            decoration: InputDecoration(
                              labelText: 'Port (4455)',
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                color: GlassColors.textMuted,
                              ),
                              filled: true,
                              fillColor: GlassColors.canvas,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassColors.borderDefault,
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: GlassColors.borderRaised,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            final portNum =
                                int.tryParse(_obsPortController.text) ?? 4455;
                            obs.updateConfig(
                              host: _obsHostController.text,
                              port: portNum,
                            );
                            showNeonToast(
                              context,
                              'Saved OBS WebSocket config',
                              icon: Icons.videocam_rounded,
                              accentColor: GlassColors.offline,
                            );
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'Red on Stream',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ),
                            value: obs.redOnLive,
                            activeColor: GlassColors.offline,
                            onChanged: (val) =>
                                obs.updateConfig(redOnLive: val ?? true),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'Red on Record',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ),
                            value: obs.redOnRecord,
                            activeColor: GlassColors.offline,
                            onChanged: (val) =>
                                obs.updateConfig(redOnRecord: val ?? true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. GLOBAL WINDOWS HOTKEYS REFERENCE
              GlowingCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassSectionHeader(
                      icon: Icons.keyboard_rounded,
                      title: 'GLOBAL WINDOWS HOTKEYS',
                      accentColor: GlassColors.cyan,
                    ),
                    const SizedBox(height: 10),
                    _buildHotkeyRow(
                      'Master Power Toggle',
                      'Ctrl + Alt + Home',
                      shaded: true,
                    ),
                    _buildHotkeyRow(
                      'Increase Brightness',
                      'Ctrl + Alt + PageUp',
                    ),
                    _buildHotkeyRow(
                      'Decrease Brightness',
                      'Ctrl + Alt + PageDown',
                      shaded: true,
                    ),
                    _buildHotkeyRow(
                      'Toggle Screen Sync (Ambilight)',
                      'Ctrl + Alt + End',
                    ),
                    _buildHotkeyRow(
                      'Toggle Audio Reactive Visualizer',
                      'Ctrl + Alt + Insert',
                      shaded: true,
                    ),
                    _buildHotkeyRow(
                      'Cycle Next / Prev Scene',
                      'Ctrl + Alt + Shift + Left / Right',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotkeyRow(String action, String keys, {bool shaded = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: shaded
            ? Colors.white.withValues(alpha: 0.025)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFE4E4E7)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GlassColors.borderDefault,
              borderRadius: BorderRadius.circular(5),
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
}
