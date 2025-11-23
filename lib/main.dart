import 'package:aquaponic_01/screen/pot_analyzer.dart';
import 'package:flutter/material.dart';
import 'utils/const.dart';
import 'screen/splash.dart';

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

      /// ========== ROUTE DIDAFTARKAN DI SINI ==========
      home: const SplashScreen(),
      routes: {
        '/pot_analyzer': (context) => const PotAnalyzerScreen(),
        // '/setting': (context) => const SettingScreen(),
      },
      /// =================================================
    );
  }
}
