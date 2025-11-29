import 'package:aquaponic_01/Data/services/Mqtt/mqtt_service.dart';
import 'package:aquaponic_01/features/screen/history.dart';
import 'package:aquaponic_01/features/screen/maintenance.dart';
import 'package:aquaponic_01/features/screen/pot_analyzer.dart';
import 'package:flutter/material.dart';
import 'Core/const/const.dart';
import 'features/screen/splash.dart';

void main() {
  runApp(const SmartAquaponicApp());
}
class SmartAquaponicApp extends StatelessWidget {
  const SmartAquaponicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart AquaPonic',

      theme: ThemeData(
        primaryColor: kPrimaryColor,
        fontFamily: 'Poppins',
      ),

      home: const SplashScreen(),
      routes: {
        '/pot_analyzer': (context) => const PotAnalyzerScreen(),
        '/history': (context) => const HistoryScreen(),
        '/maintenance': (context) => MaintenanceScreen(
              mqtt: MqttService(),
            ),
      },
    );
  }
}
