import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/local_api_service.dart';
import '../../services/obs_service.dart';
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
    _obsPortController = TextEditingController(text: widget.obsService.port.toString());
    _obsPasswordController = TextEditingController(text: widget.obsService.password);
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOCAL HTTP REST API & CLI
              GlowingCard(
                glowColor: const Color(0xFF10B981),
                isGlowing: api.isEnabled,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.http_rounded, size: 22, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCAL HTTP CONTROL API & CLI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: Color(0xFFA1A1AA),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Enables external scripts, Stream Deck, and terminal CLI control',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF71717A)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: api.isEnabled,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (val) => api.setEnabled(val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Endpoint & Port
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141417),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lan_rounded, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 8),
                          const Text(
                            'Endpoint URL:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA)),
                          ),
                          const SizedBox(width: 8),
                          const SelectableText(
                            'http://127.0.0.1:49732',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: api.isEnabled
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              api.isEnabled ? 'LISTENING' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: api.isEnabled ? const Color(0xFF10B981) : const Color(0xFF71717A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secret Bearer Token
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141417),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded, size: 16, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 8),
                          const Text(
                            'Bearer Token:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              api.token,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: Color(0xFFFDE68A)),
                              maxLines: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            tooltip: 'Copy Bearer Token',
                            visualDensity: VisualDensity.compact,
                            color: const Color(0xFFA1A1AA),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: api.token));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bearer token copied to clipboard!')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 15),
                            tooltip: 'Regenerate Token',
                            visualDensity: VisualDensity.compact,
                            color: const Color(0xFFA1A1AA),
                            onPressed: () => api.regenerateToken(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. AI ASSISTANT (MODEL CONTEXT PROTOCOL / MCP) INTEGRATION
              GlowingCard(
                glowColor: const Color(0xFFA855F7),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy_rounded, size: 20, color: Color(0xFFA855F7)),
                        SizedBox(width: 8),
                        Text(
                          'AI ASSISTANT (MCP) INTEGRATION',
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
                      'Allow AI assistants like Claude, Cursor, or ChatGPT to set ambient lighting, switch scenes, or flash alerts upon task completion.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA), height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC4B5FD),
                        side: const BorderSide(color: Color(0xFFA855F7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.terminal_rounded, size: 16),
                      label: const Text('Copy Claude MCP Setup Command'),
                      onPressed: () {
                        final cmd = 'curl -X POST http://127.0.0.1:49732/status -H "Authorization: Bearer ${api.token}"';
                        Clipboard.setData(ClipboardData(text: cmd));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied CLI verification command to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. OBS STUDIO TALLY & SCENE LINK
              GlowingCard(
                glowColor: const Color(0xFFEF4444),
                isGlowing: obs.isConnected,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.videocam_rounded, size: 22, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OBS STUDIO 28+ WEBSOCKET TALLY LINK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: Color(0xFFA1A1AA),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lights strip Red automatically while streaming or recording in OBS',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF71717A)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: obs.isEnabled,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) => obs.setEnabled(val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Host & Port configuration
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _obsHostController,
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              labelText: 'WebSocket Host',
                              labelStyle: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                              filled: true,
                              fillColor: Color(0xFF141417),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _obsPortController,
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              labelText: 'Port (4455)',
                              labelStyle: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                              filled: true,
                              fillColor: Color(0xFF141417),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27272A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final portNum = int.tryParse(_obsPortController.text) ?? 4455;
                            obs.updateConfig(host: _obsHostController.text, port: portNum);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tally switches
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Red on Stream', style: TextStyle(fontSize: 12, color: Colors.white)),
                            value: obs.redOnLive,
                            activeColor: const Color(0xFFEF4444),
                            onChanged: (val) => obs.updateConfig(redOnLive: val ?? true),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Red on Record', style: TextStyle(fontSize: 12, color: Colors.white)),
                            value: obs.redOnRecord,
                            activeColor: const Color(0xFFEF4444),
                            onChanged: (val) => obs.updateConfig(redOnRecord: val ?? true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. GLOBAL WINDOWS HOTKEYS REFERENCE
              GlowingCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.keyboard_rounded, size: 20, color: Color(0xFF06B6D4)),
                        SizedBox(width: 8),
                        Text(
                          'GLOBAL WINDOWS HOTKEYS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHotkeyRow('Master Power Toggle', 'Ctrl + Alt + Home'),
                    _buildHotkeyRow('Increase Brightness', 'Ctrl + Alt + PageUp'),
                    _buildHotkeyRow('Decrease Brightness', 'Ctrl + Alt + PageDown'),
                    _buildHotkeyRow('Toggle Screen Sync (Ambilight)', 'Ctrl + Alt + End'),
                    _buildHotkeyRow('Toggle Audio Reactive Visualizer', 'Ctrl + Alt + Insert'),
                    _buildHotkeyRow('Cycle Next / Prev Scene', 'Ctrl + Alt + Shift + Left / Right'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotkeyRow(String action, String keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(fontSize: 12, color: Color(0xFFE4E4E7))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF141417),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Text(
              keys,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
            ),
          ),
        ],
      ),
    );
  }
}
