import 'package:flutter/material.dart';

import '../../domain/entities/obd_pid.dart';

class ObdPidCatalogView extends StatelessWidget {
  const ObdPidCatalogView({super.key, required this.pids, required this.onRequest});

  final List<ObdPid> pids;
  final ValueChanged<String> onRequest;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: pids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final pid = pids[index];
        final isImplemented = pid.status == ObdPidStatus.implemented;
        final serviceHex = pid.service.toRadixString(16).toUpperCase().padLeft(2, '0');
        final pidHex = pid.pid.toRadixString(16).toUpperCase().padLeft(2, '0');

        return Card(
          child: ListTile(
            title: Text('Service $serviceHex PID 0x$pidHex'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pid.name),
                const SizedBox(height: 4),
                Text(
                  isImplemented ? 'Implemented by simulator' : 'Declared only in pids.py',
                  style: TextStyle(color: isImplemented ? Colors.green : Colors.orange),
                ),
                if (pid.unit.isNotEmpty) Text('Unit: ${pid.unit}'),
              ],
            ),
            trailing: IconButton(
              onPressed: isImplemented ? () => onRequest(pid.request) : null,
              icon: const Icon(Icons.send),
            ),
          ),
        );
      },
    );
  }
}
