import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';

import 'mqtt_service.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MqttService? mqttService;
  late String _deviceId;
  int _selectedIndex = 0;
  final Map<String, List<FlSpot>> _chartData = {};
  final List<double> _tiltSensorValues = [0.0, 0.0, 0.0, 0.0];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _deviceId = await getDeviceId();
    mqttService = MqttService(widget.notificationService, _deviceId, _chartData,
        _tiltSensorValues, _onChartDataUpdated);
    await requestNotificationPermission();
    await mqttService?.connect();
    mqttService?.listen();
    setState(() {});
  }

  void _onChartDataUpdated() {
    setState(() {});
  }

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? 'ID Android Tidak Diketahui';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ID iOS Tidak Diketahui';
    } else {
      return 'Platform Tidak Dikenal';
    }
  }

    double calculateAlfa(double sensorValue, bool isOddSensor) {
      if (isOddSensor) {
        return -7.06295934183023 + 0.0226603135592881 * sensorValue;
      } else {
        return 7.06295934183023 - 0.0226603135592881 * sensorValue;
      }
    }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: _selectedIndex == 0
              ? const Text('Pemantauan Kebocoran')
              : _selectedIndex == 1
                  ? const Text('Topik Langganan')
                  : const Text('Monitor Kemiringan'),
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Monitor Kebocoran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Topik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.device_thermostat),
              label: 'Monitor Kemiringan',
            ),
          ],
        ),
        floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2)
            ? FloatingActionButton(
                onPressed: () {
                  widget.notificationService.stopAlarm();
                },
                tooltip: 'Hentikan Notifikasi',
                child: const Icon(Icons.notifications_off),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildLeakMonitorView();
    } else if (_selectedIndex == 1) {
      return _buildSubscribedTopicsList();
    } else {
      return _buildTiltMonitoring();
    }
  }

  Widget _buildTiltMonitoring() {
    final sensorLabels = ['Sensor 1', 'Sensor 2', 'Sensor 3', 'Sensor 4'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemCount: _tiltSensorValues.length,
        itemBuilder: (context, index) {
          final sensorValue = _tiltSensorValues[index];

          return Container(
            decoration: BoxDecoration(
              color: sensorValue >= 1000 ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Center(
              child: Text(
                '${sensorLabels[index]}\nNilai: $sensorValue',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscribedTopicsList() {
    final topics = mqttService?.subscribedTopics ?? [];
    return ListView.builder(
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return ListTile(
          title: Text(topic),
          trailing: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              mqttService?.unsubscribe(topic);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildLeakMonitorView() {
  const List<Offset> leftPositions = [
    Offset(-95, -70),
    Offset(-95, -10),
    Offset(-95, 50),
    Offset(-95, 100),
    Offset(-95, 145),
    Offset(-95, 195),
  ];

  const List<Offset> rightPositions = [
    Offset(105, -70),
    Offset(105, -25),
    Offset(105, 25),
    Offset(105, 70),
    Offset(105, 115),
    Offset(105, 155),
    Offset(105, 195),
  ];

  final alfaValues = [
    calculateAlfa(_tiltSensorValues[0], true),
    calculateAlfa(_tiltSensorValues[1], false),
    calculateAlfa(_tiltSensorValues[2], true),
    calculateAlfa(_tiltSensorValues[3], false)
  ];

  List<bool> leakData = mqttService?.leakData ?? [];
  List<bool> leftLeakData = leakData.length >= 6 ? leakData.sublist(0, 6) : [];
  List<bool> rightLeakData = leakData.length > 11 ? leakData.sublist(11, 18) : [];

  return Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/bagan.png',
          width: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Text('Gambar tidak ditemukan'),
        ),
        Positioned(
          left: 0,
          top: 10,
          child: Text(
            'Kiri Atas: ${alfaValues[0].toStringAsFixed(2)}°',
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        Positioned(
          right: 0,
          top: 10,
          child: Text(
            'Kanan Atas: ${alfaValues[1].toStringAsFixed(2)}°',
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 10,
          child: Text(
            'Kiri Bawah: ${alfaValues[2].toStringAsFixed(2)}°',
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 10,
          child: Text(
            'Kanan Bawah: ${alfaValues[3].toStringAsFixed(2)}°',
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        ...List.generate(leftPositions.length, (index) {
          if (leftLeakData.isNotEmpty && leftLeakData[index] == true) {
            return _buildLeakIndicator(1, leftPositions[index]);
          }
            return const SizedBox.shrink();
          }),
        ...List.generate(rightPositions.length, (index) {
          if (rightLeakData.isNotEmpty && rightLeakData[index] == true) {
            return _buildLeakIndicator(1, rightPositions[index]);
          }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildLeakIndicator(int? leakStatus, Offset position) {
    if (leakStatus == 1) {
      return Positioned(
        left: position.dx + 130,
        top: position.dy + 150,
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.request().isGranted) {
    print("Akses Diberikan");
  } else {
    print("Akses Ditolak");
  }
}
