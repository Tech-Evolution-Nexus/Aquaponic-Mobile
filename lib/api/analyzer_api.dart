import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AnalyzerApi {
  static const String baseUrl = "http://192.168.1.91:5000";

  static Future<Uint8List?> fetchLatestImage() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/latest-image"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["image"] != null) {
          return base64Decode(data["image"]);
        }
        return null;
      } else {
        throw Exception("Gagal ambil gambar");
      }
    } catch (e) {
      print("Error fetchLatestImage: $e");
      return null;
    }
  }
}
