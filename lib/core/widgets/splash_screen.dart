import 'package:flutter/material.dart';
import '../../features/request/screens/request_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RequestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // Dark background matching banner
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Image.asset(
            'assets/images/intro_banner.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
