import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/api_sensor.dart';
import '../model/data_sensor.dart';
import '../utils/const.dart';
import 'detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const _AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Grafik ini menunjukkan pemantauan kangkung secara real-time.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // ====== GRAFIK DARI DATA DUMMY ======
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailScreen()),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA7FF83), Color(0xFFC4FFD7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: FutureBuilder<SensorData>(
                  future: DummyApi.fetchDummyData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!;
                    final spots = List.generate(
                      data.riwayatSuhuAir.length,
                      (i) => FlSpot(i.toDouble(), data.riwayatSuhuAir[i]),
                    );

                    return LineChart(
                      LineChartData(
                        minY: 20,
                        maxY: 35,
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
                              reservedSize: 22,
                              getTitlesWidget: (value, _) {
                                const labels = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                ];
                                if (value.toInt() < labels.length) {
                                  return Text(
                                    labels[value.toInt()],
                                    style: const TextStyle(fontSize: 12),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) => Text(
                                '${value.toInt()}°',
                                style: const TextStyle(fontSize: 11),
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
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.greenAccent.shade400,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.greenAccent.withOpacity(0.1),
                            ),
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ==== GRIDVIEW SENSOR ====
            FutureBuilder<SensorData>(
              future: DummyApi.fetchDummyData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.25,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _DashboardCard(
                      title: 'Suhu Air',
                      value: '${data.suhuAir.toStringAsFixed(1)} °C',
                      imagePath: 'assets/img/suhuair.png',
                    ),
                    _DashboardCard(
                      title: 'Suhu Ruangan',
                      value: '${data.suhuRuangan.toStringAsFixed(1)} °C',
                      imagePath: 'assets/img/suhura.png',
                    ),
                    _DashboardCard(
                      title: 'Kandungan Mineral',
                      value: '${data.kandunganMineral.toStringAsFixed(1)}%',
                      imagePath: 'assets/img/air.png',
                    ),
                    _DashboardCard(
                      title: 'pH Air',
                      value: data.phAir.toStringAsFixed(1),
                      imagePath: 'assets/img/ph.png',
                    ),
                    _DashboardCard(
                      title: 'Water Pump',
                      value: data.waterPump ? 'ON' : 'OFF',
                      imagePath: 'assets/img/power.png',
                    ),
                    const _DashboardCard(
                      title: 'Notifikasi',
                      value: '-',
                      imagePath: 'assets/img/lonceng.png',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===== DRAWER MENU =====
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFA7FF83), Color(0xFFC4FFD7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.green, size: 40),
            ),
            accountName: const Text('Nama Pengguna'),
            accountEmail: const Text('user@email.com'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifikasi'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Keluar',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ====== KARTU SENSOR ======
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 42, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
