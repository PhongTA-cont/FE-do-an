import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/obd_data.dart';
import '../../domain/obd_domain.dart';
import 'obd_dashboard_event.dart';
import 'obd_dashboard_state.dart';

class ObdDashboardBloc extends Bloc<ObdDashboardEvent, ObdDashboardState> {
  ObdDashboardBloc({
    required SendObdRequest sendObdRequest,
    required ListenObdResponses listenObdResponses,
    required RequestAllObdData requestAllObdData,
    required CanFrameParser canFrameParser,
    required ObdResponseParser obdResponseParser,
  })  : _sendObdRequest = sendObdRequest,
        _listenObdResponses = listenObdResponses,
        _requestAllObdData = requestAllObdData,
        _canFrameParser = canFrameParser,
        _obdResponseParser = obdResponseParser,
        super(ObdDashboardState.initial()) {
    on<ObdDashboardStarted>(_onStarted);
    on<ObdRequestOnePressed>(_onRequestOnePressed);
    on<ObdRequestAllPressed>(_onRequestAllPressed);
    on<ObdAutoPollingToggled>(_onAutoPollingToggled);
    on<ObdRawResponseReceived>(_onRawResponseReceived);
    on<ObdLogsCleared>(_onLogsCleared);
  }

  final SendObdRequest _sendObdRequest;
  final ListenObdResponses _listenObdResponses;
  final RequestAllObdData _requestAllObdData;
  final CanFrameParser _canFrameParser;
  final ObdResponseParser _obdResponseParser;

  StreamSubscription<String>? _rxSubscription;
  Timer? _pollingTimer;
  String _rxBuffer = '';

  Future<void> _onStarted(ObdDashboardStarted event, Emitter<ObdDashboardState> emit) async {
    emit(state.copyWith(status: ObdDashboardStatus.ready, data: _addLog(state.data, 'Bảng điều khiển đã khởi động')));
    await _rxSubscription?.cancel();
    _rxSubscription = _listenObdResponses().listen(
      (raw) => add(ObdRawResponseReceived(raw)),
      onError: (error) => add(ObdRawResponseReceived('LỖI#$error')),
    );
  }

  Future<void> _onRequestOnePressed(ObdRequestOnePressed event, Emitter<ObdDashboardState> emit) async {
    try {
      await _sendObdRequest(event.request);
      emit(state.copyWith(data: _addLog(state.data, 'TX: ${event.request}')));
    } catch (e) {
      emit(state.copyWith(status: ObdDashboardStatus.error, errorMessage: '$e', data: _addLog(state.data, 'LỖI GỬI TX: $e')));
    }
  }

  Future<void> _onRequestAllPressed(ObdRequestAllPressed event, Emitter<ObdDashboardState> emit) async {
    try {
      emit(state.copyWith(data: _addLog(state.data, 'Đã yêu cầu đọc toàn bộ dữ liệu')));
      await _requestAllObdData();
    } catch (e) {
      emit(state.copyWith(status: ObdDashboardStatus.error, errorMessage: '$e', data: _addLog(state.data, 'LỖI ĐỌC TOÀN BỘ: $e')));
    }
  }

  Future<void> _onAutoPollingToggled(ObdAutoPollingToggled event, Emitter<ObdDashboardState> emit) async {
    if (state.isPolling) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      emit(state.copyWith(status: ObdDashboardStatus.ready, isPolling: false, data: _addLog(state.data, 'Đã dừng tự động cập nhật')));
      return;
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => add(const ObdRequestAllPressed()));
    emit(state.copyWith(status: ObdDashboardStatus.polling, isPolling: true, data: _addLog(state.data, 'Đã bật tự động cập nhật')));
  }

  void _onRawResponseReceived(ObdRawResponseReceived event, Emitter<ObdDashboardState> emit) {
    final lines = _splitIncomingData(event.raw);
    var currentData = state.data;

    for (final line in lines) {
      currentData = _addLog(currentData, 'RX: $line');
      final frame = _canFrameParser.tryParse(line);
      if (frame == null) {
        currentData = _addLog(currentData, 'Không phân tích được: $line');
        continue;
      }

      final results = _obdResponseParser.parseFrame(frame);
      final updatedMetrics = Map.of(currentData.metrics);
      for (final result in results) {
        final metric = updatedMetrics[result.key];
        if (metric != null) updatedMetrics[result.key] = metric.copyWith(value: result.value);
      }
      currentData = currentData.copyWith(metrics: updatedMetrics);
    }

    emit(state.copyWith(data: currentData));
  }

  void _onLogsCleared(ObdLogsCleared event, Emitter<ObdDashboardState> emit) {
    emit(state.copyWith(data: state.data.copyWith(logs: const [])));
  }

  List<String> _splitIncomingData(String chunk) {
    _rxBuffer += chunk;
    if (_rxBuffer.contains('\n') || _rxBuffer.contains('\r')) {
      final lines = _rxBuffer.split(RegExp(r'[\r\n]+')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      _rxBuffer = '';
      return lines;
    }

    final trimmed = _rxBuffer.trim();
    if (_looksLikeCompleteFrame(trimmed)) {
      _rxBuffer = '';
      return [trimmed];
    }
    return const [];
  }

  bool _looksLikeCompleteFrame(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    if (text.contains('#')) {
      final normalized = text.replaceFirst(RegExp(r'^[tT]'), '');
      final parts = normalized.split('#');
      return parts.length == 2 && parts[0].length == 3 && parts[1].length >= 6;
    }
    final normalized = text.replaceFirst(RegExp(r'^[tT]'), '');
    return normalized.length >= 8;
  }

  ObdDashboardData _addLog(ObdDashboardData data, String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return data.copyWith(logs: ['[$timestamp] $message', ...data.logs].take(300).toList());
  }

  @override
  Future<void> close() async {
    _pollingTimer?.cancel();
    await _rxSubscription?.cancel();
    return super.close();
  }
}
