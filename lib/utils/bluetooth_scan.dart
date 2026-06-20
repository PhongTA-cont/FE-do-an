import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../features/obd/presentation/pages/obd_dashboard_page.dart';

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
  StreamSubscription? scanSub;
  StreamSubscription? scanningSub;
  StreamSubscription? adapterSub;
  BluetoothDevice? connectedDevice;
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
        setState(() => state = BluetoothStateX.notSupported);
        return;
      }

      final permission = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (permission.values.any((e) => e.isDenied)) {
        setState(() => state = BluetoothStateX.permissionDenied);
        return;
      }

      adapterSub?.cancel();
      adapterSub = FlutterBluePlus.adapterState.listen((adapterState) {
        if (adapterState == BluetoothAdapterState.on) {
          startScan();
        } else {
          setState(() => state = BluetoothStateX.bluetoothOff);
        }
      });
    } catch (e) {
      setState(() => state = BluetoothStateX.error);
    }
  }

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await scanSub?.cancel();
      await scanningSub?.cancel();

      scanResults.clear();
      List<ScanResult> tempResults = [];

      setState(() => state = BluetoothStateX.scanning);

      scanSub = FlutterBluePlus.scanResults.listen((results) {
        tempResults = results;
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 7));
      await FlutterBluePlus.isScanning.firstWhere(
        (isScanning) => isScanning == false,
      );

      setState(() {
        scanResults = tempResults;
        state = tempResults.isEmpty
            ? BluetoothStateX.noDevice
            : BluetoothStateX.hasDevice;
      });
    } catch (e) {
      setState(() => state = BluetoothStateX.error);
    }
  }

  Future<void> rescan() async {
    scanResults.clear();
    await startScan();
  }

  @override
  void dispose() {
    scanSub?.cancel();
    scanningSub?.cancel();
    adapterSub?.cancel();
    super.dispose();
  }

  Widget buildBody() {
    switch (state) {
      case BluetoothStateX.initial:
        return const Center(child: CircularProgressIndicator());
      case BluetoothStateX.notSupported:
        return const Center(child: Text("Thiết bị không hỗ trợ Bluetooth"));
      case BluetoothStateX.permissionDenied:
        return const Center(child: Text("Chưa cấp quyền Bluetooth / Location"));
      case BluetoothStateX.bluetoothOff:
        return const Center(child: Text("Bluetooth đang tắt"));
      case BluetoothStateX.scanning:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Đang quét thiết bị (7s)..."),
            ],
          ),
        );
      case BluetoothStateX.noDevice:
        return const Center(child: Text("Không tìm thấy thiết bị"));
      case BluetoothStateX.hasDevice:
        return ListView.builder(
          itemCount: scanResults.length,
          itemBuilder: (context, index) {
            final result = scanResults[index];
            final device = result.device;

            return ListTile(
              title: Text(
                device.name.isNotEmpty ? device.name : "Unknown Device",
              ),
              subtitle: Text(device.remoteId.str),
              trailing: Text("RSSI: ${result.rssi}"),
              onTap: () async {
                try {
                  // Hiển thị dialog báo đang kết nối
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  await device.disconnect();
                  await Future.delayed(const Duration(milliseconds: 300));

                  await device.connect(
                    license: License.free,
                    timeout: const Duration(seconds: 10),
                    autoConnect: false,
                  );

                  if (Platform.isAndroid) {
                    try {
                      await device.requestMtu(256);
                      await Future.delayed(const Duration(milliseconds: 200));
                    } catch (e) {
                      debugPrint("Lỗi xin cấp MTU: $e");
                    }
                  }

                  await discoverServices(device);

                  // Ẩn dialog loading
                  if (mounted) Navigator.pop(context);

                  // Khởi tạo Service kết nối BLE thật
                  final realBleService = RealBleService(
                    writeChar: writeCharacteristic,
                    notifyChar: notifyCharacteristic,
                  );

                  // Chuyển thẳng sang Dashboard kèm dữ liệu thật
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ObdDashboardPage(
                          sendCommand: realBleService.sendCommand,
                          responseStream: realBleService.responseStream,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context); // Ẩn dialog nếu lỗi
                  debugPrint("❌ Connect lỗi: $e");
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
                }
              },
            );
          },
        );
      case BluetoothStateX.error:
        return const Center(child: Text("Có lỗi xảy ra khi quét"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn thiết bị OBD"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: rescan),
        ],
      ),
      body: buildBody(),
    );
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    writeCharacteristic = null;
    notifyCharacteristic = null;

    final services = await device.discoverServices();

    for (var service in services) {
      for (var char in service.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();

        if (uuid.contains("fff1")) {
          notifyCharacteristic = char;
          debugPrint("✅ RX (notify) = ${char.uuid}");
        }

        if (uuid.contains("fff2")) {
          writeCharacteristic = char;
          debugPrint("✅ TX (write) = ${char.uuid}");
        }
      }
    }
  }
}

// ==========================================
// REAL BLE SERVICE (Thay thế MockBleService)
// ==========================================
class RealBleService {
  final BluetoothCharacteristic? writeChar;
  final BluetoothCharacteristic? notifyChar;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  StreamSubscription? _notifySub;

  RealBleService({required this.writeChar, required this.notifyChar}) {
    _initNotify();
  }

  Stream<String> get responseStream => _controller.stream;

  Future<void> _initNotify() async {
    if (notifyChar == null) return;

    try {
      await notifyChar!.setNotifyValue(true);

      _notifySub = notifyChar!.onValueReceived.listen((value) {
        if (value.isEmpty) return;

        // Giải mã byte nhận được thành String theo format mà Dashboard đang mong đợi
        final text = utf8.decode(value, allowMalformed: true);
        _controller.add(text);
      });
    } catch (e) {
      debugPrint("❌ Lỗi set notify: $e");
    }
  }

  Future<void> sendCommand(String command) async {
    if (writeChar == null) return;

    try {
      final request = command.trim();
      // Đóng gói lệnh gửi đi (nối thêm \r để đẩy lệnh cho chip ELM327)
      final bytes = utf8.encode("$request\r");

      await writeChar!.write(
        bytes,
        withoutResponse: writeChar!.properties.writeWithoutResponse,
      );
    } catch (e) {
      debugPrint("❌ Lỗi gửi lệnh: $e");
    }
  }

  void dispose() {
    _notifySub?.cancel();
    _controller.close();
  }
}
