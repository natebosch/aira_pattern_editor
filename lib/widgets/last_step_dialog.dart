import 'package:flutter/material.dart';

class LastStepDialog extends StatefulWidget {
  final int lastStep;
  final Function(int) onSave;

  const LastStepDialog({
    super.key,
    required this.lastStep,
    required this.onSave,
  });

  @override
  State<LastStepDialog> createState() => _LastStepDialogState();
}

class _LastStepDialogState extends State<LastStepDialog> {
  late int _lastStep;

  @override
  void initState() {
    super.initState();
    _lastStep = widget.lastStep;
  }

  void _handleSliderChange(double value) {
    setState(() {
      _lastStep = value.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Last Step'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          Row(
            children: [
              const Text('Last Step: '),
              Expanded(
                child: Slider(
                  value: _lastStep.toDouble(),
                  min: 1,
                  max: 32,
                  divisions: 31, // 1-32
                  label: '$_lastStep',
                  onChanged: _handleSliderChange,
                ),
              ),
              Text('$_lastStep'),
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
            widget.onSave(_lastStep);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
