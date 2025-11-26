import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../api/analyzer_api.dart';   // ⬅️ WAJIB TAMBAH
import 'manual_crop_page.dart';

class PotAnalyzerScreen extends StatefulWidget {
  const PotAnalyzerScreen({super.key});

  @override
  State<PotAnalyzerScreen> createState() => _PotAnalyzerScreenState();
}

class _PotAnalyzerScreenState extends State<PotAnalyzerScreen> {
  late MqttService mqtt;
  Uint8List? imageBytes;

  int selectedPot = 0;

  final List<Map<String, dynamic>> potData = List.generate(
    6,
    (_) => {"image": null, "rect": null},
  );

  @override
  void initState() {
    super.initState();

    mqtt = MqttService();

    // ----------------------------
    // MQTT LISTENER
    // ----------------------------
    mqtt.connect(
      onMessage: (topic, payload) {
        if (topic == "aquaponic/cam/result") {
          try {
            setState(() {
              imageBytes = base64Decode(payload);
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal decode image dari kamera ❌")),
            );
          }
        }
      },
    );

    // ----------------------------
    // LOAD IMAGE DARI FLASK
    // ----------------------------
    loadImageFromServer();
  }

  // ==============================
  // FETCH IMAGE FROM FLASK
  // ==============================
  Future<void> loadImageFromServer() async {
    final img = await AnalyzerApi.fetchLatestImage();

    if (img != null) {
      setState(() {
        imageBytes = img;
      });
    }
  }

  // ==============================
  // REQUEST CAPTURE VIA MQTT
  // ==============================
  void requestCapture() {
    try {
      mqtt.publish("aquaponic/cam/capture", "take");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request capture dikirim ✔")),
      );

      // 🔥 tunggu 1 detik untuk Flask simpan gambar baru
      Future.delayed(const Duration(seconds: 1), () {
        loadImageFromServer();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("MQTT belum terhubung atau ESP belum nyala ❌"),
        ),
      );
    }
  }

  // ==============================
  // OPEN CROP PAGE
  // ==============================
  Future<void> openCropPage() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada gambar untuk dipotong ❌")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualCropPage(imageBytes: imageBytes!),
      ),
    );

    if (result != null) {
      setState(() {
        potData[selectedPot]["image"] = result["image"];
        potData[selectedPot]["rect"] = result["rect"];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pot ${selectedPot + 1} tersimpan ✔"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pot Analyzer"),
        backgroundColor: Colors.green.shade600,
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: requestCapture,
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.camera_alt),
        label: const Text("Capture"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// =============================
            /// GAMBAR UTAMA
            /// =============================
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imageBytes == null
                    ? Center(
                        child: Text(
                          "Belum ada gambar\nTekan Capture 👇",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(imageBytes!, fit: BoxFit.contain),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            /// =============================
            /// LIST 6 POT
            /// =============================
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (_, i) {
                  final pot = potData[i];
                  final rect = pot["rect"];

                  return GestureDetector(
                    onTap: () => setState(() => selectedPot = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedPot == i
                              ? Colors.green.shade700
                              : Colors.grey.shade400,
                          width: selectedPot == i ? 3 : 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade200,
                            ),
                            child: pot["image"] == null
                                ? Center(
                                    child: Text(
                                      "Pot ${i + 1}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      pot["image"],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: rect == null
                                ? Text(
                                    "Belum dicrop",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("X  : ${rect['x']}"),
                                      Text("Y  : ${rect['y']}"),
                                      Text("X₂ : ${rect['xmax']}"),
                                      Text("Y₂ : ${rect['ymax']}"),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// =============================
            /// BUTTON CROP
            /// =============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: openCropPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Crop Pot ${selectedPot + 1}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
