import 'dart:convert';
import 'dart:typed_data';
import 'package:aquaponic_01/Core/const/const.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../Data/services/Mqtt/mqtt_service.dart';
import '../../Data/services/api/api_sensor.dart';
import 'manual_crop_page.dart';

class PotAnalyzerScreen extends StatefulWidget {
  const PotAnalyzerScreen({super.key});

  @override
  State<PotAnalyzerScreen> createState() => _PotAnalyzerScreenState();
}

class _PotAnalyzerScreenState extends State<PotAnalyzerScreen> {
  late MqttService mqtt;
  Uint8List? imageBytes;
  String? apiImageUrl;

  int selectedPot = 0;
  bool _waitingForImage = false;

  final List<Map<String, dynamic>> potData = List.generate(
    6,
    (_) => {"image": null, "rect": null},
  );

  @override
  void initState() {
    super.initState();
    mqtt = MqttService();
    mqtt.connect(onMessage: _onMqttMessage);
    _loadApiImage();
  }

  @override
  void dispose() {
    try {
      mqtt.disconnect();
    } catch (_) {}
    super.dispose();
  }

  void _onMqttMessage(String topic, String payload) {
    final trimmed = payload.trim();

    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);

        if (decoded is Map<String, dynamic>) {
          final rawUrl = (decoded['url'] as String?)?.trim();
          if (rawUrl != null && rawUrl.isNotEmpty) {
            final fixed = rawUrl.startsWith('http')
                ? rawUrl
                : '${SensorApi.baseUrl}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';

            setState(() {
              apiImageUrl = fixed;
              imageBytes = null;
            });
            return;
          }

          final imgBase64 = (decoded['image'] as String?)?.trim();
          if (imgBase64 != null && imgBase64.length > 50) {
            final b = base64Decode(_stripBase64Prefix(imgBase64));
            setState(() {
              imageBytes = b;
              apiImageUrl = null;
              _waitingForImage = false;
            });
            return;
          }
        }
      } catch (_) {}
    }

    if (trimmed.length > 50 && _looksLikeBase64(trimmed)) {
      final b = base64Decode(_stripBase64Prefix(trimmed));
      setState(() {
        imageBytes = b;
        apiImageUrl = null;
      });
      return;
    }

    if (trimmed.startsWith('http') ||
        trimmed.contains('/uploads/') ||
        trimmed.contains('/latest-image-file')) {
      final fixed = trimmed.startsWith('http')
          ? trimmed
          : '${SensorApi.baseUrl}${trimmed.startsWith('/') ? '' : '/'}$trimmed';
      setState(() {
        apiImageUrl = fixed;
        imageBytes = null;
      });
    }
  }

  String _stripBase64Prefix(String s) {
    final idx = s.indexOf('base64,');
    return idx >= 0 ? s.substring(idx + 7) : s;
  }

  bool _looksLikeBase64(String s) {
    final cleaned = s.replaceAll(RegExp(r'\s'), '');
    return cleaned.length > 50 &&
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(cleaned);
  }

  Future<void> _loadApiImage() async {
    final url = await SensorApi.fetchSetupImageUrl();
    if (url != null && mounted) {
      setState(() {
        apiImageUrl = url;
        imageBytes = null;
      });
    }
  }

  Future<void> requestCapture() async {
    if (_waitingForImage) return;

    setState(() {
      _waitingForImage = true;
      imageBytes = null;
      apiImageUrl = null;
    });

    try {
      mqtt.publishCommand();

      final end = DateTime.now().add(const Duration(seconds: 6));
      bool received = false;

      while (DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;

        if (imageBytes != null || apiImageUrl != null) {
          received = true;
          break;
        }
      }

      if (!mounted) return;

      if (!received) {
        final bytes = await SensorApi.fetchLatestSetupImageBytes();
        if (bytes != null && bytes.isNotEmpty) {
          setState(() {
            imageBytes = bytes;
            apiImageUrl = null;
            _waitingForImage = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _waitingForImage = false);
  }

  Future<void> openCropPage() async {
    if (imageBytes == null && apiImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada gambar untuk crop")),
      );
      return;
    }

    Uint8List? bytesForCrop = imageBytes;

    if (bytesForCrop == null) {
      bytesForCrop = await SensorApi.fetchLatestSetupImageBytes();
      bytesForCrop ??= await SensorApi.fetchLatestImageBytes();
    }

    if (bytesForCrop == null || bytesForCrop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data gambar")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualCropPage(
          imageBytes: bytesForCrop!,
          potNumber: selectedPot + 1,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        potData[selectedPot]["image"] = result["image"];
        potData[selectedPot]["rect"] = result["rect"];
      });
    }
  }

  Future<void> sendAllPotsToFlask() async {
    final pots = <Map<String, dynamic>>[];

    for (int i = 0; i < potData.length; i++) {
      final rect = potData[i]["rect"];
      if (rect != null) {
        pots.add({
          "pot_number": i + 1,
          "bounding_boxes": [
            {
              "x_min": (rect["x_min"] as num).toInt(),
              "y_min": (rect["y_min"] as num).toInt(),
              "x_max": (rect["x_max"] as num).toInt(),
              "y_max": (rect["y_max"] as num).toInt(),
            },
          ],
        });
      }
    }

    if (pots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada pot yang dicrop")),
      );
      return;
    }

    final body = jsonEncode({"pots": pots});
    final url = "${SensorApi.baseUrl}/save-pots";

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil mengirim ke Flask ✔")),
        );
        resetPotData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal (${resp.statusCode})")));
      }
    } catch (_) {}
  }

  void resetPotData() {
    setState(() {
      for (int i = 0; i < potData.length; i++) {
        potData[i]["image"] = null;
        potData[i]["rect"] = null;
      }
      selectedPot = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pot Analyzer",style: TextStyle(color: Colors.white),),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            onPressed: requestCapture,
            icon: _waitingForImage
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /* ==================== IMAGE VIEWER ==================== */
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageViewer(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(child: _buildPotList()),

            /* ==================== KIRIM SEMUA POT ==================== */
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sendAllPotsToFlask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Kirim Semua Pot",
                  style: TextStyle(fontSize: 16,color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, fit: BoxFit.contain);
    }

    if (apiImageUrl != null) {
      return Image.network(
        "${apiImageUrl!}?cache=${DateTime.now().millisecondsSinceEpoch}",
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Center(child: Text("Gagal memuat gambar")),
      );
    }

    return Center(
      child: Text(
        "Belum ada gambar",
        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildPotList() {
    return ListView.builder(
      itemCount: potData.length,
      itemBuilder: (_, i) {
        final pot = potData[i];
        final rect = pot["rect"];

        return GestureDetector(
          onTap: () async {
            setState(() => selectedPot = i);
            await openCropPage();
          },
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
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(pot["image"], fit: BoxFit.cover),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("x_min : ${rect['x_min']}"),
                            Text("y_min : ${rect['y_min']}"),
                            Text("x_max : ${rect['x_max']}"),
                            Text("y_max : ${rect['y_max']}"),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ApiHelper {
  static Future<bool> headExists(
    String url, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final resp = await http.head(Uri.parse(url)).timeout(timeout);
      if (resp.statusCode == 200) {
        final ct = resp.headers['content-type'] ?? '';
        return ct.startsWith('image/');
      }
    } catch (_) {}
    return false;
  }
}
