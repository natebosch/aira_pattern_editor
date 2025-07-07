import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../models/sequencer_models.dart';
import '../../t8_rhythm/widgets/last_step_dialog.dart';
import 'note_dialog.dart';
import 'import_dialog.dart';
import 'export_display.dart';

class T8BassSequencerGrid extends StatefulWidget {
  final BassSequence data;
  final Function(BassSequence) onDataChanged;

  const T8BassSequencerGrid({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<T8BassSequencerGrid> createState() => _T8BassSequencerGridState();
}

class _T8BassSequencerGridState extends State<T8BassSequencerGrid> {
  static const List<String> instrumentLabels = ['BA', 'AC', 'SL'];

  // Page mode (false = steps 1-16, true = steps 17-32)
  bool _isPage2 = false;

  double _scrollAccumulator = 0.0;
  static const double _scrollThreshold = 40.0;

  Color _stepColor(BassStep step, bool isActive, int instrument) {
    if (!isActive) {
      return Colors.grey.shade400; // Inactive steps are gray
    }

    if (instrument > 0) {
      // AC and SL rows always use the darkest blue when active
      return step.note == Note.off
          ? Colors.white
          : Color.fromRGBO(20, 40, 80, 1.0); // Very dark blue
    }

    if (step.note == Note.off) {
      return Colors.white; // White for off notes
    }
    // Interpolate between light gray-blue (pitch 0) and very dark blue (pitch 84)
    final lightColor = Color.fromRGBO(100, 120, 140, 1.0); // Light gray-blue
    final darkColor = Color.fromRGBO(20, 40, 80, 1.0); // Very dark blue
    if (step.note == Note.tie) return darkColor;

    // Use pitch to determine color - 0 is light gray-blue, 84 is very dark blue
    final pitch = step.pitch;
    final normalizedPitch = pitch / 84.0; // 0.0 to 1.0

    return Color.lerp(lightColor, darkColor, normalizedPitch)!;
  }

  void _handleStepClick(int instrument, int step) {
    // Convert display step to actual step based on current page
    final actualStep = _isPage2 ? step + 16 : step;

    if (instrument == 0) {
      // BA instrument - open note dialog
      final currentStep = widget.data.stepAt(actualStep);
      _showNoteDialog(actualStep, currentStep);
    } else {
      // AC or SL instruments - toggle the corresponding flag on BA instrument
      final baStep = widget.data.stepAt(actualStep);
      final newBaStep = baStep.copyWith(
        isAccent: instrument == 1 ? !baStep.isAccent : baStep.isAccent,
        isSlide: instrument == 2 ? !baStep.isSlide : baStep.isSlide,
      );
      widget.onDataChanged(widget.data.setStep(actualStep, newBaStep));
    }
  }

  void _handleStepScroll(int instrument, int step, double delta) {
    // Convert display step to actual step based on current page
    final actualStep = _isPage2 ? step + 16 : step;

    if (instrument != 0) return; // Only BA instrument supports scroll

    final currentStep = widget.data.stepAt(actualStep);
    _scrollAccumulator += delta;
    int direction = 0;
    if (_scrollAccumulator.abs() >= _scrollThreshold) {
      direction = _scrollAccumulator > 0 ? 1 : -1;
      _scrollAccumulator = 0.0; // Reset after a step
    } else {
      return; // Not enough scroll yet
    }

    BassStep newStep;

    if (direction > 0) {
      // Scroll up
      if (currentStep.note == Note.off) {
        newStep = currentStep.copyWith(note: Note.start, pitch: 0);
      } else if (currentStep.note == Note.start) {
        if (currentStep.pitch >= 84) {
          newStep = currentStep.copyWith(note: Note.tie, pitch: 84);
        } else {
          newStep = currentStep.copyWith(pitch: currentStep.pitch + 1);
        }
      } else {
        // Note.tie - do nothing
        return;
      }
    } else {
      // Scroll down
      if (currentStep.note == Note.tie) {
        newStep = currentStep.copyWith(note: Note.start, pitch: 84);
      } else if (currentStep.note == Note.start) {
        if (currentStep.pitch <= 0) {
          newStep = currentStep.copyWith(note: Note.off, pitch: 0);
        } else {
          newStep = currentStep.copyWith(pitch: currentStep.pitch - 1);
        }
      } else {
        // Note.off - do nothing
        return;
      }
    }

    widget.onDataChanged(widget.data.setStep(actualStep, newStep));
  }

  void _showNoteDialog(int step, BassStep stepData) {
    showDialog(
      context: context,
      builder: (context) => NoteDialog(
        stepData: stepData,
        onSave: (updatedStep) {
          widget.onDataChanged(widget.data.setStep(step, updatedStep));
        },
      ),
    );
  }

  void _showLastStepDialog() {
    showDialog(
      context: context,
      builder: (context) => LastStepDialog(
        lastStep: widget.data.lastStep,
        onSave: (lastStep) {
          widget.onDataChanged(widget.data.copyWith(lastStep: lastStep));
        },
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => BassImportDialog(
        onImport: (data) {
          widget.onDataChanged(data);
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => BassExportDisplay(data: widget.data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main grid
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Column(
            children: List.generate(
              instrumentLabels.length,
              (instrument) => Row(
                children: [
                  // Instrument label
                  Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade400),
                        bottom: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        instrumentLabels[instrument],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  // Step cells
                  ...List.generate(16, (displayStep) {
                    final actualStep = _isPage2
                        ? displayStep + 16
                        : displayStep;

                    BassStep stepData;
                    bool isActive;

                    if (instrument == 0) {
                      // BA instrument - use its own data
                      stepData = widget.data.stepAt(actualStep);
                      isActive = actualStep < widget.data.lastStep;
                    } else {
                      // AC or SL instruments - show based on BA instrument flags
                      final baStep = widget.data.stepAt(actualStep);
                      stepData = BassStep(
                        note: instrument == 1
                            ? (baStep.isAccent ? Note.start : Note.off)
                            : (baStep.isSlide ? Note.start : Note.off),
                        pitch: 0,
                      );
                      isActive = actualStep < widget.data.lastStep;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _handleStepClick(instrument, displayStep);
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Listener(
                            onPointerSignal: (pointerSignal) {
                              if (pointerSignal is PointerScrollEvent) {
                                _handleStepScroll(
                                  instrument,
                                  displayStep,
                                  pointerSignal.scrollDelta.dy,
                                );
                              }
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _stepColor(
                                  stepData,
                                  isActive,
                                  instrument,
                                ),
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade300),
                                  left: BorderSide(color: Colors.grey.shade300),
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  right: BorderSide(
                                    color:
                                        (displayStep + 1) % 4 == 0 &&
                                            displayStep < 15
                                        ? Colors.black
                                        : Colors.grey.shade300,
                                    width:
                                        (displayStep + 1) % 4 == 0 &&
                                            displayStep < 15
                                        ? 2.0
                                        : 1.0,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  instrument == 0 ? stepData.label : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: stepData.note == Note.off
                                        ? Colors.grey.shade600
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Control row
        Row(
          children: [
            // Page toggle button
            SizedBox(
              width: 80,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPage2 = !_isPage2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPage2
                      ? Colors.blue
                      : Colors.grey.shade200,
                  foregroundColor: _isPage2 ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  _isPage2 ? '17-32' : '1-16',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Last step button
            SizedBox(
              width: 80,
              height: 30,
              child: ElevatedButton(
                onPressed: _showLastStepDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Last: ${widget.data.lastStep}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Import button
            SizedBox(
              width: 70,
              height: 30,
              child: ElevatedButton(
                onPressed: _showImportDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Import',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Export button
            SizedBox(
              width: 70,
              height: 30,
              child: ElevatedButton(
                onPressed: _showExportDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Export',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Spacer(),
            // Help text
            Text(
              'Click to edit notes. Scroll wheel changes pitch on BA instrument.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
