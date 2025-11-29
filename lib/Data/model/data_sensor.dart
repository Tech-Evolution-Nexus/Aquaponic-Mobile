class SensorData {
  final double ph;
  final double tds;
  final double water_temperature;
  final double temperature;
  final double humidity;
  final bool? relay;
  final DateTime timestamp;

  SensorData({
    required this.ph,
    required this.tds,
    required this.water_temperature,
    required this.temperature,
    required this.humidity,
    required this.relay,
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
      water_temperature: toDouble(json['water_temperature']),
      temperature: toDouble(json['temperature']),
      humidity: toDouble(json['humidity']),
      relay: toBool(json['relay']),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
