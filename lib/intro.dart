import 'package:flutter/material.dart';
import 'package:main_draft1/screens/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Start fade-in animation
    Future.delayed(Duration(milliseconds: 3000), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navigate to Login screen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Login()), // Navigate to Login Page
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 3),
          opacity: _opacity,
          child: Image.asset('assets/logo.png', width: 300), // Your logo
        ),
      ),
    );
  }
}
