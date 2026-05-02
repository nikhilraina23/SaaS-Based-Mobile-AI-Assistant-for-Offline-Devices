import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/command_engine.dart';
import '../services/permission_service.dart';

/// Data class for a quick-command chip shown in the Available Commands panel.
class _QuickCommand {
  final IconData icon;
  final String label;
  final String command;
  const _QuickCommand(this.icon, this.label, this.command);
}

/// Main screen of the Offline Assistant — styled as a command console.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CommandEngine _engine = CommandEngine();
  final PermissionService _permissionService = PermissionService();
  final ScrollController _scrollController = ScrollController();

  /// Speech-to-text runtime state.
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _speechStatus = '';
  String _speechError = '';
  String _lastSpeechWords = '';

  /// History of (command, response) pairs, newest first.
  final List<_HistoryEntry> _history = [];

  bool _isProcessing = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  /// Pre-defined quick commands the user can tap.
  static const List<_QuickCommand> _quickCommands = [
    _QuickCommand(Icons.alarm, 'Set Alarm', 'set alarm 7:00 am'),
    _QuickCommand(Icons.alarm_add, 'Multi Alarm', 'set alarm 7:00 am 5'),
    _QuickCommand(
      Icons.notifications_active,
      'Reminder',
      'remind me meeting at 6 pm',
    ),
    _QuickCommand(Icons.call, 'Call Contact', 'call mom'),
    _QuickCommand(Icons.sms, 'Send SMS', 'sms john hello'),
    _QuickCommand(Icons.apps, 'Open App', 'open calculator'),
    _QuickCommand(Icons.volume_up, 'Volume Up', 'increase volume'),
    _QuickCommand(Icons.brightness_6, 'Brightness Up', 'increase brightness'),
    _QuickCommand(Icons.wifi, 'Wi-Fi', 'turn on wifi'),
    _QuickCommand(Icons.network_cell, 'Mobile Data', 'turn on mobile data'),
    _QuickCommand(Icons.flight, 'Airplane Mode', 'turn on airplane mode'),
    _QuickCommand(Icons.bluetooth, 'Bluetooth', 'turn on bluetooth'),
  ];

  @override
  void initState() {
    super.initState();
    _prepareSpeech();
  }

  Future<void> _prepareSpeech() async {
    await _requestPermissionsAtStartup();
    await _initSpeech();
  }

  Future<void> _requestPermissionsAtStartup() async {
    await _permissionService.requestStartupPermissions();
    await Permission.microphone.request();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() {
        _speechError = micStatus.isPermanentlyDenied
            ? 'Microphone permission permanently denied. Open settings to allow.'
            : 'Microphone permission denied.';
      });
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        return;
      }
    }

    setState(() {
      _speechError = '';
      _speechStatus = 'Listening... speak now';
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false,
    );

    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _speechStatus = 'Speech stopped';
    });
  }

  void _toggleMic() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastSpeechWords = result.recognizedWords;
      _controller.text = _lastSpeechWords;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _onSpeechStatus(String status) {
    setState(() {
      _speechStatus = status;
      _isListening = status == 'listening';
      if (status == 'done' || status == 'notListening') {
        _isListening = false;
      }
    });
  }

  void _onSpeechError(dynamic error) {
    setState(() {
      _speechError = error?.toString() ?? 'Speech recognition error';
      _speechStatus = 'Speech error';
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processCommand([String? overrideInput]) async {
    final input = (overrideInput ?? _controller.text).trim();
    if (input.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.clear();

    final result = await _engine.process(input);

    setState(() {
      _isProcessing = false;
      _history.insert(0, _HistoryEntry(command: input, response: result));
    });

    // Scroll to top to show latest entry
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    _focusNode.requestFocus();
  }

  void _onQuickCommandTap(_QuickCommand cmd) {
    _controller.text = cmd.command;
    _processCommand(cmd.command);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.terminal, color: accent, size: 26),
            const SizedBox(width: 10),
            Text(
              'Offline Assistant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(
                    alpha: 0.5 + 0.5 * _pulseController.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Available Commands ──────────────────────────────────────
            _buildQuickCommands(accent),

            const Divider(height: 1, thickness: 0.5),

            // ── History / Output Area ──────────────────────────────────
            Expanded(child: _buildHistory(accent)),

            // ── Input Bar ──────────────────────────────────────────────
            _buildInputBar(accent, colorScheme),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick commands (Available Command list — clickable)
  // ---------------------------------------------------------------------------

  Widget _buildQuickCommands(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE COMMANDS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickCommands.map((cmd) {
              return ActionChip(
                avatar: Icon(cmd.icon, size: 16, color: accent),
                label: Text(cmd.label, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFF21262D),
                side: BorderSide(color: accent.withValues(alpha: 0.2)),
                onPressed: () => _onQuickCommandTap(cmd),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Command History / Output
  // ---------------------------------------------------------------------------

  Widget _buildHistory(Color accent) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal,
              size: 64,
              color: accent.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'No commands yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type a command or tap one above to get started',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return _HistoryCard(entry: entry, accent: accent);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Input Bar
  // ---------------------------------------------------------------------------

  Widget _buildInputBar(Color accent, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          // Prompt symbol
          Text(
            '\$ ',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'monospace',
            ),
          ),

          // Text field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter command...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _processCommand(),
                ),
                const SizedBox(height: 6),
                Text(
                  _speechError.isNotEmpty
                      ? _speechError
                      : _isListening
                          ? 'Listening... speak now'
                          : _speechEnabled
                              ? 'Tap the mic to dictate a command'
                              : 'Speech recognition unavailable',
                  style: TextStyle(
                    color: _speechError.isNotEmpty
                        ? Colors.redAccent
                        : Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Microphone button
          IconButton(
            onPressed: _toggleMic,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : accent,
            ),
            tooltip: _isListening ? 'Stop listening' : 'Start voice input',
          ),
          const SizedBox(width: 8),

          // Execute button
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : () => _processCommand(),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('Execute'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// History entry data + card widget
// =============================================================================

class _HistoryEntry {
  final String command;
  final String response;
  late final DateTime timestamp = DateTime.now();
  _HistoryEntry({required this.command, required this.response});
}

class _HistoryCard extends StatelessWidget {
  final _HistoryEntry entry;
  final Color accent;
  const _HistoryCard({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Command row
          Row(
            children: [
              Text(
                '\$ ',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Expanded(
                child: Text(
                  entry.command,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Response
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.response,
              style: TextStyle(
                color: accent.withValues(alpha: 0.85),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
