import 'package:flutter/material.dart';

class ObdLogView extends StatelessWidget {
  const ObdLogView({super.key, required this.logs, required this.onClear});

  final List<String> logs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhật ký TX/RX',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${logs.length} dòng gần nhất',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: logs.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: logs.isEmpty
                ? const _EmptyLogState()
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final log = logs[index];
                      final color = log.contains('LỖI') || log.contains('Không phân tích')
                          ? const Color(0xFFFCA5A5)
                          : log.contains('TX:')
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF86EFAC);

                      return Text(
                        log,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLogState extends StatelessWidget {
  const _EmptyLogState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal, color: Color(0xFF64748B), size: 36),
          SizedBox(height: 10),
          Text(
            'Chưa có nhật ký',
            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Gửi yêu cầu để xem dữ liệu TX/RX tại đây.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
