import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';

//Creating the Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      //replaces the Splash Screen with the Welcome Screen
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06235F),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),

              child: const Icon(Icons.memory, size: 70, color: Colors.white),
            ),

            const SizedBox(height: 30),

            const Text(
              'ESP32',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Device Controller',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 50),

            const CircularProgressIndicator(color: Colors.white),

            const SizedBox(height: 15),

            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
