import 'dart:convert';
import 'dart:typed_data';
import 'package:aquaponic_01/Data/model/clasifikasi.dart';
import 'package:aquaponic_01/Data/model/savepot.dart';
import 'package:http/http.dart' as http;
import '../../model/data_sensor.dart';

class SensorApi {
  static const String baseUrl = 'http://192.168.219.228:5000';
  static Future<SensorData> fetchSensorData() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/latest-sensor'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return SensorData.fromJson(data);
      } else {
        throw Exception('data gagal');
      }
    } catch (e) {
      throw Exception("gagal masuk: $e");
    }
  }

  static Future<List<ClassificationData>> fetchWeeklyHistory() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/latest-image'));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => ClassificationData.fromJson(e)).toList();
      } else {
        throw Exception("Gagal ambil data klasifikasi");
      }
    } catch (e) {
      throw Exception("Error klasifikasi: $e");
    }
  }

  static Future<bool> savePotData(List<Savepot> pots) async {
    try {
      final url = Uri.parse('$baseUrl/save-pots');

      final body = jsonEncode({"pots": pots.map((p) => p.toJson()).toList()});

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("STATUS: ${res.statusCode}");
      print("RESP: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      print("Error savePotData: $e");
      return false;
    }
  }
}
