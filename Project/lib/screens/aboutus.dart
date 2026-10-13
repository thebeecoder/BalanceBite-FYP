import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About BalanceBite',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BalanceBite is a Final Year Project developed by BS (AI) students at their university. '
              'The app leverages Artificial Intelligence to help users maintain a healthy lifestyle by '
              'providing personalized nutrition and fitness recommendations.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Key Features:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Food Recognition: Identify food items using AI.\n'
              '• Calorie Tracking: Calculate calories in recognized food.\n'
              '• Activity Recognition: Track physical activities.\n'
              '• Calorie Burn Calculation: Estimate calories burned during activities.\n'
              '• Personalized Recommendations: Provide tailored nutrition and fitness advice.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Developed By:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Bisma Hashmi (02-136212-005)\n'
              '• Syeda Fizza Batool Zaidi (02-136212-043)\n'
              '• Aleena Ahmed (02-136212-002)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Us:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'For any queries or feedback, please email us at:\n'
              'balancebitefyp@gmail.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}