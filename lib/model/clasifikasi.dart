class ClassificationData {
  final int id;
  final int potNumber;
  final String pred;
  final double confidence;
  final String image;
  final DateTime timestamp;

  ClassificationData({
    required this.id,
    required this.potNumber,
    required this.pred,
    required this.confidence,
    required this.image,
    required this.timestamp,
  });

  factory ClassificationData.fromJson(Map<String, dynamic> json) {
    return ClassificationData(
      id: json['id_log'] ?? 0,
      potNumber: json['pot_number'] ?? 0,
      pred: json['pred'] ?? '',
      confidence: (json['confid'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
