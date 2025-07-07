import 'package:flutter/material.dart';
import '../models/sequencer_models.dart';

class BassImportDialog extends StatefulWidget {
  final Function(BassSequence) onImport;

  const BassImportDialog({super.key, required this.onImport});

  @override
  State<BassImportDialog> createState() => _BassImportDialogState();
}

class _BassImportDialogState extends State<BassImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _import() {
    try {
      final data = BassSequence.fromPrmFormat(_controller.text);
      widget.onImport(data);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Bass Pattern'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Paste .prm file content:'),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste .prm content here...',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _import, child: const Text('Import')),
      ],
    );
  }
}
