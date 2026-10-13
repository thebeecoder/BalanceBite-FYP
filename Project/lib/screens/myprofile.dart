import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:balancebite/dbHelper/local_database.dart'; // Added local database for offline functionality
import 'package:crypto/crypto.dart';
import 'dart:convert';

class MyProfile extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const MyProfile({Key? key, required this.userData}) : super(key: key);

  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _bmiController;
  late TextEditingController _passwordController;
  bool _isLoading = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _bmiController = TextEditingController();
    _passwordController = TextEditingController();
    _initializeProfileData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bmiController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _initializeProfileData() {
    if (widget.userData != null) {
      setState(() {
        _fullNameController.text = widget.userData!['full_name'];
        _emailController.text = widget.userData!['email'];
        _ageController.text = widget.userData!['age']?.toString() ?? 'Not Selected';
        _weightController.text = widget.userData!['weight']?.toString() ?? 'Not Selected';
        _heightController.text = widget.userData!['height']?.toString() ?? 'Not Selected';
        _calculateBMI();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;

    if (weight > 0 && height > 0) {
      final bmi = weight / (height * height);
      _bmiController.text = bmi.toStringAsFixed(2);
    } else {
      _bmiController.text = '0.00';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final hashedPassword = _passwordController.text.isNotEmpty
            ? _hashPassword(_passwordController.text)
            : null;

        final updatedData = {
          'full_name': _fullNameController.text,
          'email': _emailController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'bmi': double.tryParse(_bmiController.text) ?? 0,
          if (hashedPassword != null) 'password': hashedPassword,
          if (_profileImage != null) 'profileImage': _profileImage!.path,
        };

        // Check if online
        bool isOnline = await LocalDatabase.isConnected();
        if (isOnline) {
          await MongoDBService.updateUserProfile(widget.userData!['_id'], updatedData);
          setState(() {
            widget.userData!['full_name'] = updatedData['full_name'];
            widget.userData!['email'] = updatedData['email'];
            widget.userData!['age'] = updatedData['age'];
            widget.userData!['weight'] = updatedData['weight'];
            widget.userData!['height'] = updatedData['height'];
            widget.userData!['bmi'] = updatedData['bmi'];
            if (hashedPassword != null) widget.userData!['password'] = hashedPassword;
            if (_profileImage != null) widget.userData!['profileImage'] = _profileImage!.path;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          // If offline, store the operation in the local database
          await LocalDatabase.updateUser(widget.userData!['_id'], updatedData);
          await LocalDatabase.queueSyncOperation('updateProfile', updatedData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated locally and will be synced later!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF74D9EA),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF212020),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF74D9EA),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? Text(
                                _fullNameController.text.isNotEmpty
                                    ? _fullNameController.text[0]
                                    : 'M',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    // Other form fields go here...
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF74D9EA),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
