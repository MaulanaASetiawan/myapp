// import 'dart:convert';
// import 'dart:ffi';

// import 'package:flutter/material.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'mqtt_service.dart';
// import 'notification_service.dart';
// // import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // await dotenv.load(fileName: "E:\\waterleak\\bagan_apps\\key.env");
//   // await Firebase.initializeApp(
//   //   options: DefaultFirebaseOptions.currentPlatform,
//   // );

//   final notificationService = NotificationService();
//   runApp(MyApp(notificationService: notificationService));
// }

// class MyApp extends StatefulWidget {
//   final NotificationService notificationService;

//   const MyApp({super.key, required this.notificationService});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   MqttService? mqttService;
//   late String _deviceId;
//   int _selectedIndex = 0;
//   final Map<String, List<FlSpot>> _chartData = {};
//   final List<double> _tiltSensorValues = [0.0, 0.0, 0.0, 0.0];
//   final Map<String, List<bool>> _leakData = {};

//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }

//   Future<void> _initializeServices() async {
//     _deviceId = await getDeviceId();
//     mqttService = MqttService(widget.notificationService, _deviceId, _chartData,
//         _tiltSensorValues, _leakData, _onChartDataUpdated);
//     await requestNotificationPermission();
//     await mqttService?.connect();
//     // await mqttService?.loadSubscribedTopics();
//     // await mqttService?.loadChartData();
//     mqttService?.listen();
//     setState(() {});
//   }

//   void _onChartDataUpdated() {
//     setState(() {});
//   }

//   Future<String> getDeviceId() async {
//     final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     if (Theme.of(context).platform == TargetPlatform.android) {
//       final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id ?? 'Unknown Android ID';
//     } else if (Theme.of(context).platform == TargetPlatform.iOS) {
//       final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ?? 'Unknown iOS ID';
//     } else {
//       return 'Unknown Platform';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: _selectedIndex == 0
//               ? const Text('Leakage Monitoring')
//               : _selectedIndex == 1
//                   ? const Text('Subscribed Topics')
//                   : const Text('Tilt Monitor'),
//         ),
//         body: _buildBody(),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.show_chart),
//               label: 'Leak Monitor',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.list),
//               label: 'Topics',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.device_thermostat),
//               label: 'Tilt Monitor',
//             ),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: () {
//             widget.notificationService.stopAlarm();
//           },
//           tooltip: 'Silence Notification',
//           child: const Icon(Icons.notifications_off),
//         ),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_selectedIndex == 0) {
//       return _buildLeakMonitorView();
//     } else if (_selectedIndex == 1) {
//       return _buildSubscribedTopicsList();
//     } else {
//       return _buildTiltMonitoring(); // New method for tilt monitoring
//     }
//   }

//   Widget _buildTiltMonitoring() {
//     final sensorLabels = ['Sensor 1', 'Sensor 2', 'Sensor 3', 'Sensor 4'];

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 20,
//           crossAxisSpacing: 20,
//         ),
//         itemCount: _tiltSensorValues.length,
//         itemBuilder: (context, index) {
//           final sensorValue = _tiltSensorValues[index];

//           return Container(
//             decoration: BoxDecoration(
//               color: sensorValue >= 1000 ? Colors.red : Colors.green,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.black, width: 2),
//             ),
//             child: Center(
//               child: Text(
//                 '${sensorLabels[index]}\nValue: $sensorValue',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSubscribedTopicsList() {
//     final topics = mqttService?.subscribedTopics ?? [];
//     return ListView.builder(
//       itemCount: topics.length,
//       itemBuilder: (context, index) {
//         final topic = topics[index];
//         return ListTile(
//           title: Text(topic),
//           trailing: IconButton(
//             icon: const Icon(Icons.remove),
//             onPressed: () {
//               mqttService?.unsubscribe(topic);
//               setState(() {});
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildLeakMonitorView() {
//     // Kiri (Left Positions) dengan jarak y lebih rapat
//     const List<Offset> leftPositions = [
//       Offset(-90, -70),
//       Offset(-90, -25),
//       Offset(-90, 30),
//       Offset(-90, 80),
//       Offset(-90, 135),
//       Offset(-90, 195),
//     ];

//     // Kanan (Right Positions) dengan jarak y lebih rapat
//     const List<Offset> rightPositions = [
//       Offset(100, -70),
//       Offset(100, -25),
//       Offset(100, 20),
//       Offset(100, 65),
//       Offset(100, 110),
//       Offset(100, 150),
//       Offset(100, 195),
//     ];

//     return Center(
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Image.asset(
//             'assets/pict.png',
//             width: 300,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) =>
//                 const Text('Image not found'),
//           ),
//           // Display indicators on the left side
//           ...List.generate(leftPositions.length, (index) {
//             if (_leakData['float_$index']?[0] == true) {
//               return _buildLeakIndicator(1, leftPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//           // Display indicators on the right side
//           ...List.generate(rightPositions.length, (index) {
//             int rightIndex = index + leftPositions.length;
//             if (_leakData['float_$rightIndex']?[0] == true) {
//               return _buildLeakIndicator(1, rightPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildLeakIndicator(int? leakStatus, Offset position) {
//     if (leakStatus == 1) {
//       return Positioned(
//         left: position.dx + 130,
//         top: position.dy + 150,
//         child: Container(
//           width: 35,
//           height: 35,
//           decoration: const BoxDecoration(
//             color: Colors.red,
//             shape: BoxShape.circle,
//           ),
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// Future<void> requestNotificationPermission() async {
//   if (await Permission.notification.request().isGranted) {
//     print("Access Granted");
//   } else {
//     print("Access Denied");
//   }
// }

// import 'dart:convert';
// import 'dart:ffi';

// import 'package:flutter/material.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'mqtt_service.dart';
// import 'notification_service.dart';
// // import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final notificationService = NotificationService();
//   runApp(MyApp(notificationService: notificationService));
// }

// class MyApp extends StatefulWidget {
//   final NotificationService notificationService;

//   const MyApp({super.key, required this.notificationService});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   MqttService? mqttService;
//   late String _deviceId;
//   int _selectedIndex = 0;
//   final Map<String, List<FlSpot>> _chartData = {};
//   final List<double> _tiltSensorValues = [0.0, 0.0, 0.0, 0.0];
//   final Map<String, List<bool>> _leakData = {};

//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }

//   Future<void> _initializeServices() async {
//     _deviceId = await getDeviceId();
//     mqttService = MqttService(widget.notificationService, _deviceId, _chartData,
//         _tiltSensorValues, _leakData, _onChartDataUpdated);
//     await requestNotificationPermission();
//     await mqttService?.connect();
//     mqttService?.listen();
//     setState(() {});
//   }

//   void _onChartDataUpdated() {
//     setState(() {});
//   }

//   Future<String> getDeviceId() async {
//     final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     if (Theme.of(context).platform == TargetPlatform.android) {
//       final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id ?? 'Unknown Android ID';
//     } else if (Theme.of(context).platform == TargetPlatform.iOS) {
//       final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ?? 'Unknown iOS ID';
//     } else {
//       return 'Unknown Platform';
//     }
//   }

//   double calculateTiltAngle(double sensorValue) {
//     return sensorValue * 6; // Mengonversi rentang 0-15 menjadi 0-90 derajat
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: _selectedIndex == 0
//               ? const Text('Leakage Monitoring')
//               : _selectedIndex == 1
//                   ? const Text('Subscribed Topics')
//                   : const Text('Tilt Monitor'),
//         ),
//         body: _buildBody(),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.show_chart),
//               label: 'Leak Monitor',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.list),
//               label: 'Topics',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.device_thermostat),
//               label: 'Tilt Monitor',
//             ),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: () {
//             widget.notificationService.stopAlarm();
//           },
//           tooltip: 'Silence Notification',
//           child: const Icon(Icons.notifications_off),
//         ),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_selectedIndex == 0) {
//       return _buildLeakMonitorView();
//     } else if (_selectedIndex == 1) {
//       return _buildSubscribedTopicsList();
//     } else {
//       return _buildTiltMonitoring(); // New method for tilt monitoring
//     }
//   }

//   Widget _buildTiltMonitoring() {
//     final sensorLabels = ['Sensor 2', 'Sensor 2', 'Sensor 3', 'Sensor 4'];

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 20,
//           crossAxisSpacing: 20,
//         ),
//         itemCount: _tiltSensorValues.length,
//         itemBuilder: (context, index) {
//           final sensorValue = _tiltSensorValues[index];

//           return Container(
//             decoration: BoxDecoration(
//               color: sensorValue >= 1000 ? Colors.red : Colors.green,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.black, width: 2),
//             ),
//             child: Center(
//               child: Text(
//                 '${sensorLabels[index]}\nValue: $sensorValue',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSubscribedTopicsList() {
//     final topics = mqttService?.subscribedTopics ?? [];
//     return ListView.builder(
//       itemCount: topics.length,
//       itemBuilder: (context, index) {
//         final topic = topics[index];
//         return ListTile(
//           title: Text(topic),
//           trailing: IconButton(
//             icon: const Icon(Icons.remove),
//             onPressed: () {
//               mqttService?.unsubscribe(topic);
//               setState(() {});
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildLeakMonitorView() {
//     const List<Offset> leftPositions = [
//       Offset(-95, -70),
//       Offset(-95, -10),
//       Offset(-95, 50),
//       Offset(-95, 100),
//       Offset(-95, 145),
//       Offset(-95, 195),
//     ];

//     const List<Offset> rightPositions = [
//       Offset(105, -70),
//       Offset(105, -25),
//       Offset(105, 25),
//       Offset(105, 70),
//       Offset(105, 115),
//       Offset(105, 155),
//       Offset(105, 195),
//     ];

//     final angles = _tiltSensorValues.map(calculateTiltAngle).toList();

//     return Center(
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Image.asset(
//             'assets/bagan.png',
//             width: 300,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) =>
//                 const Text('Image not found'),
//           ),
//           // Text kemiringan di setiap sudut
//           Positioned(
//             left: 10,
//             top: 10,
//             child: Text(
//               'Kemiringan: ${angles[0].toStringAsFixed(2)}°',
//               style: const TextStyle(
//                   color: Colors.black, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Positioned(
//             right: 10,
//             top: 10,
//             child: Text(
//               'Kemiringan: ${angles[1].toStringAsFixed(2)}°',
//               style: const TextStyle(
//                   color: Colors.black, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Positioned(
//             left: 10,
//             bottom: 10,
//             child: Text(
//               'Kemiringan: ${angles[2].toStringAsFixed(2)}°',
//               style: const TextStyle(
//                   color: Colors.black, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Positioned(
//             right: 10,
//             bottom: 10,
//             child: Text(
//               'Kemiringan: ${angles[3].toStringAsFixed(2)}°',
//               style: const TextStyle(
//                   color: Colors.black, fontWeight: FontWeight.bold),
//             ),
//           ),
//           // Display indicators on the left side
//           ...List.generate(leftPositions.length, (index) {
//             if (_leakData['float_$index']?[0] == true) {
//               return _buildLeakIndicator(1, leftPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//           // Display indicators on the right side
//           ...List.generate(rightPositions.length, (index) {
//             int rightIndex = index + leftPositions.length;
//             if (_leakData['float_$rightIndex']?[0] == true) {
//               return _buildLeakIndicator(1, rightPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildLeakIndicator(int? leakStatus, Offset position) {
//     if (leakStatus == 1) {
//       return Positioned(
//         left: position.dx + 130,
//         top: position.dy + 150,
//         child: Container(
//           width: 35,
//           height: 35,
//           decoration: const BoxDecoration(
//             color: Colors.red,
//             shape: BoxShape.circle,
//           ),
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// Future<void> requestNotificationPermission() async {
//   if (await Permission.notification.request().isGranted) {
//     print("Access Granted");
//   } else {
//     print("Access Denied");
//   }
// }

// import 'dart:convert';
// import 'dart:ffi';

// import 'package:flutter/material.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'mqtt_service.dart';
// import 'notification_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final notificationService = NotificationService();
//   runApp(MyApp(notificationService: notificationService));
// }

// class MyApp extends StatefulWidget {
//   final NotificationService notificationService;

//   const MyApp({super.key, required this.notificationService});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   MqttService? mqttService;
//   late String _deviceId;
//   int _selectedIndex = 0;
//   final Map<String, List<FlSpot>> _chartData = {};
//   final List<double> _tiltSensorValues = [0.0, 0.0, 0.0, 0.0];
//   final Map<String, List<bool>> _leakData = {};

//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }

//   Future<void> _initializeServices() async {
//     _deviceId = await getDeviceId();
//     mqttService = MqttService(widget.notificationService, _deviceId, _chartData,
//         _tiltSensorValues, _leakData, _onChartDataUpdated);
//     await requestNotificationPermission();
//     await mqttService?.connect();
//     mqttService?.listen();
//     setState(() {});
//   }

//   void _onChartDataUpdated() {
//     setState(() {});
//   }

//   Future<String> getDeviceId() async {
//     final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     if (Theme.of(context).platform == TargetPlatform.android) {
//       final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id ?? 'Unknown Android ID';
//     } else if (Theme.of(context).platform == TargetPlatform.iOS) {
//       final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ?? 'Unknown iOS ID';
//     } else {
//       return 'Unknown Platform';
//     }
//   }

//   double calculateTiltAngle(double sensorValue) {
//     return sensorValue * 6; // Mengonversi rentang 0-15 menjadi 0-90 derajat
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: _selectedIndex == 0
//               ? const Text('Pemantauan Kebocoran')
//               : _selectedIndex == 1
//                   ? const Text('Topik Langganan')
//                   : const Text('Monitor Kemiringan'),
//         ),
//         body: _buildBody(),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.show_chart),
//               label: 'Monitor Kebocoran',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.list),
//               label: 'Topik',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.device_thermostat),
//               label: 'Monitor Kemiringan',
//             ),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: () {
//             widget.notificationService.stopAlarm();
//           },
//           tooltip: 'Hentikan Notifikasi',
//           child: const Icon(Icons.notifications_off),
//         ),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_selectedIndex == 0) {
//       return _buildLeakMonitorView();
//     } else if (_selectedIndex == 1) {
//       return _buildSubscribedTopicsList();
//     } else {
//       return _buildTiltMonitoring();
//     }
//   }

//   Widget _buildTiltMonitoring() {
//     final sensorLabels = ['Sensor 1', 'Sensor 2', 'Sensor 3', 'Sensor 4'];

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 20,
//           crossAxisSpacing: 20,
//         ),
//         itemCount: _tiltSensorValues.length,
//         itemBuilder: (context, index) {
//           final sensorValue = _tiltSensorValues[index];

//           return Container(
//             decoration: BoxDecoration(
//               color: sensorValue >= 1000 ? Colors.red : Colors.green,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.black, width: 2),
//             ),
//             child: Center(
//               child: Text(
//                 '${sensorLabels[index]}\nNilai: $sensorValue',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSubscribedTopicsList() {
//     final topics = mqttService?.subscribedTopics ?? [];
//     return ListView.builder(
//       itemCount: topics.length,
//       itemBuilder: (context, index) {
//         final topic = topics[index];
//         return ListTile(
//           title: Text(topic),
//           trailing: IconButton(
//             icon: const Icon(Icons.remove),
//             onPressed: () {
//               mqttService?.unsubscribe(topic);
//               setState(() {});
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildLeakMonitorView() {
//     const List<Offset> leftPositions = [
//       Offset(-90, -70),
//       Offset(-90, -25),
//       Offset(-90, 30),
//       Offset(-90, 80),
//       Offset(-90, 135),
//       Offset(-90, 195),
//     ];

//     const List<Offset> rightPositions = [
//       Offset(100, -70),
//       Offset(100, -25),
//       Offset(100, 20),
//       Offset(100, 65),
//       Offset(100, 110),
//       Offset(100, 150),
//       Offset(100, 195),
//     ];

//     // Menghitung kemiringan rata-rata dari semua sensor
//     final averageTiltAngle = _tiltSensorValues.map(calculateTiltAngle).reduce((a, b) => a + b) / _tiltSensorValues.length;

//     return Center(
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Image.asset(
//             'assets/pict.png',
//             width: 300,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) =>
//                 const Text('Gambar tidak ditemukan'),
//           ),
//           // Teks kemiringan di tengah bawah
//           Positioned(
//             bottom: 10,
//             child: Text(
//               'Kemiringan: ${averageTiltAngle.toStringAsFixed(2)}°',
//               style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//           ),
//           // Display indicators on the left side
//           ...List.generate(leftPositions.length, (index) {
//             if (_leakData['float_$index']?[0] == true) {
//               return _buildLeakIndicator(1, leftPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//           // Display indicators on the right side
//           ...List.generate(rightPositions.length, (index) {
//             int rightIndex = index + leftPositions.length;
//             if (_leakData['float_$rightIndex']?[0] == true) {
//               return _buildLeakIndicator(1, rightPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildLeakIndicator(int? leakStatus, Offset position) {
//     if (leakStatus == 1) {
//       return Positioned(
//         left: position.dx + 130,
//         top: position.dy + 150,
//         child: Container(
//           width: 35,
//           height: 35,
//           decoration: const BoxDecoration(
//             color: Colors.red,
//             shape: BoxShape.circle,
//           ),
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// Future<void> requestNotificationPermission() async {
//   if (await Permission.notification.request().isGranted) {
//     print("Akses Diberikan");
//   } else {
//     print("Akses Ditolak");
//   }
// }

// FIX TEMPRORARY
// import 'dart:ffi';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'mqtt_service.dart';
// import 'notification_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final notificationService = NotificationService();
//   runApp(MyApp(notificationService: notificationService));
// }

// class MyApp extends StatefulWidget {
//   final NotificationService notificationService;

//   const MyApp({super.key, required this.notificationService});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   MqttService? mqttService;
//   late String _deviceId;
//   int _selectedIndex = 0;
//   final Map<String, List<FlSpot>> _chartData = {};
//   final List<double> _tiltSensorValues = [0.0, 0.0, 0.0, 0.0];
//   final Map<String, List<bool>> _leakData = {};

//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }

//   Future<void> _initializeServices() async {
//     _deviceId = await getDeviceId();
//     mqttService = MqttService(widget.notificationService, _deviceId, _chartData,
//         _tiltSensorValues, _leakData, _onChartDataUpdated);
//     await requestNotificationPermission();
//     await mqttService?.connect();
//     mqttService?.listen();
//     setState(() {});
//   }

//   void _onChartDataUpdated() {
//     setState(() {});
//   }

//   Future<String> getDeviceId() async {
//     final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     if (Theme.of(context).platform == TargetPlatform.android) {
//       final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id ?? 'ID Android Tidak Diketahui';
//     } else if (Theme.of(context).platform == TargetPlatform.iOS) {
//       final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ?? 'ID iOS Tidak Diketahui';
//     } else {
//       return 'Platform Tidak Dikenal';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: _selectedIndex == 0
//               ? const Text('Pemantauan Kebocoran')
//               : _selectedIndex == 1
//                   ? const Text('Topik Langganan')
//                   : const Text('Monitor Kemiringan'),
//         ),
//         body: _buildBody(),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.show_chart),
//               label: 'Monitor Kebocoran',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.list),
//               label: 'Topik',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.device_thermostat),
//               label: 'Monitor Kemiringan',
//             ),
//           ],
//         ),
//         floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2)
//             ? FloatingActionButton(
//                 onPressed: () {
//                   widget.notificationService.stopAlarm();
//                 },
//                 tooltip: 'Hentikan Notifikasi',
//                 child: const Icon(Icons.notifications_off),
//               )
//             : null, // Tidak ada FloatingActionButton pada halaman lain
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_selectedIndex == 0) {
//       return _buildLeakMonitorView();
//     } else if (_selectedIndex == 1) {
//       return _buildSubscribedTopicsList();
//     } else {
//       return _buildTiltMonitoring();
//     }
//   }

//   Widget _buildTiltMonitoring() {
//     final sensorLabels = ['Sensor 1', 'Sensor 2', 'Sensor 3', 'Sensor 4'];

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 20,
//           crossAxisSpacing: 20,
//         ),
//         itemCount: _tiltSensorValues.length,
//         itemBuilder: (context, index) {
//           final sensorValue = _tiltSensorValues[index];

//           return Container(
//             decoration: BoxDecoration(
//               color: sensorValue >= 1000 ? Colors.red : Colors.green,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.black, width: 2),
//             ),
//             child: Center(
//               child: Text(
//                 '${sensorLabels[index]}\nNilai: $sensorValue',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSubscribedTopicsList() {
//     final topics = mqttService?.subscribedTopics ?? [];
//     return ListView.builder(
//       itemCount: topics.length,
//       itemBuilder: (context, index) {
//         final topic = topics[index];
//         return ListTile(
//           title: Text(topic),
//           trailing: IconButton(
//             icon: const Icon(Icons.remove),
//             onPressed: () {
//               mqttService?.unsubscribe(topic);
//               setState(() {});
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildLeakMonitorView() {
//     const List<Offset> leftPositions = [
//       Offset(-95, -70),
//       Offset(-95, -10),
//       Offset(-95, 50),
//       Offset(-95, 100),
//       Offset(-95, 145),
//       Offset(-95, 195),
//     ];

//     const List<Offset> rightPositions = [
//       Offset(105, -70),
//       Offset(105, -25),
//       Offset(105, 25),
//       Offset(105, 70),
//       Offset(105, 115),
//       Offset(105, 155),
//       Offset(105, 195),
//     ];

//     final angles = _tiltSensorValues;

//     // Mengambil 6 digit pertama untuk indikator kiri dan 7 digit terakhir untuk indikator kanan
//     List<bool> leftLeakData = _leakData['digital_inputs']?.sublist(0, 6) ?? [];
//     List<bool> rightLeakData =
//         _leakData['digital_inputs']?.sublist(11, 18) ?? [];

//     print('Left Leak Data: $leftLeakData');
//     print('Right Leak Data: $rightLeakData');

//     return Center(
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Image.asset(
//             'assets/bagan.png',
//             width: 300,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) =>
//                 const Text('Gambar tidak ditemukan'),
//           ),
//           Positioned(
//             left: 0,
//             top: 10,
//             child: Text(
//               'Kemiringan: ${angles[0].toStringAsFixed(2)} mm',
//               style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12),
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 10,
//             child: Text(
//               'Kemiringan: ${angles[1].toStringAsFixed(2)} mm',
//               style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12),
//             ),
//           ),
//           Positioned(
//             left: 0,
//             bottom: 10,
//             child: Text(
//               'Kemiringan: ${angles[2].toStringAsFixed(2)} mm',
//               style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12),
//             ),
//           ),
//           Positioned(
//             right: 0,
//             bottom: 10,
//             child: Text(
//               'Kemiringan: ${angles[3].toStringAsFixed(2)} mm',
//               style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12),
//             ),
//           ),
//           ...List.generate(leftPositions.length, (index) {
//             if (leftLeakData.isNotEmpty && leftLeakData[index] == true) {
//               print('Membuat lingkaran di kiri pada posisi $index');
//               return _buildLeakIndicator(1, leftPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//           ...List.generate(rightPositions.length, (index) {
//             if (rightLeakData.isNotEmpty && rightLeakData[index] == true) {
//               print('Membuat lingkaran di kanan pada posisi $index');
//               return _buildLeakIndicator(1, rightPositions[index]);
//             }
//             return const SizedBox.shrink();
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildLeakIndicator(int? leakStatus, Offset position) {
//     if (leakStatus == 1) {
//       return Positioned(
//         left: position.dx + 130,
//         top: position.dy + 150,
//         child: Container(
//           width: 35,
//           height: 35,
//           decoration: const BoxDecoration(
//             color: Colors.red,
//             shape: BoxShape.circle,
//           ),
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// Future<void> requestNotificationPermission() async {
//   if (await Permission.notification.request().isGranted) {
//     print("Akses Diberikan");
//   } else {
//     print("Akses Ditolak");
//   }
// }



import 'dart:convert';

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
            : null, // Tidak ada FloatingActionButton pada halaman lain
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

    final angles = _tiltSensorValues;

    List<bool> leakData = mqttService?.leakData ?? [];
    List<bool> leftLeakData = leakData.length >= 6 ? leakData.sublist(0, 6) : [];
    List<bool> rightLeakData = leakData.length > 11 ? leakData.sublist(11, 18) : [];

    print('Left Leak Data: $leftLeakData');
    print('Right Leak Data: $rightLeakData');

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
              'Kemiringan: ${angles[0].toStringAsFixed(2)} mm',
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
              'Kemiringan: ${angles[1].toStringAsFixed(2)} mm',
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
              'Kemiringan: ${angles[2].toStringAsFixed(2)} mm',
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
              'Kemiringan: ${angles[3].toStringAsFixed(2)} mm',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          ...List.generate(leftPositions.length, (index) {
            if (leftLeakData.isNotEmpty && leftLeakData[index] == true) {
              print('Membuat lingkaran di kiri pada posisi $index');
              return _buildLeakIndicator(1, leftPositions[index]);
            }
            return const SizedBox.shrink();
          }),
          ...List.generate(rightPositions.length, (index) {
            if (rightLeakData.isNotEmpty && rightLeakData[index] == true) {
              print('Membuat lingkaran di kanan pada posisi $index');
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
