import 'dart:math';

import 'package:balancebite/dbHelper/local_database.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class ForgotPassword extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final Connectivity _connectivity = Connectivity();

  Future<void> _processPasswordReset(String email, String token) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      await MongoDBService.sendResetEmail(email, token);
    } else {
      await LocalDatabase.queuePasswordReset(email, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF232323),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 52.0),
                      child: Image.asset(
                        'assets/logobd.png',
                        width: screenWidth * 0.1,
                        height: screenHeight * 0.05,
                      ),
                    ),
                    SizedBox(width: 30),
                    Padding(
                      padding: const EdgeInsets.only(top: 42.0),
                      child: Text(
                        'Forgotten Password',
                        style: TextStyle(
                          color: Color(0xFFE2F163),
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Enter your email address to receive a reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'League Spartan',
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(116, 217, 234, 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Enter your email address',
                      style: TextStyle(
                        color: Color(0xFF232323),
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'League Spartan',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(
                        color: Color(0xFF232323),
                        fontSize: screenWidth * 0.04,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        hintText: 'example@example.com',
                        hintStyle: TextStyle(
                          color: Color(0xFF232323),
                          textBaseline: TextBaseline.alphabetic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF232323),
                  backgroundColor: const Color(0xFFE2F163),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                onPressed: () async {
                  final email = _emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your email address')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // Check connectivity
                    final connectivityResult = await _connectivity.checkConnectivity();
                    final isOnline = connectivityResult != ConnectivityResult.none;

                    // Sync users first
                    if (isOnline) await LocalDatabase.syncPendingUsers();

                    // Check email existence
                    bool emailExists = false;
                    if (isOnline) {
                      emailExists = await MongoDBService.checkEmailExists(email);
                    } else {
                      emailExists = await LocalDatabase.doesEmailExist(email);
                    }

                    if (!emailExists) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email not found')),
                      );
                      return;
                    }

                    // Generate or retrieve token
                    String token;
                    if (isOnline) {
                      token = await MongoDBService.generateResetToken(email);
                    } else {
                      final user = await LocalDatabase.getUserByEmail(email);
                      token = user?['resetToken'] ?? _generateSecureToken();
                    }

                    // Process password reset
                    await _processPasswordReset(email, token);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isOnline
                            ? 'Reset link sent to your email'
                            : 'Request queued - will send when online'),
                      ),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateSecureToken() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (i) => random.nextInt(256)));
  }
}
