import 'package:flutter/material.dart';
import 'models/sequencer_models.dart';
import 'widgets/sequencer_grid.dart';

void main() {
  runApp(const SequencerApp());
}

class SequencerApp extends StatelessWidget {
  const SequencerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-8 Rhythm Pattern Editor',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SequencerPage(),
    );
  }
}

class SequencerPage extends StatefulWidget {
  const SequencerPage({super.key});

  @override
  State<SequencerPage> createState() => _SequencerPageState();
}

class _SequencerPageState extends State<SequencerPage> {
  SequencerData _sequencerData = SequencerData.empty();

  void _onDataChanged(SequencerData newData) {
    setState(() {
      _sequencerData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T-8 Rhythm Pattern Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SequencerGrid(
                    data: _sequencerData,
                    onDataChanged: _onDataChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
