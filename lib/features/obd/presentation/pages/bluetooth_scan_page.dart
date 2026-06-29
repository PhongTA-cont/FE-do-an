import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/obd_data.dart';
import 'obd_dashboard_page.dart';

enum BluetoothStateX {
  initial,
  notSupported,
  permissionDenied,
  bluetoothOff,
  scanning,
  noDevice,
  hasDevice,
  error,
}

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  BluetoothStateX state = BluetoothStateX.initial;

  List<ScanResult> scanResults = [];
  StreamSubscription<List<ScanResult>>? scanSub;
  StreamSubscription<bool>? scanningSub;
  StreamSubscription<BluetoothAdapterState>? adapterSub;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        _setState(BluetoothStateX.notSupported);
        return;
      }

      final permission = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (permission.values.any((status) => status.isDenied)) {
        _setState(BluetoothStateX.permissionDenied);
        return;
      }

      await adapterSub?.cancel();
      adapterSub = FlutterBluePlus.adapterState.listen((adapterState) {
        if (adapterState == BluetoothAdapterState.on) {
          startScan();
        } else {
          _setState(BluetoothStateX.bluetoothOff);
        }
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo Bluetooth: $e');
      _setState(BluetoothStateX.error);
    }
  }

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await scanSub?.cancel();
      await scanningSub?.cancel();

      final tempResults = <ScanResult>[];
      setState(() {
        scanResults = const [];
        state = BluetoothStateX.scanning;
      });

      scanSub = FlutterBluePlus.scanResults.listen((results) {
        tempResults
          ..clear()
          ..addAll(results);
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 7));
      await FlutterBluePlus.isScanning.firstWhere((isScanning) => !isScanning);

      if (!mounted) return;
      setState(() {
        scanResults = tempResults;
        state = tempResults.isEmpty
            ? BluetoothStateX.noDevice
            : BluetoothStateX.hasDevice;
      });
    } catch (e) {
      debugPrint('Lỗi quét Bluetooth: $e');
      _setState(BluetoothStateX.error);
    }
  }

  Future<void> rescan() async {
    await startScan();
  }

  void _setState(BluetoothStateX nextState) {
    if (!mounted) return;
    setState(() => state = nextState);
  }

  @override
  void dispose() {
    scanSub?.cancel();
    scanningSub?.cancel();
    adapterSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _ScanHeader(onRescan: rescan, state: state),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (state) {
      case BluetoothStateX.initial:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.bluetooth_searching,
            title: 'Đang chuẩn bị Bluetooth',
            message: 'Ứng dụng đang kiểm tra quyền và trạng thái bộ chuyển đổi.',
            showProgress: true,
          ),
        );
      case BluetoothStateX.notSupported:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.bluetooth_disabled,
            title: 'Thiết bị không hỗ trợ Bluetooth',
            message: 'Hãy thử trên thiết bị Android/iOS có Bluetooth LE.',
          ),
        );
      case BluetoothStateX.permissionDenied:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.lock_outline,
            title: 'Thiếu quyền Bluetooth',
            message: 'Cấp quyền Bluetooth và Vị trí để quét thiết bị OBD.',
          ),
        );
      case BluetoothStateX.bluetoothOff:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.bluetooth_disabled,
            title: 'Bluetooth đang tắt',
            message: 'Bật Bluetooth rồi nhấn quét lại.',
          ),
        );
      case BluetoothStateX.scanning:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.radar,
            title: 'Đang quét thiết bị',
            message: 'Tìm bộ chuyển đổi OBD-II BLE trong khoảng 7 giây.',
            showProgress: true,
          ),
        );
      case BluetoothStateX.noDevice:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.search_off,
            title: 'Không tìm thấy thiết bị',
            message: 'Đưa bộ chuyển đổi lại gần hơn hoặc khởi động lại thiết bị OBD.',
            action: OutlinedButton.icon(
              onPressed: rescan,
              icon: const Icon(Icons.refresh),
              label: const Text('Quét lại'),
            ),
          ),
        );
      case BluetoothStateX.hasDevice:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final result = scanResults[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == scanResults.length - 1 ? 0 : 10,
                ),
                child: _DeviceTile(
                  result: result,
                  onTap: () => _connect(result.device),
                ),
              );
            },
            childCount: scanResults.length,
          ),
        );
      case BluetoothStateX.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.error_outline,
            title: 'Không thể quét thiết bị',
            message: 'Có lỗi xảy ra khi làm việc với Bluetooth.',
            action: OutlinedButton.icon(
              onPressed: rescan,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        );
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ConnectingDialog(),
      );

      await device.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(256);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('Lỗi yêu cầu MTU: $e');
        }
      }

      await discoverServices(device);
      if (mounted) Navigator.pop(context);

      final bleConnection = ObdBleConnection(
        writeChar: writeCharacteristic,
        notifyChar: notifyCharacteristic,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ObdDashboardPage(
            sendCommand: bleConnection.sendCommand,
            responseStream: bleConnection.responseStream,
            onDispose: bleConnection.dispose,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Lỗi kết nối: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    writeCharacteristic = null;
    notifyCharacteristic = null;

    final services = await device.discoverServices();
    for (final service in services) {
      for (final char in service.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();
        if (uuid.contains('fff1')) notifyCharacteristic = char;
        if (uuid.contains('fff2')) writeCharacteristic = char;
      }
    }
  }
}

class _ScanHeader extends StatelessWidget {
  const _ScanHeader({required this.onRescan, required this.state});

  final VoidCallback onRescan;
  final BluetoothStateX state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isScanning = state == BluetoothStateX.scanning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, const Color(0xFF0F172A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quét OBD-II',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Chọn bộ chuyển đổi BLE để bắt đầu đọc dữ liệu xe',
                      style: TextStyle(color: Color(0xFFDCEAFE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isScanning ? null : onRescan,
            icon: Icon(isScanning ? Icons.radar : Icons.refresh),
            label: Text(isScanning ? 'Đang quét...' : 'Quét thiết bị'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primary,
              disabledBackgroundColor: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.result, required this.onTap});

  final ScanResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final device = result.device;
    final name = device.name.isNotEmpty ? device.name : 'Thiết bị không tên';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bluetooth_connected, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.remoteId.str,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.rssi} dBm',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (showProgress) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(),
              ],
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectingDialog extends StatelessWidget {
  const _ConnectingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: const Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang kết nối...'),
          ],
        ),
      ),
    );
  }
}
