import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/data_sensor.dart';

class SensorApi {
  static const String baseUrl = 'http://192.168.8.228:5000';
  static Future<SensorData> fetchSensorData() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/latest'));

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
}
