import 'package:flutter/material.dart';
import '../models/sequencer_models.dart';

class ImportDialog extends StatefulWidget {
  final Function(SequencerData) onImport;

  const ImportDialog({super.key, required this.onImport});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleImport() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      try {
        final data = SequencerData.fromPrmFormat(content);
        widget.onImport(data);
        Navigator.of(context).pop();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Pattern'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          children: [
            const Text(
              'Paste .prm file content:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste .prm file content here...',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _handleImport, child: const Text('Import')),
      ],
    );
  }
}
