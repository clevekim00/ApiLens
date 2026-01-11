import 'package:flutter/material.dart';
import '../../domain/models/node_config.dart';

// --- WS Connect Form ---
class WebSocketConnectForm extends StatefulWidget {
  final WebSocketConnectNodeConfig config;
  final ValueChanged<WebSocketConnectNodeConfig> onSave;

  const WebSocketConnectForm({super.key, required this.config, required this.onSave});

  @override
  State<WebSocketConnectForm> createState() => _WebSocketConnectFormState();
}

class _WebSocketConnectFormState extends State<WebSocketConnectForm> {
  late TextEditingController _urlCtrl;
  late TextEditingController _storeAsCtrl;
  String _mode = 'direct';

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.config.url);
    _storeAsCtrl = TextEditingController(text: widget.config.storeAs);
    _mode = widget.config.mode;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _storeAsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(WebSocketConnectNodeConfig(
      mode: _mode,
      url: _urlCtrl.text,
      storeAs: _storeAsCtrl.text,
      // Default others for now
      protocols: widget.config.protocols,
      autoReconnect: widget.config.autoReconnect,
      reconnectPolicy: widget.config.reconnectPolicy,
      headers: widget.config.headers,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _mode,
          decoration: const InputDecoration(labelText: 'Connection Mode'),
          items: const [
            DropdownMenuItem(value: 'direct', child: Text('Direct URL')),
            DropdownMenuItem(value: 'configRef', child: Text('Use Saved Config')),
          ],
          onChanged: (val) {
             setState(() => _mode = val!);
             _save();
          },
        ),
        const SizedBox(height: 16),
        if (_mode == 'direct')
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'WebSocket URL', hintText: 'wss://..'),
            onChanged: (_) => _save(),
          )
        else
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
             child: const Text('Config Reference selection not implemented for MVP (using ws-config-001 stub)'),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _storeAsCtrl,
          decoration: const InputDecoration(labelText: 'Store Session As', hintText: 'e.g. mainWs'),
          onChanged: (_) => _save(),
        ),
      ],
    );
  }
}

// --- WS Send Form ---
class WebSocketSendForm extends StatefulWidget {
  final WebSocketSendNodeConfig config;
  final ValueChanged<WebSocketSendNodeConfig> onSave;

  const WebSocketSendForm({super.key, required this.config, required this.onSave});

  @override
  State<WebSocketSendForm> createState() => _WebSocketSendFormState();
}

class _WebSocketSendFormState extends State<WebSocketSendForm> {
  late TextEditingController _sessionKeyCtrl;
  late TextEditingController _payloadCtrl;
  String _format = 'text';

  @override
  void initState() {
    super.initState();
    _sessionKeyCtrl = TextEditingController(text: widget.config.sessionKey);
    _payloadCtrl = TextEditingController(text: widget.config.payload);
    _format = widget.config.payloadFormat;
  }
  
  @override
  void dispose() {
    _sessionKeyCtrl.dispose();
    _payloadCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(WebSocketSendNodeConfig(
      sessionKey: _sessionKeyCtrl.text,
      payloadFormat: _format,
      payload: _payloadCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _sessionKeyCtrl,
          decoration: const InputDecoration(labelText: 'Session Key', hintText: 'mainWs'),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _format,
          decoration: const InputDecoration(labelText: 'Payload Format'),
          items: const [
            DropdownMenuItem(value: 'text', child: Text('Text')),
            DropdownMenuItem(value: 'json', child: Text('JSON')),
          ],
          onChanged: (val) {
             setState(() => _format = val!);
             _save();
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _payloadCtrl,
          decoration: const InputDecoration(labelText: 'Payload (Template supported)', alignLabelWithHint: true),
          maxLines: 5,
          onChanged: (_) => _save(),
        ),
      ],
    );
  }
}

// --- WS Wait Form ---
class WebSocketWaitForm extends StatefulWidget {
  final WebSocketWaitNodeConfig config;
  final ValueChanged<WebSocketWaitNodeConfig> onSave;

  const WebSocketWaitForm({super.key, required this.config, required this.onSave});

  @override
  State<WebSocketWaitForm> createState() => _WebSocketWaitFormState();
}

class _WebSocketWaitFormState extends State<WebSocketWaitForm> {
  late TextEditingController _sessionKeyCtrl;
  late TextEditingController _timeoutCtrl;
  late TextEditingController _matchValueCtrl;
  String _matchType = 'containsText';

  @override
  void initState() {
    super.initState();
    _sessionKeyCtrl = TextEditingController(text: widget.config.sessionKey);
    _timeoutCtrl = TextEditingController(text: widget.config.timeoutMs.toString());
    _matchType = widget.config.match['type'] ?? 'containsText';
    _matchValueCtrl = TextEditingController(text: widget.config.match['value']);
  }

  @override
  void dispose() {
    _sessionKeyCtrl.dispose();
    _timeoutCtrl.dispose();
    _matchValueCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(WebSocketWaitNodeConfig(
      sessionKey: _sessionKeyCtrl.text,
      timeoutMs: int.tryParse(_timeoutCtrl.text) ?? 5000,
      match: {'type': _matchType, 'value': _matchValueCtrl.text},
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _sessionKeyCtrl,
          decoration: const InputDecoration(labelText: 'Session Key', hintText: 'mainWs'),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
             Expanded(
               child: DropdownButtonFormField<String>(
                  value: _matchType,
                  decoration: const InputDecoration(labelText: 'Match Type'),
                  items: const [
                    DropdownMenuItem(value: 'containsText', child: Text('Contains Text')),
                    DropdownMenuItem(value: 'jsonPathEquals', child: Text('JSON Path Equals')),
                    DropdownMenuItem(value: 'anyMessage', child: Text('Any Message')),
                  ],
                  onChanged: (val) {
                     setState(() => _matchType = val!);
                     _save();
                  },
              ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: TextField(
                 controller: _timeoutCtrl,
                 decoration: const InputDecoration(labelText: 'Timeout (ms)'),
                 keyboardType: TextInputType.number,
                 onChanged: (_) => _save(),
               ),
             ),
          ],
        ),
        const SizedBox(height: 16),
        if (_matchType != 'anyMessage')
          TextField(
            controller: _matchValueCtrl,
            decoration: InputDecoration(
              labelText: _matchType == 'containsText' ? 'Text to contain' : 'JSON Path (e.g. \$.type=="pong")',
            ),
            onChanged: (_) => _save(),
          ),
      ],
    );
  }
}
