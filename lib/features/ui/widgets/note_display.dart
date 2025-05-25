import 'package:flutter/material.dart';

class NoteDisplay extends StatelessWidget {
  const NoteDisplay({super.key});

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
              itemCount: 10, // Placeholder count
              itemBuilder: (context, index) {
                final isCorrect = index % 3 != 0; // Placeholder logic
                return ListTile(
                  leading: Icon(
                    isCorrect ? Icons.check_circle : Icons.error,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    'Note ${index + 1}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    isCorrect ? 'Correct' : 'Incorrect',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: Text(
                    '${(index * 0.5).toStringAsFixed(1)}s',
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
