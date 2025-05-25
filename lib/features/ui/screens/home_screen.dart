import 'dart:io'; // Import dart:io for File operations
import 'dart:math'; // Import dart:math for pow
import 'dart:typed_data'; // Import for Float32List
import 'package:flutter/material.dart';
import 'package:wav/wav.dart' as wav_package; // Import the wav package
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_analyzer/features/ui/widgets/audio_visualizer.dart';
import 'package:music_practice_analyzer/features/ui/widgets/note_display.dart';
import 'package:tflite_flutter/tflite_flutter.dart'
    as tflite_flutter_helper; // Import TFLite
// import 'package:flutter_pitch_detection/flutter_pitch_detection.dart'; // Import the package - REMOVED

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
} // This closes HomeScreen

// Then follows the existing _HomeScreenState class:
class _HomeScreenState extends State<HomeScreen> {
  // Constants for post-processing
  static const double secondsPerFrame =
      0.01; // 10ms per frame (adjust if necessary)
  static const double onsetThreshold = 0.3;
  static const double frameThreshold = 0.3;
  static const int numPianoKeys = 88;
  static const int midiOffset = 21; // MIDI note for A0

  String? _selectedFilePath;
  bool _isAnalyzing = false;
  String? _detectedMusic;
  List<Map<String, dynamic>> _notes = [];

  // final PitchDetector _pitchDetector = PitchDetector(); // Initialize PitchDetector - REMOVED
  tflite_flutter_helper.Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await tflite_flutter_helper.Interpreter.fromAsset(
        'assets/ml/onsets_frames_wavinput.tflite',
      );
      // _interpreter?.allocateTensors(); // Some versions might need this explicitly
      debugPrint('TFLite model loaded successfully.');
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
      setState(() {
        _detectedMusic = "Error: TFLite model failed to load.";
      });
    }
  }

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
          // Read WAV file
          final wavFile = await wav_package.Wav.readFile(_selectedFilePath!);
          debugPrint('WAV Format: ${wavFile.format}');
          debugPrint('WAV SamplesPerSecond: ${wavFile.samplesPerSecond}');
          debugPrint('WAV Channels: ${wavFile.channels.length}');
          if (wavFile.channels.isNotEmpty) {
            debugPrint(
                'WAV Samples in first channel: ${wavFile.channels[0].length}');
          }

          // Placeholder for TFLite input
          Float32List? tfliteInput;
          List<double> processedSamples = [];

          if (wavFile.channels.isEmpty) {
            debugPrint('WAV file has no channels.');
            _detectedMusic = "WAV file has no channels.";
            _notes = [];
          } else {
            // Convert to Float / Normalize if int16/int24/int32
            List<List<double>> floatChannels = [];
            if (wavFile.format == wav_package.WavFormat.pcm16bit) {
              debugPrint('Converting PCM 16-bit to Float32');
              for (var channel in wavFile.channels) {
                floatChannels.add(channel.map((s) => s / 32768.0).toList());
              }
            } else if (wavFile.format == wav_package.WavFormat.pcm24bit) {
              debugPrint('Converting PCM 24-bit to Float32');
              for (var channel in wavFile.channels) {
                floatChannels.add(channel.map((s) => s / 8388608.0).toList());
              }
            } else if (wavFile.format == wav_package.WavFormat.pcm32bit) {
              debugPrint('Converting PCM 32-bit to Float32');
              for (var channel in wavFile.channels) {
                floatChannels
                    .add(channel.map((s) => s / 2147483648.0).toList());
              }
            } else if (wavFile.format == wav_package.WavFormat.float32) {
              debugPrint('Already Float32 format.');
              floatChannels = wavFile.channels; // Already List<List<double>>
            } else {
              debugPrint(
                  'Unsupported WAV format for processing: ${wavFile.format}');
              _detectedMusic = "Unsupported WAV format: ${wavFile.format}";
              _notes = [];
              // Set _isAnalyzing to false and return or throw to avoid further processing
              setState(() {
                _isAnalyzing = false;
              });
              return;
            }
            debugPrint(
                'WAV Samples converted to float. Number of channels: ${floatChannels.length}');

            // Mono Conversion
            List<double> monoSamples;
            if (floatChannels.length > 1) {
              debugPrint('Converting to mono...');
              monoSamples = List<double>.filled(floatChannels[0].length, 0.0);
              for (int i = 0; i < floatChannels[0].length; i++) {
                double sum = 0;
                for (int j = 0; j < floatChannels.length; j++) {
                  sum += floatChannels[j][i];
                }
                monoSamples[i] = sum / floatChannels.length;
              }
              debugPrint(
                  'Mono conversion complete. Samples: ${monoSamples.length}');
            } else {
              monoSamples = floatChannels[0];
              debugPrint('Already mono. Samples: ${monoSamples.length}');
            }

            // Resampling to 16kHz
            const int targetRate = 16000;
            int originalRate = wavFile.samplesPerSecond;
            List<double> resampledSamples;

            if (originalRate == targetRate) {
              debugPrint('Sample rate is already $targetRate Hz.');
              resampledSamples = monoSamples;
            } else {
              debugPrint(
                  'Resampling from $originalRate Hz to $targetRate Hz...');
              double ratio = targetRate / originalRate.toDouble();
              int newLength = (monoSamples.length * ratio).floor();
              resampledSamples = List<double>.filled(newLength, 0.0);

              for (int j = 0; j < newLength; j++) {
                double originalPos = j / ratio;
                int index1 = originalPos.floor();
                int index2 = originalPos.ceil();

                if (index1 < 0) index1 = 0;
                if (index2 >= monoSamples.length)
                  index2 = monoSamples.length - 1;
                if (index1 >= monoSamples.length)
                  index1 = monoSamples.length - 1;

                double sample1 = monoSamples[index1];
                double sample2 = monoSamples[index2];
                double fraction = originalPos - index1;

                resampledSamples[j] = sample1 + (sample2 - sample1) * fraction;
              }
              debugPrint(
                  'Resampling complete. New samples: ${resampledSamples.length} at $targetRate Hz.');
            }
            processedSamples = resampledSamples;
          }

          if (processedSamples.isNotEmpty) {
            tfliteInput = Float32List.fromList(processedSamples);
            debugPrint(
                'Final tfliteInput created. Length: ${tfliteInput.length}');

            if (_interpreter == null) {
              debugPrint('Interpreter not loaded, attempting to load now...');
              await _loadModel(); // Attempt to load if not already loaded
              if (_interpreter == null) {
                debugPrint('Failed to load interpreter even after retry.');
                _detectedMusic =
                    "Error: TFLite model could not be loaded for inference.";
                _notes = [];
                setState(() {
                  _isAnalyzing = false;
                });
                return;
              }
            }

            // Prepare Input Tensor
            // Assuming the model expects input shape like [1, num_audio_samples]
            // However, tflite_flutter's run method often directly accepts a compatible list for the first input.
            // Let's ensure tfliteInput is correctly shaped if needed, or directly usable.
            // The `run` method expects a List<Object> for inputs if there's only one input tensor.
            // If the input tensor in the model is `[null]` or `[null, 1]` for scalar input,
            // or `[num_samples]` for a 1D array, tfliteInput might be directly usable.
            // If the model expects `[1, num_samples]`, we need to wrap it:
            var inputTensor = [tfliteInput]; // This creates a List<Float32List>
            debugPrint(
                'Input tensor prepared. Shape: [1, ${tfliteInput.length}]');

            // Prepare Output Tensors dynamically
            // _interpreter.allocateTensors(); // Ensure tensors are allocated. Often implicitly done by fromAsset.
            // For some versions or complex models, explicit allocation might be needed after resizing inputs.

            List<tflite_flutter_helper.Tensor> outputTensorsMeta =
                _interpreter!.getOutputTensors();
            Map<int, Object> outputs = {};
            debugPrint('Model Output Tensors Meta:');
            for (int i = 0; i < outputTensorsMeta.length; i++) {
              debugPrint(
                  '  Output tensor $i: shape=${outputTensorsMeta[i].shape}, type=${outputTensorsMeta[i].type}, name=${outputTensorsMeta[i].name}');
              // Create appropriately typed and shaped lists for outputs
              // Assuming most outputs are float32 for now. Adjust if type indicates otherwise.
              if (outputTensorsMeta[i].type ==
                  tflite_flutter_helper.TfLiteType.kTfLiteFloat16) {
                outputs[i] = List.filled(
                        outputTensorsMeta[i].shape.reduce((a, b) => a * b), 0.0)
                    .reshape(outputTensorsMeta[i].shape);
              } else if (outputTensorsMeta[i].type ==
                  tflite_flutter_helper.TfLiteType.kTfLiteFloat32) {
                outputs[i] = List.filled(
                        outputTensorsMeta[i].shape.reduce((a, b) => a * b), 0)
                    .reshape(outputTensorsMeta[i].shape);
              } else {
                // Handle other types as needed, or log an error
                debugPrint(
                    "Unhandled output tensor type: ${outputTensorsMeta[i].type} for tensor $i");
                // Fallback to a float list, might cause issues if type is incompatible
                outputs[i] = List.filled(
                        outputTensorsMeta[i].shape.reduce((a, b) => a * b), 0.0)
                    .reshape(outputTensorsMeta[i].shape);
              }
            }

            debugPrint('Running TFLite inference...');
            _interpreter!.runForMultipleInputs(
                [inputTensor], outputs); // Pass input as List<Object>
            debugPrint(
                'TFLite inference complete. Output map keys: ${outputs.keys}');
            outputs.forEach((key, value) {
              if (value is List) {
                debugPrint(
                    'Output tensor $key: First 10 elements: ${value.take(10).toList()}');
              } else {
                debugPrint('Output tensor $key: $value');
              }
            });

            _detectedMusic =
                "TFLite inference ran. Raw output obtained. Check logs for details.";
            _notes =
                []; // Clear previous notes, will be populated by post-processing
          } else {
            _detectedMusic =
                "Audio preprocessing failed or resulted in empty samples.";
            _notes = [];
          }
        } catch (e) {
          debugPrint('Error processing audio file: $e');
          setState(() {
            _detectedMusic = "Error during audio processing.";
            _notes = [];
            _isAnalyzing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error processing audio: $e. Please try a different file.')),
          );
        } finally {
          // This ensures _isAnalyzing is always set to false after processing,
          // regardless of success or caught error within the analysis try-catch.
          if (mounted) {
            // Check if the widget is still in the tree
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
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          _selectedFilePath = null;
          _detectedMusic = null;
          _notes = [];
          _isAnalyzing = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Could not process the audio file. Please try a different file or format.')),
      );
    }
  }

  String _midiToNoteName(int midiNote) {
    if (midiNote < 21 || midiNote > 108)
      return "Unknown"; // Standard 88-key piano range
    const List<String> noteNames = [
      "A",
      "A#",
      "B",
      "C",
      "C#",
      "D",
      "D#",
      "E",
      "F",
      "F#",
      "G",
      "G#"
    ];
    // A0 is MIDI 21.
    // Octave calculation: MIDI 21-23 are octave 0 (A0, A#0, B0)
    // MIDI 24-35 are octave 1 (C1 to B1)
    // etc.
    // MIDI C4 = 60.
    int octave;
    if (midiNote < 24) {
      // A0, A#0, B0
      octave = 0;
    } else {
      octave = ((midiNote - 24) ~/ 12) + 1;
    }
    String note = noteNames[(midiNote - 21) % 12]; // A0 is index 0 (21-21=0)
    return '$note$octave';
  }

  // Function to convert frequency to note name - can be kept or commented out if not used
  // String _frequencyToNote(double? frequency) { ... } // Keeping it for now, as it doesn't hurt
  // Function to convert frequency to note name - Not used by TFLite transcription but kept for now
  String _frequencyToNote(double? frequency) {
    if (frequency == null) return "N/A";

    const Map<String, double> noteFrequencies = {
      'A0': 27.50,
      'A#0/Bb0': 29.14,
      'B0': 30.87,
      'C1': 32.70,
      'C#1/Db1': 34.65,
      'D1': 36.71,
      'D#1/Eb1': 38.89,
      'E1': 41.20,
      'F1': 43.65,
      'F#1/Gb1': 46.25,
      'G1': 49.00,
      'G#1/Ab1': 51.91,
      'A1': 55.00,
      'A#1/Bb1': 58.27,
      'B1': 61.74,
      'C2': 65.41,
      'C#2/Db2': 69.30,
      'D2': 73.42,
      'D#2/Eb2': 77.78,
      'E2': 82.41,
      'F2': 87.31,
      'F#2/Gb2': 92.50,
      'G2': 98.00,
      'G#2/Ab2': 103.83,
      'A2': 110.00,
      'A#2/Bb2': 116.54,
      'B2': 123.47,
      'C3': 130.81,
      'C#3/Db3': 138.59,
      'D3': 146.83,
      'D#3/Eb3': 155.56,
      'E3': 164.81,
      'F3': 174.61,
      'F#3/Gb3': 185.00,
      'G3': 196.00,
      'G#3/Ab3': 207.65,
      'A3': 220.00,
      'A#3/Bb3': 233.08,
      'B3': 246.94,
      'C4': 261.63,
      'C#4/Db4': 277.18,
      'D4': 293.66,
      'D#4/Eb4': 311.13,
      'E4': 329.63,
      'F4': 349.23,
      'F#4/Gb4': 369.99,
      'G4': 392.00,
      'G#4/Ab4': 415.30,
      'A4': 440.00,
      'A#4/Bb4': 466.16,
      'B4': 493.88,
      'C5': 523.25,
      'C#5/Db5': 554.37,
      'D5': 587.33,
      'D#5/Eb5': 622.25,
      'E5': 659.25,
      'F5': 698.46,
      'F#5/Gb5': 739.99,
      'G5': 783.99,
      'G#5/Ab5': 830.61,
      'A5': 880.00,
      'A#5/Bb5': 932.33,
      'B5': 987.77,
      'C6': 1046.50,
      'C#6/Db6': 1108.73,
      'D6': 1174.66,
      'D#6/Eb6': 1244.51,
      'E6': 1318.51,
      'F6': 1396.91,
      'F#6/Gb6': 1479.98,
      'G6': 1567.98,
      'G#6/Ab6': 1661.22,
      'A6': 1760.00,
      'A#6/Bb6': 1864.66,
      'B6': 1975.53,
      'C7': 2093.00,
      'C#7/Db7': 2217.46,
      'D7': 2349.32,
      'D#7/Eb7': 2489.02,
      'E7': 2637.02,
      'F7': 2793.83,
      'F#7/Gb7': 2959.96,
      'G7': 3135.96,
      'G#7/Ab7': 3322.44,
      'A7': 3520.00,
      'A#7/Bb7': 3729.31,
      'B7': 3951.07,
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
    double threshold = closestNote == "Unknown"
        ? double.infinity
        : noteFrequencies[closestNote]! * (1.0 - 1.0 / (2 * (22 * 0.01)));
    // Corrected threshold calculation:
    // A semitone is 2^(1/12). A quarter tone is 2^(1/24).
    // We can check if the frequency is within, say, 25 cents (a quarter of a semitone) of the target frequency.
    // 1 cent = 2^(1/1200). So 25 cents = 2^(25/1200) = 2^(1/48)
    if (closestNote != "Unknown") {
      threshold = noteFrequencies[closestNote]! * (pow(2, 1 / 48) - 1);
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
            if (_notes.isNotEmpty) ...[
              // Show NoteDisplay only if there are notes
              const SizedBox(height: 16),
              const AudioVisualizer(),
              // This could be enhanced to use _notes
              const SizedBox(height: 16),
              NoteDisplay(notes: _notes),
              // Pass the _notes list
            ],
          ],
        ),
      ),
    );
  }
}
