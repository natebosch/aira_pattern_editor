import 'package:flutter/material.dart';
import '../models/sequencer_models.dart';

class ProbabilityDialog extends StatefulWidget {
  final StepData stepData;
  final Function(StepData) onSave;

  const ProbabilityDialog({
    super.key,
    required this.stepData,
    required this.onSave,
  });

  @override
  State<ProbabilityDialog> createState() => _ProbabilityDialogState();
}

class _ProbabilityDialogState extends State<ProbabilityDialog> {
  late int _hitProbability;
  late int _repeatProbability;

  @override
  void initState() {
    super.initState();
    _hitProbability = widget.stepData.hitProbability;
    _repeatProbability = widget.stepData.repeatProbability;
  }

  @override
  Widget build(BuildContext context) {
    final hasRepeat = widget.stepData.repeatType != RepeatType.none;

    return AlertDialog(
      title: const Text('Edit Probabilities'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hit probability slider
          Row(
            children: [
              const Text('Prob: '),
              Expanded(
                child: Slider(
                  value: _hitProbability.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9, // 10, 20, 30, ..., 100
                  label: '$_hitProbability%',
                  onChanged: (value) {
                    setState(() {
                      _hitProbability = value.round();
                    });
                  },
                ),
              ),
              Text('$_hitProbability%'),
            ],
          ),
          // Repeat probability slider (only if has repeat)
          if (hasRepeat) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Rep:  '),
                Expanded(
                  child: Slider(
                    value: _repeatProbability.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9, // 10, 20, 30, ..., 100
                    label: '$_repeatProbability%',
                    onChanged: (value) {
                      setState(() {
                        _repeatProbability = value.round();
                      });
                    },
                  ),
                ),
                Text('$_repeatProbability%'),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedStep = widget.stepData.copyWith(
              hitProbability: _hitProbability,
              repeatProbability: _repeatProbability,
            );
            widget.onSave(updatedStep);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
