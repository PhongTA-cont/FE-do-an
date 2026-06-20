import 'package:flutter/material.dart';

class ObdLogView extends StatelessWidget {
  const ObdLogView({super.key, required this.logs, required this.onClear});

  final List<String> logs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text('TX/RX Logs', style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(onPressed: onClear, icon: const Icon(Icons.delete_outline), label: const Text('Clear')),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: logs.isEmpty
                ? const Center(child: Text('No logs yet', style: TextStyle(color: Colors.greenAccent)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (_, index) {
                      return Text(
                        logs[index],
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
