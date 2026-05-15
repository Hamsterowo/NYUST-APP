import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeatherErrorDetailScreen extends StatelessWidget {
  final String errorMessage;

  const WeatherErrorDetailScreen({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細錯誤資訊'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    errorMessage,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: errorMessage));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已複製錯誤資訊')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('複製錯誤資訊'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('返回'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
