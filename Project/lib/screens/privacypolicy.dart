import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'At BalanceBite, we are committed to protecting your privacy and ensuring the security of your personal information. '
              'This Privacy Policy outlines how we collect, use, and safeguard your data when you use our app.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Information We Collect:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Personal Information: Name, email, age, weight, height, and dietary preferences.\n'
              '• Usage Data: Information about how you interact with the app.\n'
              '• Device Information: Device type, operating system, and unique device identifiers.\n'
              '• Food and Activity Data: Data related to food recognition, calorie intake, and physical activities.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How We Use Your Information:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• To provide personalized nutrition and fitness recommendations.\n'
              '• To improve the functionality and user experience of the app.\n'
              '• To communicate with you about updates, offers, and support.\n'
              '• To analyze app usage and trends for research and development.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Data Security:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We implement industry-standard security measures to protect your data from unauthorized access, '
              'alteration, or disclosure. Your information is stored securely and accessed only by authorized personnel.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
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
              'If you have any questions or concerns about our Privacy Policy, please contact us at:\n'
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