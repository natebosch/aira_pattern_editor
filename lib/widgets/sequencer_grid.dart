import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../models/sequencer_models.dart';
import 'probability_dialog.dart';
import 'last_step_dialog.dart';
import 'velocity_dialog.dart';
import 'import_dialog.dart';
import 'export_display.dart';
import 'shuffle_dialog.dart';

class SequencerGrid extends StatefulWidget {
  final SequencerData data;
  final Function(SequencerData) onDataChanged;

  const SequencerGrid({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<SequencerGrid> createState() => _SequencerGridState();
}

class _SequencerGridState extends State<SequencerGrid> {
  static const List<String> instrumentLabels = [
    'BD',
    'SD',
    'CL',
    'TO',
    'OH',
    'CH',
    'AC',
  ];

  // Accumulate scroll delta for coarse stepping
  double _scrollAccumulator = 0.0;
  static const double _scrollThreshold = 40.0;

  // Probability edit mode
  bool _isProbabilityMode = false;

  // Velocity edit mode
  bool _isVelocityMode = false;

  // Page mode (false = steps 1-16, true = steps 17-32)
  bool _isPage2 = false;

  Color _stepColor(StepData? step, bool isActive) {
    if (!isActive) {
      return Colors.grey.shade400; // Inactive steps are gray
    }

    if (step != null) {
      // Use velocity to determine color - 0 is light gray-blue, 10 is very dark blue
      final velocity = step.velocity;
      final normalizedVelocity = velocity / 10.0; // 0.0 to 1.0

      // Interpolate between light gray-blue (velocity 0) and very dark blue (velocity 10)
      final lightColor = Color.fromRGBO(100, 120, 140, 1.0); // Light gray-blue
      final darkColor = Color.fromRGBO(20, 40, 80, 1.0); // Very dark blue

      return Color.lerp(lightColor, darkColor, normalizedVelocity)!;
    }

    return Colors.grey.shade400; // Gray for skipped cells
  }

  double _stepFillRatio(StepData? step, bool isActive) {
    if (step == null) return 0.0;
    return step.hitProbability / 100.0;
  }

  MouseCursor _cursorForCell(int instrument, StepData? stepData) {
    // AC instrument is not interactive in velocity mode
    if (_isVelocityMode && instrument == 6) {
      return SystemMouseCursors.forbidden;
    }

    // In probability or velocity mode, only filled cells are interactive
    if (_isProbabilityMode || _isVelocityMode) {
      if (stepData == null) {
        return SystemMouseCursors.forbidden;
      } else {
        return SystemMouseCursors.click;
      }
    }

    // Normal mode - all cells are interactive
    return SystemMouseCursors.click;
  }

  void _handleStepClick(int instrument, int step) {
    // Convert display step to actual step based on current page
    final actualStep = _isPage2 ? step + 16 : step;

    // AC instrument (index 6) is not interactive in velocity mode
    if (_isVelocityMode && instrument == 6) {
      return;
    }

    if (_isProbabilityMode) {
      // In probability mode, only allow editing filled cells
      final currentStep = widget.data.stepAt(instrument, actualStep);
      if (currentStep != null) {
        _showProbabilityDialog(instrument, actualStep, currentStep);
      }
      return;
    }

    if (_isVelocityMode) {
      // In velocity mode, only allow editing filled cells
      final currentStep = widget.data.stepAt(instrument, actualStep);
      if (currentStep != null) {
        _showVelocityDialog(instrument, actualStep, currentStep);
      }
      return;
    }

    // Normal mode behavior - toggle hit/skipped
    final currentStep = widget.data.stepAt(instrument, actualStep);
    StepData? newStep;

    if (currentStep != null) {
      // If already hit, clear the step
      newStep = null;
    } else {
      // If empty, create a new hit with default velocity 7
      newStep = const StepData(velocity: 7);
    }

    widget.onDataChanged(widget.data.setStep(instrument, actualStep, newStep));
  }

  void _handleStepScroll(int instrument, int step, double delta) {
    // Convert display step to actual step based on current page
    final actualStep = _isPage2 ? step + 16 : step;

    // AC instrument (index 6) does not support repeats or velocity, but supports probability
    if (instrument == 6 && !_isProbabilityMode) {
      return;
    }

    final currentStep = widget.data.stepAt(instrument, actualStep);
    if (currentStep == null) return; // Only affect voiced steps

    _scrollAccumulator += delta;
    int direction = 0;
    if (_scrollAccumulator.abs() >= _scrollThreshold) {
      direction = _scrollAccumulator > 0 ? 1 : -1;
      _scrollAccumulator = 0.0; // Reset after a step
    } else {
      return; // Not enough scroll yet
    }

    StepData newStep;

    if (_isVelocityMode) {
      // In velocity mode, adjust velocity directly
      int newVelocity = currentStep.velocity + direction;
      if (newVelocity < 0) newVelocity = 0;
      if (newVelocity > 10) newVelocity = 10;
      newStep = currentStep.copyWith(velocity: newVelocity);
    } else if (_isProbabilityMode) {
      // In probability mode, adjust hit probability directly
      int newProbability = currentStep.hitProbability + (direction * 10);
      if (newProbability < 10) newProbability = 10;
      if (newProbability > 100) newProbability = 100;
      newStep = currentStep.copyWith(hitProbability: newProbability);
    } else {
      // In normal mode, adjust repeat type
      final repeatTypes = RepeatType.values;
      final currentIndex = repeatTypes.indexOf(currentStep.repeatType);
      int newIndex = currentIndex + direction;
      if (newIndex < 0 || newIndex >= repeatTypes.length) return;
      newStep = currentStep.copyWith(repeatType: repeatTypes[newIndex]);
    }

    widget.onDataChanged(widget.data.setStep(instrument, actualStep, newStep));
  }

  void _showProbabilityDialog(int instrument, int step, StepData stepData) {
    showDialog(
      context: context,
      builder: (context) => ProbabilityDialog(
        stepData: stepData,
        onSave: (updatedStep) {
          widget.onDataChanged(
            widget.data.setStep(instrument, step, updatedStep),
          );
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

  void _showShuffleDialog() {
    showDialog(
      context: context,
      builder: (context) => ShuffleDialog(
        shuffle: widget.data.shuffle,
        onSave: (shuffle) {
          widget.onDataChanged(widget.data.copyWith(shuffle: shuffle));
        },
      ),
    );
  }

  void _showVelocityDialog(int instrument, int step, StepData stepData) {
    showDialog(
      context: context,
      builder: (context) => VelocityDialog(
        velocity: stepData.velocity,
        onSave: (velocity) {
          final updatedStep = stepData.copyWith(velocity: velocity);
          widget.onDataChanged(
            widget.data.setStep(instrument, step, updatedStep),
          );
        },
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportDialog(
        onImport: (data) {
          widget.onDataChanged(data);
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDisplay(data: widget.data),
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
            children: List.generate(SequencerData.numInstruments, (instrument) {
              return Row(
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
                    final stepData = widget.data.stepAt(instrument, actualStep);
                    final isActive = actualStep < widget.data.lastStep;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _handleStepClick(instrument, displayStep);
                        },

                        child: MouseRegion(
                          cursor: _cursorForCell(instrument, stepData),
                          onEnter: (_) {
                            // Enable scroll wheel detection
                          },
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
                                gradient: stepData != null
                                    ? LinearGradient(
                                        colors: [
                                          _stepColor(stepData, isActive),
                                          isActive
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade300,
                                        ],
                                        stops: [
                                          _stepFillRatio(stepData, isActive),
                                          _stepFillRatio(stepData, isActive),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: stepData != null
                                    ? null
                                    : (isActive
                                          ? Colors.white
                                          : Colors.grey.shade100),
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
                                  _isVelocityMode
                                      ? (stepData != null && instrument != 6
                                            ? stepData.labelForVelocityMode
                                            : '')
                                      : (stepData?.label ?? ''),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: stepData != null
                                        ? Colors.white
                                        : Colors.grey.shade600,
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
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        // Control row (Prob and page toggle)
        Row(
          children: [
            // Prob button
            SizedBox(
              width: 60,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isProbabilityMode = !_isProbabilityMode;
                    if (_isProbabilityMode) {
                      _isVelocityMode = false; // Turn off velocity mode
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProbabilityMode
                      ? Colors.blue
                      : Colors.grey.shade200,
                  foregroundColor: _isProbabilityMode
                      ? Colors.white
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Prob',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Vel button
            SizedBox(
              width: 60,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isVelocityMode = !_isVelocityMode;
                    if (_isVelocityMode) {
                      _isProbabilityMode = false; // Turn off probability mode
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVelocityMode
                      ? Colors.blue
                      : Colors.grey.shade200,
                  foregroundColor: _isVelocityMode
                      ? Colors.white
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Vel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
            // Shuffle button
            SizedBox(
              width: 80,
              height: 30,
              child: ElevatedButton(
                onPressed: _showShuffleDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Shuf: ${widget.data.shuffle}',
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
          ],
        ),
      ],
    );
  }
}
