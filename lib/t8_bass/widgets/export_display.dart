import 'package:flutter/material.dart';
import '../models/sequencer_models.dart';

class BassExportDisplay extends StatelessWidget {
  final BassSequence data;

  const BassExportDisplay({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Bass Pattern'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Copy the .prm content below:'),
          const SizedBox(height: 10),
          Container(
            width: double.maxFinite,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                data.toPrmFormat(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
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
