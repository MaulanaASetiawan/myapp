import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'notification_service.dart';
import 'package:fl_chart/fl_chart.dart';

class MqttService {
  // final MqttServerClient client = MqttServerClient('as1.cloud.thethings.industries', '');
  final MqttServerClient client = MqttServerClient('broker.mqtt.cool', '');
  final NotificationService notificationService;
  final String deviceId;
  final List<String> _subscribedTopics = [
    "v3/transmitter-badaklng@badak-lng/devices/badaklng-transmitter-3/up"
  ];
  final Map<String, List<FlSpot>> _chartData;
  // final Map<String, List<bool>> _data;
  final List<double> _tiltSensorValues;
  final VoidCallback onChartDataUpdate;
  final Map<String, List<bool>> _leakData;

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
          // .authenticateAs(dotenv.env['USERNAME_ACCESS']!, dotenv.env['PASSWORD_ACCESS']!)
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
    String allTopic =
        'v3/transmitter-badaklng@badak-lng/devices/badaklng-transmitter-3/up';
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
                double sensorValue =
                    decodedPayload['sensor_value_$i'].toDouble();
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
