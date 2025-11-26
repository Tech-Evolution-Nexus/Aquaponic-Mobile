class SensorData {
  final double ph;
  final double tds;
  final double waterTemperature;
  final double airTemperature;
  final double humidity;
  final bool? power;
  final DateTime timestamp;

  SensorData({
    required this.ph,
    required this.tds,
    required this.waterTemperature,
    required this.airTemperature,
    required this.humidity,
    required this.power,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
 
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }

   
    bool? toBool(dynamic value) {
      if (value == null) return null;
      final v = value.toString().trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'on';
    }

    return SensorData(
      ph: toDouble(json['ph']),
      tds: toDouble(json['tds']),
      waterTemperature: toDouble(json['waterTemperature']),
      airTemperature: toDouble(json['airTemperature']),
      humidity: toDouble(json['humidity']),
      power: toBool(json['power']),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
