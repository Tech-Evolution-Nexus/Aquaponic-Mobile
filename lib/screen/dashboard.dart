import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/api_sensor.dart';
import '../utils/const.dart';
import '../services/mqtt_service.dart';

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

  bool powerOn = false;
  late MqttService mqtt;

  @override
  void initState() {
    super.initState();
    mqtt = MqttService();
    mqtt.connect();
    Timer.periodic(const Duration(seconds: 3), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final data = await SensorApi.fetchSensorData();

    setState(() {
      if (phList.length > 10) phList.removeAt(0);
      if (tdsList.length > 10) tdsList.removeAt(0);
      if (suhuAirList.length > 10) suhuAirList.removeAt(0);
      if (suhuRuanganList.length > 10) suhuRuanganList.removeAt(0);
      if (kelembapanList.length > 10) kelembapanList.removeAt(0);

      phList.add(data.ph);
      tdsList.add(data.tds);
      suhuAirList.add(data.waterTemperature);
      suhuRuanganList.add(data.airTemperature);
      kelembapanList.add(data.humidity);
    });
  }

  void togglePower() {
    setState(() => powerOn = !powerOn);
    mqtt.publishPower(powerOn);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Power: ${powerOn ? 'ON' : 'OFF'}"),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Sensor Gabungan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Menampilkan pH, TDS, suhu air, suhu ruangan dan kelembapan realtime.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),

            Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA7FF83), Color(0xFFC4FFD7)],
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
                        maxY: 100,
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
                            bottom: BorderSide(color: Colors.grey.shade400),
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
                ),
                _DashboardCard(
                  title: 'TDS',
                  value: tdsList.isNotEmpty
                      ? tdsList.last.toStringAsFixed(0)
                      : '--',
                  imagePath: 'assets/img/TDS.png',
                ),
                _DashboardCard(
                  title: 'Suhu Air',
                  value: suhuAirList.isNotEmpty
                      ? '${suhuAirList.last.toStringAsFixed(1)} °C'
                      : '--',
                  imagePath: 'assets/img/suhuair.png',
                ),
                _DashboardCard(
                  title: 'Suhu Ruangan',
                  value: suhuRuanganList.isNotEmpty
                      ? '${suhuRuanganList.last.toStringAsFixed(1)} °C'
                      : '--',
                  imagePath: 'assets/img/suhura.png',
                ),
                _DashboardCard(
                  title: 'Kelembapan',
                  value: kelembapanList.isNotEmpty
                      ? '${kelembapanList.last.toStringAsFixed(1)} %'
                      : '--',
                  imagePath: 'assets/img/humidity.png',
                ),
                _DashboardPowerCard(isOn: powerOn, onPressed: togglePower),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) return;

          if (index == 1) {
            Navigator.pushNamed(context, '/pot_analyzer');
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/history');
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
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<double> list, Color color) {
    return LineChartBarData(
      spots: List.generate(list.length, (i) => FlSpot(i.toDouble(), list[i])),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _DashboardPowerCard extends StatelessWidget {
  final bool isOn;
  final VoidCallback onPressed;

  const _DashboardPowerCard({required this.isOn, required this.onPressed});

  @override
  Widget build(BuildContext context) {
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
              isOn ? "Power ON" : "Power OFF",
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String imagePath;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA7FF83), Color(0xFFC4FFD7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 42, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
