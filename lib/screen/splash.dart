import 'package:flutter/material.dart';
import 'package:aquaponic_01/screen/login.dart';
import '../utils/const.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu 3 detik sebelum pindah ke Login
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pastikan kamu sudah punya file assets/img/logo.png
            Image.asset('assets/img/logo.png', height: 150),
            const SizedBox(height: 30),
            const Text(
              'Smart AquaPonic',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
