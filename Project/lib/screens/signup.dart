import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'gender.dart';
import 'privacypolicy.dart';
import 'signin.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildBackButton(context),
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildSignUpForm(),
                const SizedBox(height: 30),
                _buildBottomLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        icon: Image.asset('assets/Arrow2.png', width: 24, height: 24),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFFE2F163),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Let's Get Started!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF74D9EA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInputField(
              label: 'Full Name',
              controller: _nameController,
              validator: (value) => value!.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              label: 'Email',
              controller: _emailController,
              validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              label: 'Password',
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              label: 'Confirm Password',
              controller: null,
              isPassword: true,
              isConfirmation: true,
            ),
            const SizedBox(height: 25),
            _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController? controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF232323),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController? controller,
    bool isPassword = false,
    bool isConfirmation = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF232323),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isConfirmation ? _obscureConfirmPassword : _obscurePassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isConfirmation 
                  ? _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility
                  : _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() {
                if (isConfirmation) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              }),
            ),
          ),
          validator: (value) {
            if (isConfirmation) {
              return value != _passwordController.text ? 'Passwords mismatch' : null;
            }
            return value!.length < 6 ? 'Minimum 6 characters' : null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _handleSignUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: const Text(
        'Sign Up',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white),
            children: [
              const TextSpan(text: 'By signing up, you agree to our '),
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(color: Color(0xFFE2F163)),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicy()),
                  ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Login',
                style: const TextStyle(
                  color: Color(0xFFE2F163),
                  fontWeight: FontWeight.bold,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final user = {
      '_id': DateTime.now().millisecondsSinceEpoch.toString(), // Replace with actual unique ID generation logic
      'full_name': _nameController.text,
      'email': _emailController.text,
      'password': _hashPassword(_passwordController.text), // Hash the password
      'gender': null, // To be added in the next page
      'age': null,
      'weight': null,
      'height': null,
      'bmi': null,
      'goal': null,
      'activity_level': null,
      'profileImage': null,
      'classification': null,
      'ideal_range': null,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final existingUsers = await JsonStorage.readUsers();
      final emailExists = existingUsers.any((u) => u['email'] == user['email']);
      
      if (emailExists) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already registered')),
        );
        return;
      }

      await JsonStorage.writeUser(user);
      
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GenderSelectionScreen(user),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    }
  }

  String _hashPassword(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }
}

class JsonStorage {
  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/users.json');
  }

  static Future<List<dynamic>> readUsers() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return jsonDecode(await file.readAsString());
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> writeUser(Map<String, dynamic> user) async {
    final users = await readUsers();
    users.add(user);
    final file = await _localFile;
    await file.writeAsString(jsonEncode(users));
  }
}
