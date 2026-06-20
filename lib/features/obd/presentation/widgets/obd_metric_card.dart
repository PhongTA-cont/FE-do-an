import 'package:flutter/material.dart';

import '../../domain/entities/obd_metric.dart';

class ObdMetricCard extends StatelessWidget {
  const ObdMetricCard({super.key, required this.metric, required this.onTap, this.compact = false});

  final ObdMetric metric;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Card(
        child: ListTile(
          onTap: onTap,
          title: Text(metric.title),
          subtitle: Text(metric.value, style: const TextStyle(fontFamily: 'monospace')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (metric.unit.isNotEmpty) Text(metric.unit),
              const SizedBox(width: 8),
              const Icon(Icons.send),
            ],
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(metric.value, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (metric.unit.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(metric.unit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
