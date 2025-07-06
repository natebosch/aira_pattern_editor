import 'package:flutter/material.dart';

class VelocityDialog extends StatefulWidget {
  final int velocity;
  final Function(int) onSave;

  const VelocityDialog({
    super.key,
    required this.velocity,
    required this.onSave,
  });

  @override
  State<VelocityDialog> createState() => _VelocityDialogState();
}

class _VelocityDialogState extends State<VelocityDialog> {
  late int _velocity;

  @override
  void initState() {
    super.initState();
    _velocity = widget.velocity;
  }

  void _handleSliderChange(double value) {
    setState(() {
      _velocity = value.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Velocity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          Row(
            children: [
              const Text('Velocity: '),
              Expanded(
                child: Slider(
                  value: _velocity.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10, // 0-10
                  label: '$_velocity',
                  onChanged: _handleSliderChange,
                ),
              ),
              Text('$_velocity'),
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
            widget.onSave(_velocity);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
