class SensorData {
  final double suhuAir;
  final double suhuRuangan;
  final double phAir;
  final double kandunganMineral;
  final bool waterPump;
  final List<double> riwayatSuhuAir;

  SensorData({
    required this.suhuAir,
    required this.suhuRuangan,
    required this.phAir,
    required this.kandunganMineral,
    required this.waterPump,
    required this.riwayatSuhuAir,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      suhuAir: json['suhuAir'],
      suhuRuangan: json['suhuRuangan'],
      phAir: json['phAir'],
      kandunganMineral: json['kandunganMineral'],
      waterPump: json['waterPump'],
      riwayatSuhuAir: List<double>.from(json['riwayatSuhuAir']),
    );
  }
}
