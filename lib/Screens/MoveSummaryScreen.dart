import 'package:flutter/material.dart';

class MoveSummaryScreen extends StatelessWidget {
  final String parentCode;
  final List<MoveResult> results;

  const MoveSummaryScreen({
    super.key,
    required this.parentCode,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rapor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parent Container: $parentCode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: results.map((result) {
                  return ListTile(
                    title: Text(result.code),
                    trailing: result.success
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Tooltip(
                      message: result.message,
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                    subtitle: result.success ? null : Text(result.message, style: const TextStyle(color: Colors.red)),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }
}

class MoveResult {
  final String code;
  final bool success;
  final String message;

  MoveResult({required this.code, required this.success, this.message = ''});
}
