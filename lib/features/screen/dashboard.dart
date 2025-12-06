import 'dart:async';
import 'dart:convert';
import 'package:aquaponic_01/Core/const/sensor_limits.dart';
import 'package:aquaponic_01/features/screen/maintenance.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../Data/services/api/api_sensor.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../../Core/const/const.dart';
import '../../Data/services/Mqtt/mqtt_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<double> phList = [];
  final List<double> tdsList = [];
  final List<double> suhuAirList = [];
  final List<double> suhuRuanganList = [];
  final List<double> kelembapanList = [];

  String temperature = "";
  String humidity = "";
  String waterTemp = "";
  String ph = "";
  String tds = "";

  bool powerOn = false;
  late MqttService mqtt;

  String? latestImageUrl;
  DateTime? _lastWarningTime;
  Timer? _imageTimer;
  bool maintenanceActive = false;
  int? maintenanceSeconds;
  Timer? maintenanceTimer;
  int? maintenanceCountdown;
  Timer? countdownTimer;
  bool manualLockActive = false;
  int? manualLockSeconds;
  Timer? manualLockTimer;
  Timer? manualLockCountdownTimer;

  @override
  void initState() {
    super.initState();
    mqtt = MqttService();
    mqtt
        .connect(
          onMessage: (topic, payload) {
            // ⬇⬇⬇ ADD DEBUG PRINT HERE
            print("📩 MQTT RECEIVED TOPIC: $topic  |  PAYLOAD: $payload");
            // ⬆⬆⬆

            setState(() {
              final value = double.tryParse(payload) ?? 0;

              if (topic.endsWith("/ph")) {
                ph = payload;
                phList.add(value);
                if (phList.length > 20) phList.removeAt(0);
              } else if (topic.endsWith("/tds")) {
                tds = payload;
                tdsList.add(value);
                if (tdsList.length > 20) tdsList.removeAt(0);
              } else if (topic.endsWith("/wtr_temp")) {
                waterTemp = payload;
                suhuAirList.add(value);
                if (suhuAirList.length > 20) suhuAirList.removeAt(0);
              } else if (topic.endsWith("/temp")) {
                temperature = payload;
                suhuRuanganList.add(value);
                if (suhuRuanganList.length > 20) suhuRuanganList.removeAt(0);
              } else if (topic.endsWith("/hum")) {
                humidity = payload;
                kelembapanList.add(value);
                if (kelembapanList.length > 20) kelembapanList.removeAt(0);
              }
            });

            // 🚨 Setelah update sensor, cek peringatan
            checkWarnings(
              double.tryParse(ph) ?? 0,
              double.tryParse(tds) ?? 0,
              double.tryParse(waterTemp) ?? 0,
              double.tryParse(temperature) ?? 0,
              double.tryParse(humidity) ?? 0,
            );
          },
        )
        .then((_) {
          mqtt.subscribe("aquaponic/#");
          print("📡 SUBSCRIBED TO aquaponic/#");
        });

    _fetchLatestImage();
    _imageTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _fetchLatestImage(),
    );
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    super.dispose();
  }

  void checkWarnings(
    double ph,
    double tds,
    double suhuAir,
    double suhuRuang,
    double hum,
  ) {
    final Map<String, double> warnings = {};

    // Deteksi sensor yang keluar batas
    if (ph < PH_MIN || ph > PH_MAX) warnings["pH"] = ph;
    if (tds < TDS_MIN || tds > TDS_MAX) warnings["TDS"] = tds;
    if (suhuAir < SUHU_AIR_MIN || suhuAir > SUHU_AIR_MAX)
      warnings["SuhuAir"] = suhuAir;
    if (suhuRuang < SUHU_RUANGAN_MIN || suhuRuang > SUHU_RUANGAN_MAX)
      warnings["SuhuRuang"] = suhuRuang;
    if (hum < KELEMBAPAN_MIN || hum > KELEMBAPAN_MAX)
      warnings["Kelembapan"] = hum;

    if (warnings.isEmpty) return;

    // Kirim semua warning ke MQTT
    warnings.forEach((sensor, value) {
      _publishWarning(sensor, value);
    });

    String warningMsg = "";
    if (warnings.containsKey("pH")) {
      warningMsg = "⚠ pH air tidak normal!";
    } else if (warnings.containsKey("TDS")) {
      warningMsg = "⚠ TDS berada di luar batas!";
    } else if (warnings.containsKey("SuhuAir")) {
      warningMsg = "⚠ Suhu air tidak normal!";
    } else if (warnings.containsKey("SuhuRuang")) {
      warningMsg = "⚠ Suhu ruangan terlalu ekstrem!";
    } else if (warnings.containsKey("Kelembapan")) {
      warningMsg = "⚠ Kelembapan tidak stabil!";
    }

    if (mounted) {
      final now = DateTime.now();
      if (_lastWarningTime != null &&
          now.difference(_lastWarningTime!).inSeconds < 10) {
        return;
      }
      _lastWarningTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warningMsg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _publishMaintenanceStatus(bool active, int? duration) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(active ? "ACTIVE:$duration" : "INACTIVE");
    mqtt.client?.publishMessage(
      'aquaponic/esp32/status',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void _publishMaintenanceRemaining(int remaining) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(remaining.toString());
    mqtt.client?.publishMessage(
      'aquaponic/esp32/maint_remaining',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void _publishPumpMode() {
    final builder = MqttClientPayloadBuilder();
    builder.addString(powerOn ? "ON" : "OFF");
    mqtt.client?.publishMessage(
      'aquaponic/esp32/pump_mode',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void _publishWarning(String sensor, double value) {
    final builder = MqttClientPayloadBuilder();
    builder.addString("$sensor:$value");
    mqtt.client?.publishMessage(
      'aquaponic/esp32/warning',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void togglePower() {
    if (maintenanceActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Maintenance sedang aktif, pompa akan menyala otomatis nanti.",
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (powerOn) {
      // Matikan pompa manual
      setState(() {
        powerOn = false;
        mqtt.setPump(false);
      });

      // Timer peringatan 15 menit
      manualLockTimer?.cancel();
      manualLockTimer = Timer(const Duration(minutes: 15), () {
        if (!powerOn && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠ Pompa sudah 15 menit dimatikan manual!"),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 15),
            ),
          );
        }
      });
    } else {
      // Nyalakan pompa manual
      mqtt.setPump(true);
      setState(() => powerOn = true);

      // Batalkan timer peringatan kalau sudah dinyalakan
      manualLockTimer?.cancel();
    }

    _publishPumpMode();
  }

  Future<void> _fetchLatestImage() async {
    try {
      final url = await SensorApi.fetchLatestImageUrl();
      debugPrint('DEBUG: latest image url -> $url');
      if (!mounted) return;
      setState(() => latestImageUrl = url);
    } catch (e) {
      debugPrint('fetch latest image error: $e');
    }
  }

  LineChartBarData _buildLine(List<double> list, Color color) {
    return LineChartBarData(
      spots: List.generate(list.length, (i) => FlSpot(i.toDouble(), list[i])),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ClipPath(
          clipper: BottomCurveClipper(),
          child: AppBar(
            toolbarHeight: 120,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 160, 235, 176),
                    Color(0xFF4CAF50),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Image.asset("assets/img/logo.png", height: 60),
                  const SizedBox(width: 17),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "AQUANEK",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Aquaponic Network Experience",
                        style: TextStyle(
                          color: Color.fromARGB(179, 220, 216, 216),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Sensor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'pH, TDS, suhu air, suhu ruangan dan kelembapan',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // CHART + GAMBAR
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Chart
                  Container(
                    width: 350,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 186, 238, 197),
                          Color(0xFF4CAF50),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: phList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY:
                                  [
                                    ...phList,
                                    ...tdsList,
                                    ...suhuAirList,
                                    ...suhuRuanganList,
                                    ...kelembapanList,
                                  ].fold<double>(
                                    0,
                                    (prev, element) =>
                                        element > prev ? element : prev,
                                  ) +
                                  10,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 24,
                                    getTitlesWidget: (value, _) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, _) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                  left: BorderSide(color: Colors.grey.shade400),
                                ),
                              ),
                              lineBarsData: [
                                _buildLine(phList, Colors.green),
                                _buildLine(tdsList, Colors.blue),
                                _buildLine(suhuAirList, Colors.red),
                                _buildLine(suhuRuanganList, Colors.orange),
                                _buildLine(kelembapanList, Colors.purple),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Gambar hasil klasifikasi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Hasil Klasifikasi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (latestImageUrl == null) return;

                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(10),
                              child: InteractiveViewer(
                                panEnabled: true,
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    '${latestImageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text("Gagal memuat gambar"),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: latestImageUrl == null
                              ? const Center(child: Text("Belum ada gambar."))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    '${latestImageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}',
                                    gaplessPlayback: true,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text("Gagal memuat gambar"),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _Legend(color: Colors.green, label: 'pH'),
                _Legend(color: Colors.blue, label: 'TDS'),
                _Legend(color: Colors.red, label: 'Suhu Air'),
                _Legend(color: Colors.orange, label: 'Suhu Ruangan'),
                _Legend(color: Colors.purple, label: 'Kelembapan'),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _DashboardCard(
                  title: 'pH Air',
                  value: phList.isNotEmpty
                      ? phList.last.toStringAsFixed(2)
                      : '--',
                  imagePath: 'assets/img/ph.png',
                  sensorValue: phList.isNotEmpty ? phList.last : null,
                  minValue: PH_MIN,
                  maxValue: PH_MAX,
                ),
                _DashboardCard(
                  title: 'TDS',
                  value: tdsList.isNotEmpty
                      ? tdsList.last.toStringAsFixed(0)
                      : '--',
                  imagePath: 'assets/img/TDS.png',
                  sensorValue: tdsList.isNotEmpty ? tdsList.last : null,
                  minValue: TDS_MIN,
                  maxValue: TDS_MAX,
                ),
                _DashboardCard(
                  title: 'Suhu Air',
                  value: suhuAirList.isNotEmpty
                      ? '${suhuAirList.last.toStringAsFixed(1)} °C'
                      : '--',
                  imagePath: 'assets/img/suhuair.png',
                  sensorValue: suhuAirList.isNotEmpty ? suhuAirList.last : null,
                  minValue: SUHU_AIR_MIN,
                  maxValue: SUHU_AIR_MAX,
                ),
                _DashboardCard(
                  title: 'Suhu Ruangan',
                  value: suhuRuanganList.isNotEmpty
                      ? '${suhuRuanganList.last.toStringAsFixed(1)} °C'
                      : '--',
                  imagePath: 'assets/img/suhura.png',
                  sensorValue: suhuRuanganList.isNotEmpty
                      ? suhuRuanganList.last
                      : null,
                  minValue: SUHU_RUANGAN_MIN,
                  maxValue: SUHU_RUANGAN_MAX,
                ),
                _DashboardCard(
                  title: 'Kelembapan',
                  value: kelembapanList.isNotEmpty
                      ? '${kelembapanList.last.toStringAsFixed(1)} %'
                      : '--',
                  imagePath: 'assets/img/humidity.png',
                  sensorValue: kelembapanList.isNotEmpty
                      ? kelembapanList.last
                      : null,
                  minValue: KELEMBAPAN_MIN,
                  maxValue: KELEMBAPAN_MAX,
                ),
                _DashboardPowerCard(
                  isOn: powerOn,
                  onPressed: togglePower,
                  countdown: maintenanceCountdown,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        currentIndex: 0,
        elevation: 0,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          if (index == 1) Navigator.pushNamed(context, '/pot_analyzer');
          if (index == 2) Navigator.pushNamed(context, '/history');
          if (index == 3) {
            final result = await Navigator.push<int>(
              context,
              MaterialPageRoute(builder: (_) => MaintenanceScreen(mqtt: mqtt)),
            );
            if (result != null) {
              setState(() {
                maintenanceActive = true;
                maintenanceSeconds = result;
                maintenanceCountdown = result;
                powerOn = false;
                mqtt.setPump(false);

                // Kirim status maintenance ACTIVE
                _publishMaintenanceStatus(true, maintenanceSeconds);
              });

              // Timer maintenance otomatis
              maintenanceTimer?.cancel();
              countdownTimer?.cancel();

              countdownTimer = Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (maintenanceCountdown! > 0) {
                  setState(() {
                    maintenanceCountdown = maintenanceCountdown! - 1;

                    // Update MQTT setiap detik sisa maintenance
                    _publishMaintenanceRemaining(maintenanceCountdown!);
                  });
                } else {
                  timer.cancel();
                }
              });

              maintenanceTimer = Timer(
                Duration(seconds: maintenanceSeconds!),
                () {
                  mqtt.setPump(true);
                  setState(() {
                    powerOn = true;
                    maintenanceActive = false;
                    maintenanceSeconds = null;
                    maintenanceCountdown = null;

                    // Kirim status maintenance INACTIVE
                    _publishMaintenanceStatus(false, null);
                  });
                },
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Maintenance aktif, pompa akan menyala setelah $maintenanceSeconds detik",
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.crop),
            label: "Pot Analyzer",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),

          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services_outlined),
            label: "Maintance",
          ),
        ],
      ),
    );
  }
}

class _DashboardPowerCard extends StatelessWidget {
  final bool isOn;
  final VoidCallback onPressed;
  final int? countdown; // tambahkan ini

  const _DashboardPowerCard({
    required this.isOn,
    required this.onPressed,
    this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    String displayText = isOn ? "Power ON" : "Power OFF";
    if (countdown != null && countdown! > 0) {
      final minutes = countdown! ~/ 60;
      final seconds = countdown! % 60;
      displayText =
          "Maintenance\n${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOn
                ? [Colors.greenAccent, Colors.lightGreen]
                : [Colors.grey.shade300, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOn ? Icons.power : Icons.power_off,
              size: 50,
              color: isOn ? Colors.green.shade900 : Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final String imagePath;
  final double? sensorValue;
  final double? minValue;
  final double? maxValue;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.imagePath,
    this.sensorValue,
    this.minValue,
    this.maxValue,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWarning = false;
    print(
      "DEBUG CARD -> ${widget.title} : "
      "value=${widget.sensorValue}, "
      "min=${widget.minValue}, max=${widget.maxValue}",
    );
    if (widget.sensorValue != null &&
        widget.minValue != null &&
        widget.maxValue != null) {
      const double eps = 0.001; // toleransi aman

      isWarning =
          widget.sensorValue! < widget.minValue! - eps ||
          widget.sensorValue! > widget.maxValue! + eps;
    }

    return Container(
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? Colors.red : Colors.green,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(widget.imagePath, height: 42),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double h = size.height;

    Path path = Path();
    path.lineTo(0, h - 50);

    // Lengkungan lebih dalam & smooth
    path.cubicTo(
      size.width * 0.25,
      h,
      size.width * 0.75,
      h - 100,
      size.width,
      h - 40,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(oldClipper) => false;
}
