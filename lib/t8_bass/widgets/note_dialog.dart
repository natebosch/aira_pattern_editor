import 'package:flutter/material.dart';
import '../models/sequencer_models.dart';

class NoteDialog extends StatefulWidget {
  final BassStep stepData;
  final Function(BassStep) onSave;

  const NoteDialog({super.key, required this.stepData, required this.onSave});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late BassStep _currentStepData;

  @override
  void initState() {
    super.initState();
    _currentStepData = widget.stepData;
  }

  void _updateNote(double value) {
    if (value == 0) {
      _currentStepData = _currentStepData.copyWith(note: Note.off, pitch: 0);
    } else if (value >= 86) {
      _currentStepData = _currentStepData.copyWith(note: Note.tie, pitch: 84);
    } else {
      _currentStepData = _currentStepData.copyWith(
        note: Note.start,
        pitch: (value - 1)
            .toInt(), // Subtract 1 so slider value 1 maps to pitch 0
      );
    }
    setState(() {});
  }

  double get _sliderValue {
    return switch (_currentStepData.note) {
      Note.off => 0,
      Note.start =>
        (_currentStepData.pitch + 1)
            .toDouble(), // Add 1 so pitch 0 maps to slider value 1
      Note.tie => 86,
    };
  }

  String get _noteLabel {
    return switch (_currentStepData.note) {
      Note.off => 'Off',
      Note.start =>
        'Pitch: ${BassStep.pitchToNoteName(_currentStepData.pitch)}',
      Note.tie => 'Tie',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bass Note'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _noteLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _sliderValue,
              min: 0,
              max: 86,
              divisions: 86,
              onChanged: _updateNote,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 20,
              child: Stack(
                children: [
                  // Position labels at specific points
                  Positioned(left: 0, child: const Text('Off |')),
                  Positioned(
                    left: 30,
                    child: Text(BassStep.pitchToNoteName(0)),
                  ),
                  Positioned(
                    right: 30,
                    child: Text(BassStep.pitchToNoteName(84)),
                  ),
                  Positioned(right: 0, child: const Text('| Tie')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Slide', softWrap: false),
                    value: _currentStepData.isSlide,
                    onChanged: (value) {
                      setState(() {
                        _currentStepData = _currentStepData.copyWith(
                          isSlide: value ?? false,
                        );
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Accent', softWrap: false),
                    value: _currentStepData.isAccent,
                    onChanged: (value) {
                      setState(() {
                        _currentStepData = _currentStepData.copyWith(
                          isAccent: value ?? false,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_currentStepData);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
