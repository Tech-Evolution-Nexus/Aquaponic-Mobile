import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;

class MqttService {
  MqttServerClient? client;
  Function(String topic, String payload)? onMessage;

  final String broker = 'fed021a58d384c25a16ad61f8aebbecb.s1.eu.hivemq.cloud';
  final int port = 8883;
  final String user = 'kurogane';
  final String pass = 'Worst0ne';

  // 👉 Anda pakai ESP tanpa prefix → subscribe semua
  final String topicSubscribe = '#';

  final String topicCommand = 'aquaponic/capture';
  final String caCertPath = 'assets/cfg.pem';

  Future<void> connect({
    Function(String topic, String payload)? onMessage,
  }) async {
    this.onMessage = onMessage;

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('🔁 MQTT already connected');
      return;
    }

    client = MqttServerClient(
        broker, 'flutter_${DateTime.now().millisecondsSinceEpoch}');
    client!
      ..port = port
      ..secure = true
      ..setProtocolV311()
      ..keepAlivePeriod = 20
      ..autoReconnect = true;

    // Load SSL Certificate
    final context = SecurityContext.defaultContext;
    try {
      final cert = await rootBundle.load(caCertPath);
      context.setTrustedCertificatesBytes(cert.buffer.asUint8List());
    } catch (e) {
      print("❌ Failed to load CA cert: $e");
    }
    client!.securityContext = context;

    client!.connectionMessage = MqttConnectMessage()
        .authenticateAs(user, pass)
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    // ===== Event Callback =====
    client!.onConnected = () {
      print("✅ MQTT Connected");
      subscribe(topicSubscribe);
    };

    client!.onDisconnected = () => print("⚠️ MQTT Disconnected");
    client!.onAutoReconnect = () => print("🔄 MQTT Auto reconnecting...");

    // ===== CONNECT =====
    try {
      print("🔌 Connecting to MQTT Broker...");
      await client!.connect();

      client!.updates?.listen((messages) {
        if (messages.isEmpty) return;
        for (final msg in messages) {
          if (msg is MqttReceivedMessage<MqttMessage>) {
            final recMsg = msg.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                recMsg.payload.message);

            print("📥 [${msg.topic}] => $payload");

            onMessage?.call(msg.topic, payload);
          }
        }
      });
    } catch (e) {
      print("❌ MQTT Connection Error: $e");
      disconnect();
    }
  }

  // 🔌 Disconnect
  Future<void> disconnect() async {
    if (client != null) {
      print("🔌 MQTT Disconnecting...");
      client!.disconnect();
      client = null;
    }
  }

  // 📸 Send capture command to ESP
  void publishCommand() {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString("capture");
    client!.publishMessage(topicCommand, MqttQos.exactlyOnce, builder.payload!);
    print("📤 SEND CAPTURE");
  }

  // 🔧 Set Pump ON/OFF
  void setPump(bool on) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected");
      return;
    }

    final payload = on ? "ON" : "OFF";
    final builder = MqttClientPayloadBuilder()..addString(payload);
    client!.publishMessage(
      'relay_pump', // 👈 karena tanpa 'aquaponic/'
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    print("🖥 PUMP → $payload");
  }

  // ➕ Subscribe topic
  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected - cannot subscribe");
      return;
    }

    client!.subscribe(topic, qos);
    print("📡 SUBSCRIBED → $topic");
  }

  // ➖ Unsubscribe
  void unsubscribe(String topic) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected - cannot unsubscribe");
      return;
    }
    client!.unsubscribe(topic);
    print("🚫 UNSUBSCRIBED → $topic");
  }
}
