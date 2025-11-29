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
  final String topicSubscribe = 'aquaponic/#';
  final String topicCommand = 'aquaponic/capture';
  final String caCertPath = 'assets/cfg.pem'; 

  Future<void> connect({
    Function(String topic, String payload)? onMessage,
  }) async {
    this.onMessage = onMessage;

    // jika sudah terhubung, jangan ulangi
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('🔁 MQTT already connected');
      return;
    }

    client = MqttServerClient(broker, 'flutter_test_client_${DateTime.now().millisecondsSinceEpoch}');
    client!.port = port;
    client!.secure = true;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.autoReconnect = true;

    // ===== Load CA Certificate =====
    final context = SecurityContext.defaultContext;
    try {
      final cert = await rootBundle.load(caCertPath);
      context.setTrustedCertificatesBytes(cert.buffer.asUint8List());
    } catch (e) {
      print("❌ Failed to load CA cert: $e");
    }
    client!.securityContext = context;

    // ===== Connect message =====
    client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(client!.clientIdentifier)
        .authenticateAs(user, pass)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    // event callbacks
    client!.onConnected = () {
      print("✅ MQTT onConnected");
    };
    client!.onDisconnected = () {
      print("⚠️ MQTT onDisconnected");
    };
    client!.onAutoReconnect = () {
      print("🔄 MQTT auto reconnecting...");
    };

    // ===== Connect =====
    try {
      print("🔌 Connecting to MQTT Broker...");
      await client!.connect();
      print("✅ MQTT Connected!");

      // ===== Subscribe =====
      // ...existing code...
      // ===== Listener =====
      client!.updates?.listen((messages) {
        if (messages.isEmpty) return;
        for (final msg in messages) {
          try {
            // Pastikan ini pesan publish sebelum cast
            if (msg is MqttReceivedMessage<MqttPublishMessage>) {
              final rec = msg;
              final payload = MqttPublishPayload.bytesToStringAsString(
                rec.payload.payload.message,
              );
              print("📥 RECEIVED → [${rec.topic}] payloadLen=${payload.length}");
              try {
                onMessage?.call(rec.topic, payload);
              } catch (e) {
                print("❌ onMessage handler error: $e");
              }
            } else {
              // ignore non-publish message types (e.g. ack, ping)
              print("ℹ️ Ignored non-publish message: ${msg.runtimeType}");
            }
          } catch (e, st) {
            print("❌ Error processing incoming MQTT message: $e\n$st");
          }
        }
      });
// ...existing code...
    } on NoConnectionException catch (e) {
      print("❌ NoConnectionException: $e");
      await disconnect();
    } on SocketException catch (e) {
      print("❌ SocketException: $e");
      await disconnect();
    } catch (e) {
      print("❌ MQTT General Error: $e");
      await disconnect();
    }
  }

  Future<void> disconnect() async {
    try {
      if (client != null) {
        print("🔌 Disconnecting MQTT...");
        client!.disconnect();
        client = null;
      }
    } catch (e) {
      print("❌ Error while disconnecting MQTT: $e");
    }
  }

  void publishCommand() {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString("capture");
    client!.publishMessage(topicCommand, MqttQos.atMostOnce, builder.payload!);
    print("📤 PUBLISH → [$topicCommand] capture");
  }

  void setPump(bool on) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected - cannot set pump");
      return;
    }
    final payload = on ? "ON" : "OFF";
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client!.publishMessage(
      'aquaponic/esp32/relay_pump',
      MqttQos.atMostOnce,
      builder.payload!,
    );
    print("📤 Pump → $payload");
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected - cannot subscribe");
      return;
    }
    client!.subscribe(topic, qos);
  }

  void unsubscribe(String topic) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print("❌ MQTT not connected - cannot unsubscribe");
      return;
    }
    client!.unsubscribe(topic);
  }
}