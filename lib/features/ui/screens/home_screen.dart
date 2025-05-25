import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_analyzer/features/ui/widgets/audio_visualizer.dart';
import 'package:music_practice_analyzer/features/ui/widgets/note_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFilePath;
  bool _isAnalyzing = false;
  String? _detectedMusic;
  List<Map<String, dynamic>> _notes = [];

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _isAnalyzing = true;
        });

        // TODO: Implement audio analysis
        // This will be implemented in the next steps
        await Future.delayed(const Duration(seconds: 2)); // Placeholder

        setState(() {
          _detectedMusic = "Sample Music"; // Placeholder
          _notes = [
            {"note": "C4", "time": 0.0, "correct": true},
            {"note": "E4", "time": 0.5, "correct": false},
            {"note": "G4", "time": 1.0, "correct": true},
          ];
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Practice Analyzer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.music_note,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFilePath != null
                          ? 'Selected: ${_selectedFilePath!.split('/').last}'
                          : 'No file selected',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickAudioFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                          _isAnalyzing ? 'Analyzing...' : 'Select Audio File'),
                    ),
                  ],
                ),
              ),
            ),
            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
            if (_detectedMusic != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Music',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectedMusic!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AudioVisualizer(),
              const SizedBox(height: 16),
              const NoteDisplay(),
            ],
          ],
        ),
      ),
    );
  }
}
