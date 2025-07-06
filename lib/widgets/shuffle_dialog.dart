import 'package:flutter/material.dart';

class ShuffleDialog extends StatefulWidget {
  final int shuffle;
  final Function(int) onSave;

  const ShuffleDialog({super.key, required this.shuffle, required this.onSave});

  @override
  State<ShuffleDialog> createState() => _ShuffleDialogState();
}

class _ShuffleDialogState extends State<ShuffleDialog> {
  late int _shuffle;

  @override
  void initState() {
    super.initState();
    _shuffle = widget.shuffle;
  }

  void _handleSliderChange(double value) {
    setState(() {
      _shuffle = value.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Shuffle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          Row(
            children: [
              const Text('Shuffle: '),
              Expanded(
                child: Slider(
                  value: _shuffle.toDouble(),
                  min: -90,
                  max: 90,
                  divisions: 180, // -90 to 90 with 1 unit steps
                  label: '$_shuffle',
                  onChanged: _handleSliderChange,
                ),
              ),
              Text('$_shuffle'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(_shuffle);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
