// ...existing code...
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:aquaponic_01/Data/model/clasifikasi.dart';
import 'package:aquaponic_01/Data/model/data_sensor.dart';
import 'package:aquaponic_01/Data/model/savepot.dart';
import 'package:http/http.dart' as http;

class SensorApi {
  static const String baseUrl = 'http://192.168.1.9:5000';

  static const Duration _timeout = Duration(seconds: 12);

  static Future<SensorData> fetchSensorData() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/latest-sensor'))
          .timeout(_timeout);
      if (res.statusCode == 200)
        return SensorData.fromJson(jsonDecode(res.body));
      throw Exception('fetchSensorData: status ${res.statusCode}');
    } catch (e) {
      throw Exception("gagal masuk: $e");
    }
  }

  static Future<List<ClassificationData>> fetchWeeklyHistory() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/latest-image'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => ClassificationData.fromJson(e)).toList();
      }
      throw Exception(
        "Gagal ambil data klasifikasi - status ${res.statusCode}",
      );
    } catch (e) {
      throw Exception("Error klasifikasi: $e");
    }
  }

  static Future<bool> savePotData(List<Savepot> pots) async {
    try {
      final url = Uri.parse('$baseUrl/save-pots');
      final body = jsonEncode({"pots": pots.map((p) => p.toJson()).toList()});
      final res = await http
          .post(url, headers: {"Content-Type": "application/json"}, body: body)
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      print("Error savePotData: $e");
      return false;
    }
  }

  static Future<String?> fetchLatestImageUrl({
    Duration timeout = _timeout,
  }) async {
    try {
      final respLatest = await http
          .get(Uri.parse('$baseUrl/latest-image'))
          .timeout(timeout);

      if (respLatest.statusCode == 200) {
        final body = jsonDecode(respLatest.body);
        if (body is List && body.isNotEmpty) {
          final first = body.first as Map<String, dynamic>;
          final raw =
              (first['image'] ?? first['labeled_file'] ?? first['url'] ?? '')
                  as String;
          if (raw.isNotEmpty) return _toFullUrl(raw);
        }
      }

      // 2️⃣ fallback kalau latest-image null → baru get-image
      final respGet = await http
          .get(Uri.parse('$baseUrl/get-image'))
          .timeout(timeout);

      if (respGet.statusCode == 200) {
        final map = jsonDecode(respGet.body);
        final url = map['url'] as String?;
        if (url != null && url.isNotEmpty) return _toFullUrl(url);
      }

      // 3️⃣ fallback terakhir
      final tryFile = await _tryLatestImageFileHead(timeout);
      if (tryFile != null) return tryFile;
    } catch (e) {
      print("fetchLatestImageUrl error: $e");
    }

    return null;
  }

  static Future<String?> fetchLatestClassificationImageUrl({
    Duration timeout = _timeout,
  }) async {
    try {
      final respLatest = await http
          .get(Uri.parse('$baseUrl/latest-image'))
          .timeout(timeout);
      if (respLatest.statusCode == 200) {
        final body = jsonDecode(respLatest.body);
        if (body is List && body.isNotEmpty) {
          final first = body.first as Map<String, dynamic>;
          final raw =
              (first['image'] ?? first['labeled_file'] ?? first['url'] ?? '')
                  as String;
          if (raw.isNotEmpty) return _toFullUrl(raw);
        }
      }

      final respGet = await http
          .get(Uri.parse('$baseUrl/get-image'))
          .timeout(timeout);
      if (respGet.statusCode == 200) {
        final map = jsonDecode(respGet.body);
        final url = map['url'] as String?;
        if (url != null && url.isNotEmpty) return _toFullUrl(url);
      }

      final tryFile = await _tryLatestImageFileHead(timeout);
      if (tryFile != null) return tryFile;
    } on TimeoutException catch (e) {
      print("fetchLatestClassificationImageUrl timeout: $e");
    } catch (e) {
      print("fetchLatestClassificationImageUrl error: $e");
    }
    return null;
  }

  static Future<String?> fetchLatestSetupImageUrl({
    Duration timeout = _timeout,
  }) async {
    try {
      final respGet = await http
          .get(Uri.parse('$baseUrl/get-image'))
          .timeout(timeout);
      if (respGet.statusCode == 200) {
        final map = jsonDecode(respGet.body);
        final url = map['url'] as String?;
        if (url != null && url.isNotEmpty) return _toFullUrl(url);
      }

      final tryFile = await _tryLatestImageFileHead(timeout);
      if (tryFile != null) return tryFile;
    } on TimeoutException catch (e) {
      print("fetchLatestSetupImageUrl timeout: $e");
    } catch (e) {
      print("fetchLatestSetupImageUrl error: $e");
    }
    return null;
  }

  static Future<Uint8List?> fetchLatestSetupImageBytes({
    Duration timeout = _timeout,
  }) async {
    try {
      final url = await fetchLatestSetupImageUrl(timeout: Duration(seconds: 8));
      if (url == null) {
        print("fetchLatestSetupImageBytes: no URL");
        // try direct latest-image-file if present
        final direct = await _tryDirectLatestImageFile(timeout);
        if (direct != null) return direct;
        return null;
      }
      final resp = await http.get(Uri.parse(url)).timeout(timeout);
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty)
        return resp.bodyBytes;
      print("fetchLatestSetupImageBytes: failed status=${resp.statusCode}");
    } on TimeoutException catch (e) {
      print("fetchLatestSetupImageBytes timeout: $e");
    } catch (e) {
      print("fetchLatestSetupImageBytes error: $e");
    }
    return null;
  }

  static Future<Uint8List?> fetchLatestImageBytes({
    Duration timeout = _timeout,
  }) async {
    try {
      final url = await fetchLatestImageUrl(timeout: Duration(seconds: 8));
      if (url == null) {
        print("fetchLatestImageBytes: no URL");
        final direct = await _tryDirectLatestImageFile(timeout);
        if (direct != null) return direct;
        return null;
      }
      final resp = await http.get(Uri.parse(url)).timeout(timeout);
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty)
        return resp.bodyBytes;
      print("fetchLatestImageBytes: failed status=${resp.statusCode}");
    } on TimeoutException catch (e) {
      print("fetchLatestImageBytes timeout: $e");
    } catch (e) {
      print("fetchLatestImageBytes error: $e");
    }
    return null;
  }

  static Future<String?> _tryLatestImageFileHead(Duration timeout) async {
    try {
      final head = await http
          .head(Uri.parse('$baseUrl/latest-image-file'))
          .timeout(timeout);
      if (head.statusCode == 200) return _toFullUrl('/latest-image-file');
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> _tryDirectLatestImageFile(Duration timeout) async {
    try {
      final url = _toFullUrl('/latest-image-file');
      final resp = await http.get(Uri.parse(url)).timeout(timeout);
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty)
        return resp.bodyBytes;
    } catch (_) {}
    return null;
  }

  static String _toFullUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return baseUrl + raw;
    return '$baseUrl/$raw';
  }

  static Future<String?> fetchSetupImageUrl() async {
    final response = await http.get(Uri.parse("$baseUrl/get-image"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["exists"] == true) {
        return data["url"];
      }
    }

    return null;
  }
}
