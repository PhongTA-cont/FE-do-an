import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/obd_ble_datasource.dart';
import '../../data/parsers/can_frame_parser.dart';
import '../../data/parsers/obd_response_parser.dart';
import '../../data/repositories/obd_repository_impl.dart';
import '../../domain/usecases/listen_obd_responses.dart';
import '../../domain/usecases/request_all_obd_data.dart';
import '../../domain/usecases/send_obd_request.dart';
import '../bloc/obd_dashboard_bloc.dart';
import '../bloc/obd_dashboard_event.dart';
import '../bloc/obd_dashboard_state.dart';
import '../widgets/obd_log_view.dart';
import '../widgets/obd_metric_card.dart';
import '../widgets/obd_pid_catalog_view.dart';

class ObdDashboardPage extends StatelessWidget {
  const ObdDashboardPage({super.key, required this.sendCommand, required this.responseStream});

  final Future<void> Function(String command) sendCommand;
  final Stream<String> responseStream;

  @override
  Widget build(BuildContext context) {
    final dataSource = ObdBleDataSourceImpl(sendCommand: sendCommand, responseStream: responseStream);
    final repository = ObdRepositoryImpl(dataSource);

    return BlocProvider(
      create: (_) => ObdDashboardBloc(
        sendObdRequest: SendObdRequest(repository),
        listenObdResponses: ListenObdResponses(repository),
        requestAllObdData: RequestAllObdData(repository),
        canFrameParser: CanFrameParser(),
        obdResponseParser: ObdResponseParser(),
      )..add(const ObdDashboardStarted()),
      child: const _ObdDashboardView(),
    );
  }
}

class _ObdDashboardView extends StatelessWidget {
  const _ObdDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObdDashboardBloc, ObdDashboardState>(
      builder: (context, state) {
        final metrics = state.data.metrics;
        final mainMetrics = [metrics['speed']!, metrics['rpm']!, metrics['coolantTemp']!, metrics['engineLoad']!];
        final otherMetrics = [
          metrics['intakePressure']!,
          metrics['intakeAirTemp']!,
          metrics['maf']!,
          metrics['throttle']!,
          metrics['barometricPressure']!,
          metrics['supportedPids']!,
          metrics['vin']!,
        ];

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('OBD-II Dashboard'),
              bottom: const TabBar(tabs: [Tab(text: 'Dashboard'), Tab(text: 'PID Catalog'), Tab(text: 'Logs')]),
              actions: [
                IconButton(
                  tooltip: 'Read all',
                  onPressed: () => context.read<ObdDashboardBloc>().add(const ObdRequestAllPressed()),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: state.isPolling ? 'Stop polling' : 'Start polling',
                  onPressed: () => context.read<ObdDashboardBloc>().add(const ObdAutoPollingToggled()),
                  icon: Icon(state.isPolling ? Icons.pause_circle : Icons.play_circle),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.read<ObdDashboardBloc>().add(const ObdRequestAllPressed()),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Read all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.read<ObdDashboardBloc>().add(const ObdAutoPollingToggled()),
                            icon: Icon(state.isPolling ? Icons.stop : Icons.play_arrow),
                            label: Text(state.isPolling ? 'Stop' : 'Auto polling'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Main values', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mainMetrics.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (_, index) {
                        final metric = mainMetrics[index];
                        return ObdMetricCard(
                          metric: metric,
                          onTap: () => context.read<ObdDashboardBloc>().add(ObdRequestOnePressed(metric.request)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Other data', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...otherMetrics.map(
                      (metric) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ObdMetricCard(
                          metric: metric,
                          compact: true,
                          onTap: () => context.read<ObdDashboardBloc>().add(ObdRequestOnePressed(metric.request)),
                        ),
                      ),
                    ),
                  ],
                ),
                ObdPidCatalogView(
                  pids: state.data.pidCatalog,
                  onRequest: (request) => context.read<ObdDashboardBloc>().add(ObdRequestOnePressed(request)),
                ),
                ObdLogView(
                  logs: state.data.logs,
                  onClear: () => context.read<ObdDashboardBloc>().add(const ObdLogsCleared()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
