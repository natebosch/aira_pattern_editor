import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sequencer_models.dart';

class ExportDisplay extends StatelessWidget {
  final SequencerData data;

  const ExportDisplay({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final prmContent = data.toPrmFormat();

    return AlertDialog(
      title: const Text('Exported .prm Content'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Copy to clipboard:'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Copy to clipboard
                    Clipboard.setData(ClipboardData(text: prmContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(
                    prmContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
