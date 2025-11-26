import 'package:aquaponic_01/api/api_sensor.dart';
import 'package:aquaponic_01/model/clasifikasi.dart';
import 'package:flutter/material.dart';
import '../utils/const.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ClassificationData>> _historyData;

  @override
  void initState() {
    super.initState();
    _historyData = SensorApi.fetchWeeklyHistory();
  }

  // ------------------ COLOR HELPER ------------------
  Color getChipColor(String pred) {
    switch (pred.toLowerCase()) {
      case 'kuning':
        return Colors.orange;
      case 'rusak':
        return Colors.red;
      default:
        return kPrimaryColor; // default hijau utama
    }
  }

  Color getBackgroundCard(String pred) {
    switch (pred.toLowerCase()) {
      case 'kuning':
        return Colors.orange.withOpacity(0.08);
      case 'rusak':
        return Colors.red.withOpacity(0.08);
      default:
        return kPrimaryColor.withOpacity(0.08); // default hijau muda
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: kBackgroundLight,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
        title: const Text(
          "History Klasifikasi",
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<List<ClassificationData>>(
        future: _historyData,
        builder: (context, snapshot) {
          // ------------ LOADING ------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
                strokeWidth: 3,
              ),
            );
          }

          // ------------ ERROR ------------
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Gagal memuat data",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          // ------------ NO DATA ------------
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Belum ada data minggu ini",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          // ------------ DATA READY ------------
          final data = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = data[index];

              return Container(
                decoration: BoxDecoration(
                  color: getBackgroundCard(item.pred),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- IMAGE ----------------
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.image,
                        width: 95,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 95,
                            height: 95,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ---------------- TEXT CONTENT ----------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // STATUS CHIP
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: getChipColor(item.pred),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              item.pred.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Tanggal",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),

                          Text(
                            "${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextColor,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Confidence",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),

                          Text(
                            "${(item.confidence * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
