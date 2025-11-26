import 'package:aquaponic_01/Data/model/bondingbox.dart';

class Savepot {
  final int potNumber;
  final List<BoundingBox> boundingBoxes;

  Savepot({
    required this.potNumber,
    required this.boundingBoxes,
  });

  factory Savepot.fromJson(Map<String, dynamic> json) {
    return Savepot(
      potNumber: json["pot_number"],
      boundingBoxes: (json["bounding_boxes"] as List)
          .map((box) => BoundingBox.fromJson(box))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "pot_number": potNumber,
      "bounding_boxes":
          boundingBoxes.map((box) => box.toJson()).toList(),
    };
  }
}
