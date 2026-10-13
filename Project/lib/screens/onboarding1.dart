import 'package:flutter/material.dart';
import 'onboarding2.dart'; // Import onboarding2.dart

class HeroSection extends StatelessWidget {
  const HeroSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtain screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      },
      child: Scaffold(
        body: Center(
          child: Container(
            width: double.infinity, // Fill 100% width
            height: double.infinity, // Fill 100% height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
              color: const Color(0xFF232323),
            ),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/heroimage.png',
                    fit: BoxFit.cover,
                    semanticLabel: 'Background hero image',
                  ),
                ),
                // Overlay with Text and Logo
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.3, // Dynamically adjust padding
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // "Welcome To" Text
                          Text(
                            'Welcome To',
                            style: TextStyle(
                              color: const Color(0xFFE2F163), // Set text color
                              fontFamily: 'League Spartan', // Use League Spartan font
                              fontWeight: FontWeight.bold, // Bold font
                              fontSize: 25.47, // Font size
                            ),
                          ),
                          const SizedBox(height: 10), // Add space between text and logo
                          // Logo
                          Image.asset(
                            'assets/logobd.png',
                            fit: BoxFit.contain,
                            semanticLabel: 'Hero content image',
                            width: screenWidth * 0.98, // Scale the logo size
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
