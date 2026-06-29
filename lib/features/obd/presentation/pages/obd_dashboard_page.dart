import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/obd_data.dart';
import '../../domain/obd_domain.dart';
import '../bloc/obd_dashboard.dart';
import '../widgets/obd_widgets.dart';

class ObdDashboardPage extends StatefulWidget {
  const ObdDashboardPage({
    super.key,
    required this.sendCommand,
    required this.responseStream,
    this.onDispose,
  });

  final Future<void> Function(String command) sendCommand;
  final Stream<String> responseStream;
  final Future<void> Function()? onDispose;

  @override
  State<ObdDashboardPage> createState() => _ObdDashboardPageState();
}

class _ObdDashboardPageState extends State<ObdDashboardPage> {
  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = ObdBleDataSourceImpl(
      sendCommand: widget.sendCommand,
      responseStream: widget.responseStream,
    );
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
        final mainMetrics = [
          metrics['speed']!,
          metrics['rpm']!,
          metrics['coolantTemp']!,
          metrics['engineLoad']!,
        ];
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
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Bảng điều khiển OBD-II'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Nhật ký'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(
                  state: state,
                  mainMetrics: mainMetrics,
                  otherMetrics: otherMetrics,
                ),
                ObdLogView(
                  logs: state.data.logs,
                  onClear: () => context.read<ObdDashboardBloc>().add(
                        const ObdLogsCleared(),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.state,
    required this.mainMetrics,
    required this.otherMetrics,
  });

  final ObdDashboardState state;
  final List<ObdMetric> mainMetrics;
  final List<ObdMetric> otherMetrics;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ObdDashboardBloc>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final columnCount = isWide ? 4 : 2;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _StatusPanel(
              state: state,
              onReadAll: () => bloc.add(const ObdRequestAllPressed()),
              onTogglePolling: () => bloc.add(const ObdAutoPollingToggled()),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: 'Thông số chính',
              subtitle: 'Chạm vào từng thẻ để gửi lại yêu cầu PID.',
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mainMetrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.15 : 0.95,
              ),
              itemBuilder: (_, index) {
                final metric = mainMetrics[index];
                return ObdMetricCard(
                  metric: metric,
                  onTap: () => bloc.add(ObdRequestOnePressed(metric.request)),
                );
              },
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'Thông số mở rộng',
              subtitle: '${otherMetrics.length} thông số có thể đọc từ xe.',
            ),
            const SizedBox(height: 10),
            ...otherMetrics.map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ObdMetricCard(
                  metric: metric,
                  compact: true,
                  onTap: () => bloc.add(ObdRequestOnePressed(metric.request)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.state,
    required this.onReadAll,
    required this.onTogglePolling,
  });

  final ObdDashboardState state;
  final VoidCallback onReadAll;
  final VoidCallback onTogglePolling;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final readyCount = state.data.metrics.values
        .where((metric) => metric.value != '--')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF0F172A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  state.isPolling ? Icons.speed : Icons.sensors,
                  color: const Color(0xFF93C5FD),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isPolling
                          ? 'Đang tự động cập nhật'
                          : 'Sẵn sàng đọc dữ liệu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$readyCount/${state.data.metrics.length} thông số đã có dữ liệu',
                      style: const TextStyle(color: Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReadAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Đọc tất cả'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onTogglePolling,
                  icon: Icon(state.isPolling ? Icons.stop : Icons.play_arrow),
                  label: Text(state.isPolling ? 'Dừng' : 'Tự động'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }
}
