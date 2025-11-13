import 'dart:async';
import '../model/data_sensor.dart';

class DummyApi {
  static Future<SensorData> fetchDummyData() async {
    await Future.delayed(const Duration(seconds: 1));

    return SensorData(
      suhuAir: 28.5,
      suhuRuangan: 31.2,
      phAir: 6.8,
      kandunganMineral: 90.0,
      waterPump: true,
      riwayatSuhuAir: [26.5, 27.0, 27.5, 28.0, 28.5, 28.3, 28.7, 29.0],
    );
  }
}
