import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'signin.dart';
import 'onboarding3.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Set status bar to have a black background and white icons
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Set status bar color to black
        statusBarIconBrightness: Brightness.light, // Light icons for visibility
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity, // Fill 100% width
            child: Column(
              children: [
                // Stack with explicit top padding for status bar
                Stack(
                  children: [
                    // Background Image
                    Semantics(
                      label: 'Background Image',
                      child: Container(
                        width: double.infinity,
                        child: Image.asset(
                          'assets/heroimage2.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: screenHeight, // Full screen height
                          semanticLabel: 'Fitness background image',
                        ),
                      ),
                    ),
                    // Overlay and Content
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        padding: EdgeInsets.only(
                          top: statusBarHeight, // Space for status bar
                        ),
                        child: Column(
                          children: [
                            // Skip Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: screenWidth * 0.06),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignInPage(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Skip',
                                        style: TextStyle(
                                          color: const Color(0xFFE2F163),
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w500,
                                          fontSize: screenWidth * 0.045, // Dynamic font size
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Image.asset(
                                        'assets/Arrow.png',
                                        width: screenWidth * 0.03,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Main Content Container
                            Container(
                              margin: EdgeInsets.only(top: screenHeight * 0.35), // Adjust for dynamic content
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.07,
                                vertical: screenHeight * 0.02,
                              ),
                              color: const Color(0xFF0E0C16),
                              child: Column(
                                children: [
                                  // Workout Image
                                  Image.asset(
                                    'assets/workout.png',
                                    width: screenWidth * 0.08,
                                    fit: BoxFit.contain,
                                  ),
                                  Semantics(
                                    label: 'Journey description',
                                    child: Text(
                                      'Start your journey towards a more active lifestyle',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05, // Dynamic font size
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: screenHeight * 0.01),
                                    child: Image.asset(
                                      'assets/bar1.png',
                                      width: screenWidth * 0.15, // Dynamic width
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Next Button
                            Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.03),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OnboardingScreen3(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.09),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    side: const BorderSide(color: Colors.white, width: 0.5),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.25,
                                    vertical: screenHeight * 0.02,
                                  ),
                                ),
                                child: Text(
                                  'Next',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045, // Dynamic font size
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
