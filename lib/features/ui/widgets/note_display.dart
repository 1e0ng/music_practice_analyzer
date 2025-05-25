import 'package:flutter/material.dart';

class NoteDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> notes;

  const NoteDisplay({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected Notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final noteData = notes[index];
                final noteName = noteData['note'] as String? ?? 'N/A';
                final noteTime = noteData['time'] as double? ?? 0.0;
                // Placeholder for correctness, adjust as needed
                final isCorrect = (noteData['correct'] as bool? ?? true); 

                return ListTile(
                  leading: Icon(
                    isCorrect ? Icons.check_circle : Icons.error,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    noteName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    // You might want to display more info here, like confidence or actual frequency
                    isCorrect ? 'Detected' : 'Possibly Incorrect', 
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: Text(
                    '${noteTime.toStringAsFixed(2)}s', // Display time with 2 decimal places
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
