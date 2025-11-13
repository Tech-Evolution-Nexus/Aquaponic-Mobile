import 'package:aquaponic_01/screen/splash.dart';
import 'package:flutter/material.dart';
import 'utils/const.dart';

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
    );
  }
}
