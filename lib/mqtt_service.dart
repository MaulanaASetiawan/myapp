// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'notification_service.dart';
// import 'package:fl_chart/fl_chart.dart';

// class MqttService {
//   final MqttServerClient client = MqttServerClient('broker.mqtt.cool', '');
//   final NotificationService notificationService;
//   final String deviceId;
//   final List<String> _subscribedTopics = ["qwe"];
//   // final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//   final Map<String, List<FlSpot>> _chartData;
//   final Map<String, List<bool>> _data;
//   final List<double> _tiltSensorValues;
//   final VoidCallback onChartDataUpdate;
//   Map<String, dynamic> _jsonData = {};

//   MqttService(this.notificationService, this.deviceId, this._chartData,
//       this._tiltSensorValues, this._data, this.onChartDataUpdate) {
//     client.port = 1883;
//     client.logging(on: true);
//     client.keepAlivePeriod = 20;
//     client.onConnected = onConnected;
//     client.onDisconnected = onDisconnected;
//     client.onSubscribed = onSubscribed;
//     client.pongCallback = pong;
//   }

//   Future<void> connect() async {
//     try {
//       final connMessage = MqttConnectMessage()
//           .withClientIdentifier('MqttClient')
//           // .authenticateAs(dotenv.env['USERNAME_ACCESS']!, dotenv.env['PASSWORD_ACCESS']!)
//           .startClean()
//           .withWillQos(MqttQos.atLeastOnce);
//       client.connectionMessage = connMessage;

//       print('Connecting to the MQTT broker...');
//       await client.connect();
//       subscribe();
//       listen();
//     } catch (e) {
//       print('Error: $e');
//       client.disconnect();
//     }
//   }

//   void onConnected() {
//     print('Connected');
//     for (var topic in _subscribedTopics) {
//       client.subscribe(topic, MqttQos.atMostOnce);
//     }
//   }

//   void onDisconnected() {
//     print('Disconnected');
//     connect();
//   }

//   void onSubscribed(String topic) {
//     print('Subscribed: $topic');
//   }

//   void pong() {
//     print('Ping response client callback invoked');
//   }

//   void subscribe() {
//     String allTopic = 'qwe';
//     // _subscribedTopics.add(allTopic);
//     client.subscribe(allTopic, MqttQos.atMostOnce);
//     _saveSubscriptionToDatabase(allTopic);
//     print("Subscribed to $allTopic");
//   }

//   void unsubscribe(String topic) {
//     String allTopic =
//         'v3/transmitter-badaklng@badak-lng/devices/badaklng-transmitter-3/up';
//     if (_subscribedTopics.contains(topic)) {
//       _subscribedTopics.remove(topic);
//       client.unsubscribe(topic);
//       _removeSubscriptionFromDatabase(topic);
//     }
//   }

//   List<String> get subscribedTopics => _subscribedTopics;

//   // Modified listen method to handle digital_inputs and notifications
//   void listen() {
//     client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
//       final MqttPublishMessage recMessage =
//           messages[0].payload as MqttPublishMessage;
//       final String message =
//           MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

//       print('Received message: $message on topic: ${messages[0].topic}');
//       final topic = messages[0].topic;
//       final DateTime currentTime = DateTime.now();

//       // Parsing JSON message
//       try {
//         final Map<String, dynamic> jsonData = jsonDecode(message);

//         if (jsonData.containsKey('uplink_message')) {
//           final uplinkMessage = jsonData['uplink_message'];

//           if (uplinkMessage.containsKey('decoded_payload')) {
//             final Map<String, dynamic> decodedPayload =
//                 uplinkMessage['decoded_payload'];

//             final sanitizedDeviceId = sanitizeDeviceId(deviceId);
//             // final dataRef = _dbRef.child('devices/$sanitizedDeviceId/data/').push();
//             // dataRef.set({
//             //   'timestamp' : currentTime.microsecondsSinceEpoch,
//             //   'payload' : decodedPayload,
//             // });

//             // Checking digital_inputs
//             if (decodedPayload.containsKey('digital_inputs')) {
//               List<dynamic> digitalInputs = decodedPayload['digital_inputs'];
//               for (int i = 0; i < digitalInputs.length; i++) {
//                 final bool inputState = digitalInputs[i];
//                 final topicWithKey = '$topic-float_$i';
//                 // _digitalInputsData[topicWithKey] = inputState;

//                 // Update chart data
//                 if (!_chartData.containsKey(topicWithKey)) {
//                   _chartData[topicWithKey] = [];
//                   _data[topicWithKey] = [];
//                 }

//                 // If the input is true, chart rises, otherwise, it stays stable at 0
//                 double chartValue = inputState ? 1.0 : 0.0;
//                 _chartData[topicWithKey]!.add(FlSpot(
//                     _chartData[topicWithKey]!.length.toDouble(), chartValue));
              
//                 _data[topicWithKey]!.add(inputState ? true : false);

//                 // Trigger notification if any float (input) is true
//                 if (inputState) {
//                   notificationService.showNotification(
//                       'Leakage Alert', 'Float ${i + 1} detected a leak!');
//                 }
//                 print('Float ${i + 1} state: $inputState');
//               }
//             }

//             // Save tilt sensor values 1 to 4 to _tiltSensorValues
//             for (int i = 1; i <= 4; i++) {
//               if (decodedPayload.containsKey('sensor_value_$i')) {
//                 double sensorValue =
//                     decodedPayload['sensor_value_$i'].toDouble();
//                 _tiltSensorValues[i - 1] = sensorValue;
//               }
//             }
//           }
//         }
//       } catch (e) {
//         print('Error parsing JSON: $e');
//       }
//     });
//   }

//   Map<String, dynamic> get jsonData => _jsonData;
//   // Future<void> loadSubscribedTopics() async {
//   //   final sanitizedDeviceId = sanitizeDeviceId(deviceId);
//   //   // final snapshot = await _dbRef.child('devices/$sanitizedDeviceId/subscriptions').get();
//   //   // if (snapshot.exists) {
//   //   //   final Map<dynamic, dynamic> topics = snapshot.value as Map<dynamic, dynamic>;
//   //   //   topics.forEach((key, value) {
//   //   //     _subscribedTopics.add(key);
//   //   //   });
//   //   // }
//   // }

//   void _saveSubscriptionToDatabase(String topic) {
//     final sanitizedDeviceId = sanitizeDeviceId(deviceId);
//     // _dbRef.child('devices/$sanitizedDeviceId/subscriptions/$topic').set(true);
//   }

//   void _removeSubscriptionFromDatabase(String topic) {
//     final sanitizedDeviceId = sanitizeDeviceId(deviceId);
//     // _dbRef.child('devices/$sanitizedDeviceId/subscriptions/$topic').remove();
//   }

//   String sanitizeDeviceId(String deviceId) {
//     return deviceId.replaceAll(RegExp(r'[.#$[\]]'), '_');
//   }

// // Future<void> loadChartData() async {
// //   final sanitizedDeviceId = sanitizeDeviceId(deviceId);
// //   // final dataSnapshot = await _dbRef.child('devices/$sanitizedDeviceId/data').get();

// //   if (dataSnapshot.exists) {
// //     final dataMap = Map<String, dynamic>.from(dataSnapshot.value as Map);

// //     dataMap.forEach((key, value) {
// //       final dataEntry = Map<String, dynamic>.from(value as Map);
// //       final decodedPayload = Map<String, dynamic>.from(dataEntry['payload'] as Map);
// //       final timestamp = dataEntry['timestamp'] as int;

// //       // Load data without timestamp restriction for testing
// //       if (decodedPayload.containsKey('digital_inputs')) {
// //         List<dynamic> digitalInputs = decodedPayload['digital_inputs'];
// //         for (int i = 0; i < digitalInputs.length; i++) {
// //           final bool inputState = digitalInputs[i];
// //           final topicWithKey = 'v3/transmitter-badaklng@badak-lng/devices/badaklng-transmitter-3/up-float_$i';

// //           if (!_chartData.containsKey(topicWithKey)) {
// //             _chartData[topicWithKey] = [];
// //           }

// //           double chartValue = inputState ? 1.0 : 0.0;
// //           _chartData[topicWithKey]!.add(FlSpot(_chartData[topicWithKey]!.length.toDouble(), chartValue));
// //         }
// //       }

// //       for(int i = 1; i <= 4; i++){
// //         if(decodedPayload.containsKey('sensor_value_$i')){
// //           double sensorValue = decodedPayload['sensor_value_$i'].toDouble();
// //           _tiltSensorValues[i - 1] = sensorValue;
// //         }
// //       }
// //     });
// //     onChartDataUpdate();
// //   }
// // }
// }



import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'notification_service.dart';
import 'package:fl_chart/fl_chart.dart';

class MqttService {
  final MqttServerClient client = MqttServerClient('broker.mqtt.cool', '');
  final NotificationService notificationService;
  final String deviceId;
  final List<String> _subscribedTopics = ["qwe"];
  final Map<String, List<FlSpot>> _chartData;
  // final Map<String, List<bool>> _data;
  final List<double> _tiltSensorValues;
  final VoidCallback onChartDataUpdate;
  Map<String, List<bool>> _leakData;

  MqttService(this.notificationService, this.deviceId, this._chartData,
      this._tiltSensorValues, this._leakData, this.onChartDataUpdate) {
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;
  }

  Future<void> connect() async {
    try {
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('MqttClient')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      print('Connecting to the MQTT broker...');
      await client.connect();
      subscribe();
      listen();
    } catch (e) {
      print('Error: $e');
      client.disconnect();
    }
  }

  void onConnected() {
    print('Connected');
    for (var topic in _subscribedTopics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void onDisconnected() {
    print('Disconnected');
    connect();
  }

  void onSubscribed(String topic) {
    print('Subscribed: $topic');
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void subscribe() {
    String allTopic = 'qwe';
    client.subscribe(allTopic, MqttQos.atMostOnce);
    print("Subscribed to $allTopic");
  }

  void listen() {
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMessage =
          messages[0].payload as MqttPublishMessage;
      final String message =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('Received message: $message on topic: ${messages[0].topic}');

      try {
        final Map<String, dynamic> jsonData = jsonDecode(message);

        if (jsonData.containsKey('uplink_message')) {
          final uplinkMessage = jsonData['uplink_message'];
          if (uplinkMessage.containsKey('decoded_payload')) {
            final Map<String, dynamic> decodedPayload =
                uplinkMessage['decoded_payload'];

            if (decodedPayload.containsKey('digital_inputs')) {
              List<dynamic> digitalInputs = decodedPayload['digital_inputs'];
              for (int i = 0; i < digitalInputs.length; i++) {
                _leakData['float_$i'] = [digitalInputs[i]];
              }
              onChartDataUpdate();
            }

            for (int i = 1; i <= 4; i++) {
              if (decodedPayload.containsKey('sensor_value_$i')) {
                double sensorValue = decodedPayload['sensor_value_$i'].toDouble();
                _tiltSensorValues[i - 1] = sensorValue;
              }
            }
          }
        }
      } catch (e) {
        print('Error parsing JSON: $e');
      }
    });
  }

  void unsubscribe(String topic) {
    if (_subscribedTopics.contains(topic)) {
      _subscribedTopics.remove(topic);
      client.unsubscribe(topic);
      print('Unsubscribed from $topic');
    }
  }

  List<String> get subscribedTopics => _subscribedTopics;

  void _saveSubscriptionToDatabase(String topic) {
    final sanitizedDeviceId = sanitizeDeviceId(deviceId);
    // Simpan topik berlangganan ke basis data di sini (komentar untuk placeholder)
    // Contoh: _dbRef.child('devices/$sanitizedDeviceId/subscriptions/$topic').set(true);
  }

  void _removeSubscriptionFromDatabase(String topic) {
    final sanitizedDeviceId = sanitizeDeviceId(deviceId);
    // Hapus topik berlangganan dari basis data (placeholder untuk menghapus dari DB)
    // Contoh: _dbRef.child('devices/$sanitizedDeviceId/subscriptions/$topic').remove();
  }

  String sanitizeDeviceId(String deviceId) {
    return deviceId.replaceAll(RegExp(r'[.#$[\]]'), '_');
  }
}
