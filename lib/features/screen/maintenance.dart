import 'package:flutter/material.dart';
import '../../Data/services/Mqtt/mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MaintenanceScreen extends StatefulWidget {
  final MqttService mqtt;
  const MaintenanceScreen({required this.mqtt});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  int? selectedDuration; 
  final List<int> durations = [5, 10, 20];

  void startMaintenance() {
    if (selectedDuration == null) return;

    // Kirim command maintenance ke MQTT
    final seconds = selectedDuration! * 60;
    final builder = MqttClientPayloadBuilder();
    builder.addString("MAINT:$seconds");
    widget.mqtt.client?.publishMessage(
      'aquaponic/esp32/relay_pump',
      MqttQos.atMostOnce,
      builder.payload!,
    );

    // Kembalikan durasi ke Dashboard
    Navigator.pop(context, seconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Maintenance"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih durasi maintenance:",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedDuration,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text("Pilih durasi"),
                    items: durations
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e,
                            child: Text("$e menit"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedDuration = val),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: startMaintenance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Mulai Maintenance"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
