import 'dart:io'; // Import dart:io for File operations
import 'dart:math'; // Import dart:math for pow
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_analyzer/features/ui/widgets/audio_visualizer.dart';
import 'package:music_practice_analyzer/features/ui/widgets/note_display.dart';
// import 'package:flutter_pitch_detection/flutter_pitch_detection.dart'; // Import the package

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
  // final PitchDetector _pitchDetector = PitchDetector(); // Initialize PitchDetector

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

        try {
          // final fileBytes = await File(_selectedFilePath!).readAsBytes(); // Keep this if you want to read the file, but not analyze
          // final result = await _pitchDetector.getPitch(fileBytes); // Commented out pitch detection

          // if (result.isNotEmpty) {
          //   // Assuming 'result' is a list of pitches with confidence and time.
          //   // We need to map this to our _notes structure.
          //   // This is a simplified mapping. You might need to adjust it based on
          //   // the actual structure of 'result' and how you want to represent notes.
          //   _notes = result.map((pitchInfo) {
          //     // Example: Convert frequency to note name (this is a placeholder, actual conversion is complex)
          //     String noteName = _frequencyToNote(pitchInfo['pitch']); 
          //     return {
          //       "note": noteName,
          //       // Assuming 'time' is in seconds, adjust if it's milliseconds or another unit
          //       "time": pitchInfo['time'] ?? 0.0, 
          //       // Placeholder for 'correct', you might determine this based on comparison with a target melody
          //       "correct": true, 
          //     };
          //   }).toList();
          //   _detectedMusic = "Analyzed Music"; // Or derive from notes
          // } else {
          //   _detectedMusic = "No pitches detected or error in analysis.";
          //   _notes = [];
          // }

          // Placeholder after removing pitch detection
          await Future.delayed(const Duration(seconds: 1)); // Simulate some processing time
          _notes = [
            {"note": "N/A", "time": 0.0, "correct": false}
          ];
          _detectedMusic = "Audio analysis disabled";

        } catch (e) {
          debugPrint('Error during file processing (analysis disabled): $e');
          setState(() {
            _detectedMusic = "Error during file processing.";
            _notes = [];
            _isAnalyzing = false; 
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing file: $e. Please try a different file.')),
          );
        } finally {
          // This ensures _isAnalyzing is always set to false after processing,
          // regardless of success or caught error within the analysis try-catch.
          if (mounted) { // Check if the widget is still in the tree
            setState(() {
              _isAnalyzing = false;
            });
          }
        }
      } else {
        // User cancelled the picker
        if (mounted) {
          setState(() {
            _isAnalyzing = false; // Ensure this is false if user cancels picker
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking or accessing file: $e');
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _selectedFilePath = null;
          _detectedMusic = null; 
          _notes = [];
          _isAnalyzing = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not process the audio file. Please try a different file or format.')),
      );
    }
  }

  // Function to convert frequency to note name - can be kept or commented out if not used
  // String _frequencyToNote(double? frequency) { ... } // Keeping it for now, as it doesn't hurt
  // Function to convert frequency to note name
  String _frequencyToNote(double? frequency) {
    if (frequency == null) return "N/A";

    const Map<String, double> noteFrequencies = {
      'A0': 27.50, 'A#0/Bb0': 29.14, 'B0': 30.87,
      'C1': 32.70, 'C#1/Db1': 34.65, 'D1': 36.71, 'D#1/Eb1': 38.89, 'E1': 41.20, 'F1': 43.65, 'F#1/Gb1': 46.25, 'G1': 49.00, 'G#1/Ab1': 51.91, 'A1': 55.00, 'A#1/Bb1': 58.27, 'B1': 61.74,
      'C2': 65.41, 'C#2/Db2': 69.30, 'D2': 73.42, 'D#2/Eb2': 77.78, 'E2': 82.41, 'F2': 87.31, 'F#2/Gb2': 92.50, 'G2': 98.00, 'G#2/Ab2': 103.83, 'A2': 110.00, 'A#2/Bb2': 116.54, 'B2': 123.47,
      'C3': 130.81, 'C#3/Db3': 138.59, 'D3': 146.83, 'D#3/Eb3': 155.56, 'E3': 164.81, 'F3': 174.61, 'F#3/Gb3': 185.00, 'G3': 196.00, 'G#3/Ab3': 207.65, 'A3': 220.00, 'A#3/Bb3': 233.08, 'B3': 246.94,
      'C4': 261.63, 'C#4/Db4': 277.18, 'D4': 293.66, 'D#4/Eb4': 311.13, 'E4': 329.63, 'F4': 349.23, 'F#4/Gb4': 369.99, 'G4': 392.00, 'G#4/Ab4': 415.30, 'A4': 440.00, 'A#4/Bb4': 466.16, 'B4': 493.88,
      'C5': 523.25, 'C#5/Db5': 554.37, 'D5': 587.33, 'D#5/Eb5': 622.25, 'E5': 659.25, 'F5': 698.46, 'F#5/Gb5': 739.99, 'G5': 783.99, 'G#5/Ab5': 830.61, 'A5': 880.00, 'A#5/Bb5': 932.33, 'B5': 987.77,
      'C6': 1046.50, 'C#6/Db6': 1108.73, 'D6': 1174.66, 'D#6/Eb6': 1244.51, 'E6': 1318.51, 'F6': 1396.91, 'F#6/Gb6': 1479.98, 'G6': 1567.98, 'G#6/Ab6': 1661.22, 'A6': 1760.00, 'A#6/Bb6': 1864.66, 'B6': 1975.53,
      'C7': 2093.00, 'C#7/Db7': 2217.46, 'D7': 2349.32, 'D#7/Eb7': 2489.02, 'E7': 2637.02, 'F7': 2793.83, 'F#7/Gb7': 2959.96, 'G7': 3135.96, 'G#7/Ab7': 3322.44, 'A7': 3520.00, 'A#7/Bb7': 3729.31, 'B7': 3951.07,
      'C8': 4186.01
    };

    // Find the closest note
    String closestNote = "Unknown";
    double minDifference = double.infinity;

    noteFrequencies.forEach((note, freq) {
      double difference = (frequency - freq).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestNote = note;
      }
    });

    // Define a threshold for how close the frequency must be to a note
    // This threshold might need adjustment. It's set to roughly a quarter-tone.
    double threshold = closestNote == "Unknown" ? double.infinity : noteFrequencies[closestNote]! * (1.0 - 1.0 / (2 * (22 *0.01 ) ) );
    // Corrected threshold calculation:
    // A semitone is 2^(1/12). A quarter tone is 2^(1/24).
    // We can check if the frequency is within, say, 25 cents (a quarter of a semitone) of the target frequency.
    // 1 cent = 2^(1/1200). So 25 cents = 2^(25/1200) = 2^(1/48)
    if (closestNote != "Unknown") {
       threshold = noteFrequencies[closestNote]! * (pow(2, 1/48) -1) ;
    }


    if (minDifference <= threshold) {
      return closestNote;
    } else {
      return "Unknown"; // Or return frequency.toString() if preferred for out-of-tune notes
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
            // Remove the _detectedMusic card as NoteDisplay will show the notes
            // if (_detectedMusic != null) ...[ 
            //   const SizedBox(height: 24),
            //   Card(
            //     child: Padding(
            //       padding: const EdgeInsets.all(16.0),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             'Detected Music',
            //             style: Theme.of(context).textTheme.titleLarge,
            //           ),
            //           const SizedBox(height: 8),
            //           Text(
            //             _detectedMusic!,
            //             style: Theme.of(context).textTheme.bodyLarge,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ],
            if (_notes.isNotEmpty) ...[ // Show NoteDisplay only if there are notes
              const SizedBox(height: 16),
              const AudioVisualizer(), // This could be enhanced to use _notes
              const SizedBox(height: 16),
              NoteDisplay(notes: _notes), // Pass the _notes list
            ],
          ],
        ),
      ),
    );
  }
}
