import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8FFD8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD8FFD8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ====== GRAFIK ======
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomPaint(painter: _DetailChartPainter()),
          ),

          // ====== BAGIAN PUTIH (DETAIL) ======
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text("Detail",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  // ====== TAB BAR ======
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: const [
                      Tab(text: "Hari ini"),
                      Tab(text: "Kemarin"),
                      Tab(text: "2 Hari Lalu"),
                    ],
                  ),

                  // ====== TAB ISI ======
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDetailList(
                          suhuAir: "28 C",
                          suhuRa: "31 C",
                          mineral: "5%",
                          ph: "6.8",
                        ),
                        _buildDetailList(
                          suhuAir: "27 C",
                          suhuRa: "30 C",
                          mineral: "6%",
                          ph: "6.9",
                        ),
                        _buildDetailList(
                          suhuAir: "29 C",
                          suhuRa: "32 C",
                          mineral: "4%",
                          ph: "7.0",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== LIST DETAIL PER TAB ======
  Widget _buildDetailList({
    required String suhuAir,
    required String suhuRa,
    required String mineral,
    required String ph,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailItem(title: "Suhu Air", value: suhuAir, date: "May 11"),
        _DetailItem(title: "Suhu Ra", value: suhuRa, date: "May 11"),
        _DetailItem(title: "Kandungan Mineral", value: mineral, date: "May 11"),
        _DetailItem(title: "pH Air", value: ph, date: "May 11"),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String title;
  final String value;
  final String date;

  const _DetailItem({
    required this.title,
    required this.value,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(2, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.bold)),
              Text(date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.5,
        size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.3,
        size.width, size.height * 0.5);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
