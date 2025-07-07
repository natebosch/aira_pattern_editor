import 'package:flutter/material.dart';
import 't8_rhythm/models/sequencer_models.dart';
import 't8_rhythm/widgets/sequencer_grid.dart';
import 't8_bass/models/sequencer_models.dart';
import 't8_bass/widgets/sequencer_grid.dart';

void main() {
  runApp(const SequencerApp());
}

class SequencerApp extends StatelessWidget {
  const SequencerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aira T-8',
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

class _SequencerPageState extends State<SequencerPage>
    with SingleTickerProviderStateMixin {
  SequencerData _rhythmData = SequencerData.empty();
  BassSequence _bassData = BassSequence.empty();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onRhythmDataChanged(SequencerData newData) {
    setState(() {
      _rhythmData = newData;
    });
  }

  void _onBassDataChanged(BassSequence newData) {
    setState(() {
      _bassData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aira T-8 Pattern Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'T-8 Rhythm'),
            Tab(text: 'T-8 Bass'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // T-8 Rhythm Tab
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: T8RhythmSequencerGrid(
                        data: _rhythmData,
                        onDataChanged: _onRhythmDataChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // T-8 Bass Tab
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: T8BassSequencerGrid(
                        data: _bassData,
                        onDataChanged: _onBassDataChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
