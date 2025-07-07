enum Instrument {
  bd, // Bass Drum
  sd, // Snare Drum
  cl, // Clap
  to, // Tom
  oh, // Open Hi-Hat
  ch, // Closed Hi-Hat
}

enum RepeatType { none, x2, x3, x4, flam }

class StepData {
  final RepeatType repeatType;
  final int hitProbability;
  final int repeatProbability;
  final int velocity;

  const StepData({
    this.repeatType = RepeatType.none,
    this.hitProbability = 100,
    this.repeatProbability = 100,
    this.velocity = 7,
  });

  StepData copyWith({
    RepeatType? repeatType,
    int? hitProbability,
    int? repeatProbability,
    int? velocity,
  }) {
    return StepData(
      repeatType: repeatType ?? this.repeatType,
      hitProbability: hitProbability ?? this.hitProbability,
      repeatProbability: repeatProbability ?? this.repeatProbability,
      velocity: velocity ?? this.velocity,
    );
  }

  String get label {
    final baseLabel = switch (repeatType) {
      RepeatType.none => '',
      RepeatType.x2 => 'x2',
      RepeatType.x3 => 'x3',
      RepeatType.x4 => 'x4',
      RepeatType.flam => 'F',
    };

    if (repeatType == RepeatType.none) {
      return baseLabel;
    }

    return repeatProbability == 100
        ? baseLabel
        : '$baseLabel ($repeatProbability%)';
  }

  String get labelForVelocityMode {
    return velocity.toString();
  }
}

class SequencerData {
  static const int numInstruments = 7;
  static const int numSteps = 32;

  final List<List<StepData?>> grid;
  final List<bool> globalAccents;
  final int lastStep;
  final int shuffle;

  const SequencerData({
    required this.grid,
    required this.globalAccents,
    this.lastStep = 16,
    this.shuffle = 0,
  });

  factory SequencerData.empty() {
    return SequencerData(
      grid: List.generate(
        numInstruments,
        (_) => List.filled(numSteps, null),
        growable: false,
      ),
      globalAccents: List.generate(numSteps, (index) => false, growable: false),
    );
  }

  SequencerData copyWith({
    List<List<StepData?>>? grid,
    List<bool>? globalAccents,
    int? lastStep,
    int? shuffle,
  }) {
    return SequencerData(
      grid: grid ?? this.grid,
      globalAccents: globalAccents ?? this.globalAccents,
      lastStep: lastStep ?? this.lastStep,
      shuffle: shuffle ?? this.shuffle,
    );
  }

  StepData? stepAt(int instrument, int step) {
    return grid[instrument][step];
  }

  SequencerData setStep(int instrument, int step, StepData? stepData) {
    final newGrid = List<List<StepData?>>.from(grid);
    newGrid[instrument] = List<StepData?>.from(newGrid[instrument]);
    newGrid[instrument][step] = stepData;
    return copyWith(grid: newGrid);
  }

  /// Parse sequencer data from .prm file format
  static SequencerData fromPrmFormat(String content) {
    final lines = content.split('\n');
    final data = SequencerData.empty();

    // Parse header values
    int length = 16;
    int shuffle = 0;
    for (final line in lines) {
      if (line.startsWith('LENGTH\t=')) {
        length = int.tryParse(line.split('=')[1].trim()) ?? 16;
      } else if (line.startsWith('SHUFFLE\t=')) {
        final rawShuffle = int.tryParse(line.split('=')[1].trim()) ?? 0;
        shuffle = rawShuffle ~/ 10; // Divide by 10 to decode
      }
    }

    // Parse step data
    final newGrid = List<List<StepData?>>.from(data.grid);

    for (final line in lines) {
      if (line.startsWith('STEP ')) {
        final stepMatch = RegExp(r'STEP (\d+)\s*=\s*(.+)').firstMatch(line);
        if (stepMatch != null) {
          final stepIndex =
              int.parse(stepMatch.group(1)!) - 1; // Convert to 0-based
          final stepData = stepMatch.group(2)!;

          if (stepIndex < numSteps) {
            // Parse each instrument in the step
            final instruments = stepData.split(' ');
            for (final instrument in instruments) {
              final parts = instrument.split('=');
              if (parts.length == 2) {
                final instrumentCode = parts[0];
                final value = parts[1];

                // Map instrument codes to our instruments
                final instrumentIndex = _instrumentIndex(instrumentCode);

                if (instrumentIndex != null) {
                  // TODO: Decode the value string to StepData
                  // Format: XXXAA where XXX is velocity/probability and AA is accent/repeat info
                  final stepData = _decodeStepValue(value);
                  newGrid[instrumentIndex][stepIndex] = stepData;
                }
              }
            }
          }
        }
      }
    }

    return data.copyWith(grid: newGrid, lastStep: length, shuffle: shuffle);
  }

  /// Format sequencer data to .prm file format
  String toPrmFormat() {
    final buffer = StringBuffer();

    // Write header
    buffer.writeln('LENGTH\t= $lastStep');
    buffer.writeln('SCALE\t= 1');
    buffer.writeln('SHUFFLE\t= ${shuffle * 10}');
    buffer.writeln('FLAM\t= 36');

    // Write step data for all 32 steps
    for (int step = 1; step <= 32; step++) {
      final stepIndex = step - 1; // Convert to 0-based
      buffer.write('STEP $step\t= ');

      // Write each instrument in the exact order from the device
      final instruments = const [
        'AC',
        'BD',
        'SD',
        'LT',
        'HT',
        'CY',
        'CH',
        'OH',
      ];

      final stepParts = <String>[
        for (final instrumentCode in instruments)
          if (_instrumentIndex(instrumentCode) case final instrumentIndex?)
            if (grid[instrumentIndex][stepIndex] case final stepData?)
              '$instrumentCode=${_encodeStepValue(stepData)}'
            else
              '$instrumentCode=000AA'
          else
            '$instrumentCode=000AA',
      ];

      buffer.writeln(stepParts.join(' '));
    }

    return buffer.toString();
  }

  /// Decode a single step value from .prm format
  /// Format: XXXAA where XXX is velocity/probability and AA is accent/repeat info
  static StepData? _decodeStepValue(String value) {
    if (value.length != 5) {
      return null; // Invalid format, return null
    }

    // Character 1: Binary (0 = Off, 1 = On)
    final isOn = value[0] == '1';
    if (!isOn) {
      return null; // Step is off/skipped, return null
    }

    // Character 2: Velocity (0-10, A = 10, default 7)
    final velocityChar = value[1];
    final velocity = velocityChar == 'A' ? 10 : int.tryParse(velocityChar) ?? 7;

    // Character 3: Substep option type (0-4, zero-indexed)
    final repeatTypeChar = value[2];
    final repeatTypeIndex = int.tryParse(repeatTypeChar) ?? 0;
    final repeatType = switch (repeatTypeIndex) {
      0 => RepeatType.none,
      1 => RepeatType.x2,
      2 => RepeatType.x3,
      3 => RepeatType.x4,
      4 => RepeatType.flam,
      _ => RepeatType.none,
    };

    // Character 4: Probability (0-10, A = 10, default 10)
    final probabilityChar = value[3];
    final hitProbability = probabilityChar == 'A'
        ? 100
        : (int.tryParse(probabilityChar) ?? 10) * 10;

    // Character 5: Substep probability (0-10, A = 10, default 10)
    final repeatProbabilityChar = value[4];
    final repeatProbability = repeatProbabilityChar == 'A'
        ? 100
        : (int.tryParse(repeatProbabilityChar) ?? 10) * 10;

    return StepData(
      repeatType: repeatType,
      hitProbability: hitProbability,
      repeatProbability: repeatProbability,
      velocity: velocity,
    );
  }

  /// Encode a single step value to .prm format
  /// Format: XXXAA where XXX is velocity/probability and AA is accent/repeat info
  static String _encodeStepValue(StepData stepData) {
    // Character 2: Velocity (0-10, A = 10)
    final char2 = stepData.velocity == 10 ? 'A' : stepData.velocity.toString();

    // Character 3: Substep option type (0-4, zero-indexed)
    final char3 = stepData.repeatType.index.toString();

    // Character 4: Probability (0-10, A = 10)
    final hitProbValue =
        stepData.hitProbability ~/ 10; // Convert from 0-100 to 0-10
    final char4 = hitProbValue == 10 ? 'A' : hitProbValue.toString();

    // Character 5: Substep probability (0-10, A = 10)
    final repeatProbValue =
        stepData.repeatProbability ~/ 10; // Convert from 0-100 to 0-10
    final char5 = repeatProbValue == 10 ? 'A' : repeatProbValue.toString();

    return '1$char2$char3$char4$char5';
  }
}

/// The index within the sequence grid for the instrument which serializes to
/// [instrumentCode] or `null` if the instrument is ignored for the sequence.
int? _instrumentIndex(String instrumentCode) {
  return switch (instrumentCode) {
    'AC' => 6,
    'BD' => 0,
    'SD' => 1,
    'LT' => 3,
    'HT' => 2,
    'OH' => 4,
    'CH' => 5,
    _ => null,
  };
}
