import 'package:flutter/material.dart';
import 'onboarding1.dart'; // Import the SignUpPage

class LaunchPage extends StatefulWidget {
  const LaunchPage({Key? key}) : super(key: key);

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to SignUpPage after a short delay
    Future.delayed(const Duration(milliseconds: 3200), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HeroSection()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Get screen dimensions
    final width = size.width;
    final height = size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top; // Get status bar height

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: Padding(
        padding: EdgeInsets.only(top: statusBarHeight), // Add padding equal to status bar height
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: width * 1.0, // Use 100% of screen width
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
              color: const Color(0xFF232323),
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0), // Dynamic padding (set to 0 for no padding)
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logobd.png',
                    fit: BoxFit.contain,
                    width: width * 0.9, // 90% of screen width
                    height: height * 0.5, // 50% of screen height
                    semanticLabel: 'Decorative image',
                  ),
                  SizedBox(height: height * 0.03), // Dynamic spacing
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ), // Added loading indicator
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
