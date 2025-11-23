import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  Function(String topic, String payload)? onMessage;

  Future<void> connect({
    Function(String topic, String payload)? onMessage,
  }) async {
    this.onMessage = onMessage;

    client = MqttServerClient(
      'fed021a58d384c25a16ad61f8aebbecb.s1.eu.hivemq.cloud',
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    );

    client.port = 8883;
    client.secure = true;
    client.setProtocolV311();
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_${DateTime.now().millisecondsSinceEpoch}')
        .authenticateAs('kurogane', 'Worst0ne')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMess;

    try {
      await client.connect();
      print("MQTT Connected!");

      // Only subscribe to required topics
      client.subscribe("aquaponic/cam/result", MqttQos.atLeastOnce);
      client.subscribe("aquaponic/esp32/relay_pump", MqttQos.atLeastOnce);

      // LISTENER
      client.updates!.listen((messages) {
        final rec = messages[0] as MqttReceivedMessage<MqttPublishMessage>;
        final msg = rec.payload;

        final payload = MqttPublishPayload.bytesToStringAsString(
          msg.payload.message,
        );

        onMessage?.call(rec.topic, payload);
      });
    } catch (e) {
      print("MQTT ERROR: $e");
      client.disconnect();
    }
  }

  // ============================
  // PUMP CONTROL
  // ============================
  void publishPower(bool isOn) {
    publish("aquaponic/esp32/relay_pump", isOn ? "ON" : "OFF");
  }

  // ============================
  // CAMERA CAPTURE REQUEST
  // ============================
  void requestCameraCapture() {
    publish("aquaponic/cam/capture", "take");
  }

  // ============================
  // BASE PUBLISH
  // ============================
  void publish(String topic, String message) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print("MQTT not connected");
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print("PUBLISH → [$topic] $message");
  }
}
