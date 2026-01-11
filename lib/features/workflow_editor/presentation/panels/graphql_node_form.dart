import 'package:flutter/material.dart';
import '../../domain/models/node_config.dart';
import '../../../graphql/presentation/widgets/graphql_editors.dart';
import '../../../../core/ui/components/app_input.dart';

class GraphQLNodeForm extends StatefulWidget {
  final String nodeId;
  final GraphQLNodeConfig config;
  final ValueChanged<NodeConfig> onSave;

  const GraphQLNodeForm({
    super.key,
    required this.nodeId,
    required this.config,
    required this.onSave,
  });

  @override
  State<GraphQLNodeForm> createState() => _GraphQLNodeFormState();
}

class _GraphQLNodeFormState extends State<GraphQLNodeForm> {
  late TextEditingController _endpointCtrl;
  late TextEditingController _storeAsCtrl;
  String _query = '';
  String _variables = '';
  // Maps/Auth ignored for brevity in this MVP form, just supporting basics

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: widget.config.endpoint);
    _storeAsCtrl = TextEditingController(text: widget.config.storeAs);
    _query = widget.config.query;
    _variables = widget.config.variablesJson;
  }
  
  void _save() {
    final newConfig = GraphQLNodeConfig(
       mode: widget.config.mode,
       endpoint: _endpointCtrl.text,
       storeAs: _storeAsCtrl.text,
       query: _query,
       variablesJson: _variables,
       headers: widget.config.headers, // Preserve existing
       auth: widget.config.auth, // Preserve existing
    );
    widget.onSave(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Endpoint', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        AppInput(
          controller: _endpointCtrl,
          onChanged: (_) => _save(),
          hintText: 'https://api.example.com/graphql',
        ),
        const SizedBox(height: 12),
        const Text('Store Result As (Context Key)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        AppInput(
          controller: _storeAsCtrl,
           onChanged: (_) => _save(),
           hintText: 'gqlResult',
        ),
        const SizedBox(height: 16),
        const Text('Query Template', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 150,
          child: GraphQLQueryEditor(
            query: _query,
            onChanged: (val) {
               _query = val;
               _save();
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text('Variables Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 100,
          child: GraphQLVariablesEditor(
            variables: _variables,
            onChanged: (val) {
               _variables = val;
               _save();
            },
          ),
        ),
      ],
    );
  }
}
