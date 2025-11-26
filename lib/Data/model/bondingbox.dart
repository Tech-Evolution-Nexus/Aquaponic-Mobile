class BoundingBox {
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  BoundingBox({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      xMin: json["x_min"],
      yMin: json["y_min"],
      xMax: json["x_max"],
      yMax: json["y_max"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "x_min": xMin,
      "y_min": yMin,
      "x_max": xMax,
      "y_max": yMax,
    };
  }
}
