import 'package:flutter/material.dart';

import '../../domain/obd_domain.dart';

class ObdMetricCard extends StatelessWidget {
  const ObdMetricCard({
    super.key,
    required this.metric,
    required this.onTap,
    this.compact = false,
  });

  final ObdMetric metric;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactMetricCard(metric: metric, onTap: onTap);
    }
    return _HeroMetricCard(metric: metric, onTap: onTap);
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({required this.metric, required this.onTap});

  final ObdMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasValue = metric.value != '--';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MetricIcon(keyName: metric.key),
                  const Spacer(),
                  Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: hasValue
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  if (metric.unit.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _UnitPill(unit: metric.unit),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({required this.metric, required this.onTap});

  final ObdMetric metric;
  final VoidCallback onTap;

  bool get _isLongTextMetric {
    return metric.key == 'supportedPids' || metric.key == 'vin';
  }

  String get _hintText {
    if (metric.value == '--') return 'Chạm để đọc thông số này';
    return 'Chạm để cập nhật lại';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLongTextMetric) {
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MetricIcon(keyName: metric.key),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        metric.title,
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  metric.value,
                  maxLines: metric.key == 'supportedPids' ? 30 : 3,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: metric.value == '--'
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hintText,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MetricIcon(keyName: metric.key),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metric.title,
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _hintText,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (metric.unit.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _UnitPill(unit: metric.unit),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.keyName});

  final String keyName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_iconFor(keyName), color: colors.primary, size: 20),
    );
  }

  IconData _iconFor(String keyName) {
    switch (keyName) {
      case 'speed':
        return Icons.speed;
      case 'rpm':
        return Icons.settings_input_component;
      case 'coolantTemp':
      case 'intakeAirTemp':
        return Icons.thermostat;
      case 'engineLoad':
      case 'throttle':
        return Icons.local_gas_station;
      case 'maf':
      case 'intakePressure':
      case 'barometricPressure':
        return Icons.air;
      case 'vin':
        return Icons.pin;
      default:
        return Icons.analytics_outlined;
    }
  }
}

class _UnitPill extends StatelessWidget {
  const _UnitPill({required this.unit});

  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        unit,
        style: TextStyle(
          color: colors.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
