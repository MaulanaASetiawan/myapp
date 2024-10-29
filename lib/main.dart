import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fl_chart/fl_chart.dart';

import 'mqtt_service.dart';
import 'notification_service.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await dotenv.load(fileName: "E:\\waterleak\\bagan_apps\\key.env");
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
  final Map<String, List<bool>> _leakData = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _deviceId = await getDeviceId();
    mqttService = MqttService(widget.notificationService, _deviceId, _chartData,
        _tiltSensorValues, _leakData, _onChartDataUpdated);
    await requestNotificationPermission();
    await mqttService?.connect();
    // await mqttService?.loadSubscribedTopics();
    // await mqttService?.loadChartData();
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
      return androidInfo.id ?? 'Unknown Android ID';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'Unknown iOS ID';
    } else {
      return 'Unknown Platform';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: _selectedIndex == 0
              ? const Text('Tilt Monitoring')
              : _selectedIndex == 1
                  ? const Text('Subscribed Topics')
                  : const Text('Float Leakage Monitor'),
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
              icon: Icon(Icons.device_thermostat),
              label: 'Tilt Monitor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Topics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Leak Monitor',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            widget.notificationService.stopAlarm();
          },
          tooltip: 'Silence Notification',
          child: const Icon(Icons.notifications_off),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildTiltMonitoring(); // New method for tilt monitoring
    } else if (_selectedIndex == 1) {
      return _buildSubscribedTopicsList();
    } else {
      return _buildLeakMonitorView();
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
                '${sensorLabels[index]}\nValue: $sensorValue',
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
    // Kiri (Left Positions) dengan jarak y lebih rapat
    const List<Offset> leftPositions = [
      Offset(-90, -70),
      Offset(-90, -25),
      Offset(-90, 30),
      Offset(-90, 80),
      Offset(-90, 135),
      Offset(-90, 195),
    ];

    // Kanan (Right Positions) dengan jarak y lebih rapat
    const List<Offset> rightPositions = [
      Offset(100, -70),
      Offset(100, -25),
      Offset(100, 20),
      Offset(100, 65),
      Offset(100, 110),
      Offset(100, 150),
      Offset(100, 195),
    ];

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/pict.png',
            width: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Text('Image not found'),
          ),
          // Display indicators on the left side
          ...List.generate(leftPositions.length, (index) {
            if (_leakData['float_$index']?[0] == true) {
              return _buildLeakIndicator(1, leftPositions[index]);
            }
            return const SizedBox.shrink();
          }),
          // Display indicators on the right side
          ...List.generate(rightPositions.length, (index) {
            int rightIndex = index + leftPositions.length;
            if (_leakData['float_$rightIndex']?[0] == true) {
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
    print("Access Granted");
  } else {
    print("Access Denied");
  }
}
