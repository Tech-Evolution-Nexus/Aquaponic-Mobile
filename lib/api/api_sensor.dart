import 'dart:convert';
import 'dart:typed_data';
import 'package:aquaponic_01/model/clasifikasi.dart';
import 'package:http/http.dart' as http;
import '../model/data_sensor.dart';

class SensorApi {
  static const String baseUrl = 'http://192.168.1.91:5000';
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
      throw Exception("gagal masuk ");
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



}
