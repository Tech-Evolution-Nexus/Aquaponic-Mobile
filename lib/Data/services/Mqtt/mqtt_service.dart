import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;

class MqttService {
  late MqttServerClient client;
  Function(String topic, String payload)? onMessage;

  final String broker = 'fed021a58d384c25a16ad61f8aebbecb.s1.eu.hivemq.cloud';
  final int port = 8883;
  final String user = 'kurogane';
  final String pass = 'Worst0ne';
  final String topicSubscribe = 'aquaponic/#';
  final String topicCommand = 'aquaponic/capture';
  final String caCertPath = 'assets/cfg.pem'; // pastikan ada di assets

  Future<void> connect({Function(String topic, String payload)? onMessage}) async {
    this.onMessage = onMessage;

    client = MqttServerClient(broker, 'flutter_test_client');
    client.port = port;
    client.secure = true;
    client.setProtocolV311();
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;

    // ===== Load CA Certificate =====
    final context = SecurityContext.defaultContext;
    try {
      final cert = await rootBundle.load(caCertPath);
      context.setTrustedCertificatesBytes(cert.buffer.asUint8List());
    } catch (e) {
      print("❌ Failed to load CA cert: $e");
    }
    client.securityContext = context;

    // ===== Connect message =====
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_test_client')
        .authenticateAs(user, pass)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    // ===== Connect =====
    try {
      print("🔌 Connecting to MQTT Broker...");
      await client.connect();
      print("✅ MQTT Connected!");

      // ===== Subscribe =====
      client.subscribe(topicSubscribe, MqttQos.atMostOnce);

      // ===== Listener =====
      client.updates?.listen((messages) {
        final rec = messages[0] as MqttReceivedMessage<MqttPublishMessage>;
        final payload = MqttPublishPayload.bytesToStringAsString(rec.payload.payload.message);
        print("📥 RECEIVED → [${rec.topic}] $payload");
        onMessage?.call(rec.topic, payload);
      });

    } on NoConnectionException catch (e) {
      print("❌ NoConnectionException: $e");
      client.disconnect();
    } on SocketException catch (e) {
      print("❌ SocketException: $e");
      client.disconnect();
    } catch (e) {
      print("❌ MQTT General Error: $e");
      client.disconnect();
    }
  }

  void publishCommand() {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString("capture");
    client.publishMessage(topicCommand, MqttQos.atMostOnce, builder.payload!);
    print("📤 PUBLISH → [$topicCommand] capture");
  }
}
