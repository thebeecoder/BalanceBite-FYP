import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPassword extends StatelessWidget {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final String token;

  ResetPassword({required this.token});

  Future<Map<String, dynamic>> resetPassword(String token, String password) async {
    final url = Uri.parse('http://your-backend.com/reset-password');
    final response = await http.post(
      url,
      body: {'token': token, 'password': password},
    );

    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm Password'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordController.text != _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                try {
                  await MongoDBService.resetPassword(token, _passwordController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset successfully')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}