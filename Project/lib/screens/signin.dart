import 'package:balancebite/dbHelper/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:balancebite/dbHelper/mongodb.dart'; // Import the MongoDB database logic
import 'activity.dart';
import 'age.dart';
import 'gender.dart';
import 'goal.dart';
import 'height.dart';
import 'signup.dart'; // Import the signup screen
import 'onboarding4.dart'; // Import the onboarding4 screen
import 'forgotpassword.dart';
import 'home.dart'; // Import the home screen
import 'dart:convert'; // For encoding and decoding
import 'package:crypto/crypto.dart';

import 'weight.dart'; // For hashing passwords

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to hash the password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Hash the password using SHA-256
    return digest.toString(); // Return the hashed password as a string
  }

Future<void> _handleLogin() async {
  if (_formKey.currentState?.validate() ?? false) {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final hashedPassword = _hashPassword(password);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Always check local database first
      dynamic user = await LocalDatabase.getUserByEmail(email);
      bool isValidLogin = false;

      // Validate credentials locally first
      if (user != null) {
        final storedHash = user['password'];
        isValidLogin = storedHash == hashedPassword;

        // If online, verify with the server
        if (isValidLogin) {
          final connectivityResult = await Connectivity().checkConnectivity();
          final isOnline = connectivityResult != ConnectivityResult.none;

          if (isOnline) {
            try {
              final serverValid = await MongoDBService.signIn(email, hashedPassword);
              if (!serverValid) {
                // If the server rejects, login is invalid
                isValidLogin = false;
              }
            } catch (e) {
              debugPrint('Server validation error: $e');
              // Ignore server error but keep the login as valid from the local database
            }
          }
        }
      }

      Navigator.of(context).pop(); // Dismiss loading dialog

      if (isValidLogin && user != null) {
        // Handle navigation based on missing fields
        if (user['gender'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GenderSelectionScreen(user)),
          );
        } else if (user['age'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AgeSelectorScreen(user)),
          );
        } else if (user['weight'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WeightSelectorScreen(user)),
          );
        } else if (user['height'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HeightSelectorScreen(user)),
          );
        } else if (user['goal'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GoalSelectionScreen(userData: user)),
          );
        } else if (user['activity_level'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PhysicalActivityScreen(userData: user)),
          );
        } else {
          // If all fields are filled, navigate to Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NutritionDashboard(user)),
          );
        }
      } else {
        // Show error message if login failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.1,
                horizontal: screenWidth * 0.05,
              ),
              child: Center(
                child: Container(
                  width: screenWidth * 0.9,
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen4(),
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/Arrow2.png',
                            width: 24,
                            height: 24,
                            semanticLabel: 'Back',
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'Log In',
                            style: TextStyle(
                              color: const Color(0xFFE2F163),
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          Text(
                            'Welcome',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Track your meals and activities with BalanceBite to easily monitor calories and receive personalized health recommendations. Stay on top of your goals with smart insights!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w300,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF74D9EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username or email',
                                style: TextStyle(
                                  fontFamily: 'League Spartan',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF232323),
                                ),
                              ),
                              SizedBox(height: 7),
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  hintText: '',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context)
                                      .requestFocus(_passwordFocus);
                                },
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: 'League Spartan',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF232323),
                                ),
                              ),
                              SizedBox(height: 7),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      semanticLabel: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ForgotPassword(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF232323),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.09),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                                side: const BorderSide(
                                    color: Colors.white, width: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 32),
                            ),
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w300,
                              ),
                              children: [
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(color: Color(0xFFE2F163)),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpPage(),
                                        ),
                                      );
                                    },
                                ),
                              ],
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
        },
      ),
    );
  }
}