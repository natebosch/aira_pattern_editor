enum Note { off, start, tie }

class BassStep {
  final Note note;
  final bool isSlide;
  final bool isAccent;
  final int pitch;

  const BassStep({
    this.note = Note.off,
    this.isSlide = false,
    this.isAccent = false,
    this.pitch = 0,
  });

  BassStep copyWith({Note? note, bool? isSlide, bool? isAccent, int? pitch}) =>
      BassStep(
        note: note ?? this.note,
        isSlide: isSlide ?? this.isSlide,
        isAccent: isAccent ?? this.isAccent,
        pitch: pitch ?? this.pitch,
      );

  String get label => switch (note) {
    Note.off => '',
    Note.start => pitchToNoteName(pitch),
    Note.tie => 'tie',
  };

  /// Convert pitch number to note name (0 = C0, 1 = C#0, 12 = C1, etc.)
  static String pitchToNoteName(int pitch) {
    if (pitch < 0 || pitch > 84) return pitch.toString();

    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final octave = pitch ~/ 12;
    final noteIndex = pitch % 12;

    return '${noteNames[noteIndex]}$octave';
  }
}

class BassSequence {
  static const int _stepCount = 32;

  final List<BassStep> grid;
  final int lastStep;
  final int shuffle;

  const BassSequence({
    required this.grid,
    this.lastStep = 16,
    this.shuffle = 0,
  });

  factory BassSequence.empty() =>
      BassSequence(grid: List.filled(_stepCount, const BassStep()));

  BassSequence copyWith({List<BassStep>? grid, int? lastStep, int? shuffle}) =>
      BassSequence(
        grid: grid ?? this.grid,
        lastStep: lastStep ?? this.lastStep,
        shuffle: shuffle ?? this.shuffle,
      );

  BassStep stepAt(int step) => grid[step];

  BassSequence setStep(int step, BassStep stepData) =>
      copyWith(grid: List<BassStep>.from(grid)..[step] = stepData);

  /// Parse sequencer data from .prm file format
  static BassSequence fromPrmFormat(String content) {
    final lines = content.split('\n').where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return BassSequence.empty();

    var lastStep = 16;
    final lengthLine = lines.firstWhere(
      (l) => l.startsWith('LENGTH'),
      orElse: () => '',
    );
    if (lengthLine.isNotEmpty) {
      final parts = lengthLine.split('=');
      if (parts.length > 1) {
        lastStep = int.tryParse(parts.last.trim()) ?? 16;
      }
    }

    final steps = List.filled(_stepCount, const BassStep());

    final stepLines = lines.where((l) => l.startsWith('STEP'));
    for (final line in stepLines) {
      final eqIndex = line.indexOf('=');
      if (eqIndex == -1) continue;

      final keyPart = line.substring(0, eqIndex).trim();
      final valuePart = line.substring(eqIndex + 1).trim();

      final stepMatch = RegExp(r'STEP\s+(\d+)').firstMatch(keyPart);
      if (stepMatch == null) continue;

      final stepIndex = int.parse(stepMatch.group(1)!) - 1;
      if (stepIndex < 0 || stepIndex >= _stepCount) continue;

      final params = <String, int>{};
      final valueParts = valuePart.split(' ');
      for (final part in valueParts) {
        final kv = part.split('=');
        if (kv.length == 2) {
          params[kv[0]] = int.tryParse(kv[1]) ?? 0;
        }
      }

      final state = params['STATE'] ?? 0;
      final noteVal = params['NOTE'] ?? 0;
      final accent = params['ACCENT'] ?? 0;
      final slide = params['SLIDE'] ?? 0;

      final note = switch (state) {
        1 => Note.start,
        2 => Note.tie,
        _ => Note.off,
      };

      steps[stepIndex] = BassStep(
        note: note,
        pitch: noteVal,
        isAccent: accent == 1,
        isSlide: slide == 1,
      );
    }

    return BassSequence(grid: steps, lastStep: lastStep);
  }

  /// Format sequencer data to .prm file format
  String toPrmFormat() {
    final buffer = StringBuffer()
      ..writeln('LENGTH\t= $lastStep')
      ..writeln('TRIPLET\t= 0');

    for (var i = 0; i < _stepCount; i++) {
      final stepData = grid[i];
      final state = switch (stepData.note) {
        Note.start => 1,
        Note.tie => 2,
        Note.off => 0,
      };

      final note = stepData.pitch;
      final accent = stepData.isAccent ? 1 : 0;
      final slide = stepData.isSlide ? 1 : 0;

      buffer.writeln(
        'STEP ${i + 1}\t= STATE=$state NOTE=$note ACCENT=$accent SLIDE=$slide',
      );
    }

    return buffer.toString();
  }
}
