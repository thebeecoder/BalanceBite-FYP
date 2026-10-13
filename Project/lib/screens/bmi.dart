import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'goal.dart';

class BMIResultScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const BMIResultScreen(this.userData, {Key? key}) : super(key: key);

  @override
  _BMIResultScreenState createState() => _BMIResultScreenState();
}

class _BMIResultScreenState extends State<BMIResultScreen> {
  double? height;
  double? weight;
  int? age;
  String? gender;
  bool isLoading = false;
  bool _isOnline = true;
  List<Map<String, dynamic>> bmiClassifications = [];
  String classification = 'Unknown';
  String idealRange = 'Unknown';
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
    _fetchUserData();
    _fetchBMIClassifications();
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    if (results.isNotEmpty) {
      _updateConnectionStatus(results.first);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _fetchUserData() {
    if (widget.userData.isNotEmpty) {
      setState(() {
        height = widget.userData['height']?.toDouble();
        weight = widget.userData['weight']?.toDouble();
        age = widget.userData['age']?.toInt();
        gender = widget.userData['gender'] ?? 'Unknown';
      });
    }
  }

  Future<void> _fetchBMIClassifications() async {
  setState(() => isLoading = true);
  try {
    // Try online first
    if (_isOnline) {
      try {
        bmiClassifications = await MongoDBService.getBMIClassifications();
        await LocalDatabase.saveBMIClassifications(bmiClassifications);
      } catch (e) {
        debugPrint('Online fetch failed: $e');
      }
    }

    // If online failed or offline, try local storage
    if (bmiClassifications.isEmpty) {
      bmiClassifications = await LocalDatabase.getBMIClassifications();
    }

    // Final fallback to asset file
    if (bmiClassifications.isEmpty) {
      bmiClassifications = await _loadAssetBMIClassifications();
    }
  } catch (e) {
    debugPrint('Error fetching BMI classifications: $e');
  } finally {
    setState(() => isLoading = false);
  }
}

Future<List<Map<String, dynamic>>> _loadAssetBMIClassifications() async {
  try {
    final jsonString = await rootBundle.loadString('assets/bmi_classifications.json');
    final jsonData = json.decode(jsonString) as List;
    return jsonData.cast<Map<String, dynamic>>();
  } catch (e) {
    debugPrint('Error loading asset BMI classifications: $e');
    return [];
  }
}


  double _calculateBMI() {
    if (height != null && weight != null && height! > 0) {
      return weight! / (height! * height!);
    }
    return 0.0;
  }

  String _determineAgeGroup() {
    if (age == null) return 'Unknown';
    if (age! < 5) return '0-5 years';
    if (age! <= 19) return '5-19 years';
    if (age! <= 39) return '20-39 years';
    if (age! <= 59) return '40-59 years';
    return '60+ years';
  }

  void _classifyBMI(double bmi) {
  final ageGroup = _determineAgeGroup();
  final userGender = gender ?? 'Unknown';

  classification = 'Unknown';
  idealRange = 'N/A';

  try {
    final validClassifications = bmiClassifications.where((entry) {
      final entryGender = entry['gender'].toString().toLowerCase();
      final entryAgeGroup = entry['ageGroup'].toString();
      final matchesGender = entryGender == userGender.toLowerCase() || 
                          entryGender == 'male/female';
      return entryAgeGroup == ageGroup && matchesGender;
    }).toList();

    for (var category in validClassifications) {
      final range = category['bmiRange'].toString().trim();
      final rangeParts = range.replaceAll(' ', '').split('-');

      if (rangeParts.length == 2) {
        final min = double.tryParse(rangeParts[0]) ?? 0;
        final max = double.tryParse(rangeParts[1]) ?? double.infinity;
        
        if (bmi >= min && bmi <= max) {
          classification = category['classification'].toString();
          break;
        }
      }
    }

    // Find ideal range
    final normalEntry = validClassifications.firstWhere(
      (c) => c['classification'].toString().toLowerCase() == 'normal',
      orElse: () => {'bmiRange': 'N/A'},
    );
    
    idealRange = normalEntry['bmiRange'].toString();
  } catch (e) {
    debugPrint('Classification error: $e');
  }
}

  Future<void> _saveBMIAndNavigate(double bmi, BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updatedData = {
        ...widget.userData,
        'bmi': bmi.toStringAsFixed(2),
        'classification': classification,
        'ideal_range': idealRange,
        'isSynced': _isOnline,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Try online first if available
      if (_isOnline) {
        try {
          await MongoDBService.updateUserbmi(
            widget.userData['_id'].toString(), 
            bmi.toStringAsFixed(2),
            classification,
            idealRange,
          );
          updatedData['isSynced'] = true;
        } catch (e) {
          updatedData['isSynced'] = false;
          debugPrint('Online BMI update failed: $e');
        }
      }

      // Always update local database
      await LocalDatabase.updateUser(widget.userData, updatedData);

      Navigator.of(context).pop(); // Remove loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoalSelectionScreen(userData: updatedData),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline
              ? 'BMI results saved successfully!'
              : 'Saved offline. Will sync when connection is available.'),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save results: ${e.toString()}')),
      );
      debugPrint('BMI save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF232323),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE2F163)),
        ),
      );
    }

    if (height == null || weight == null || age == null || gender == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF232323),
        body: Center(
          child: Text(
            "Missing user data!",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final bmi = _calculateBMI();
    _classifyBMI(bmi);

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                children: [
                  _buildHeader(context),
                  SizedBox(height: screenHeight * 0.03),
                  _buildTitleSection(),
                  SizedBox(height: screenHeight * 0.05),
                  _buildBmiCard(bmi),
                  SizedBox(height: screenHeight * 0.06),
                  _buildIdealRangeCard(),
                  const Spacer(),
                  _buildContinueButton(context, bmi),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
          if (!_isOnline)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              Image.asset('assets/Arrow2.png', width: 16, height: 16),
              const SizedBox(width: 8),
              Text(
                'Back',
                style: GoogleFonts.leagueSpartan(
                  color: const Color(0xFFE2F163),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Body Mass Index',
          style: GoogleFonts.leagueSpartan(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Your BMI classification based on your height and weight',
          textAlign: TextAlign.center,
          style: GoogleFonts.leagueSpartan(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildBmiCard(double bmi) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF74D9EA),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'Your BMI',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF232323),
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          bmi.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF74D9EA).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            classification.toUpperCase(),
            style: GoogleFonts.leagueSpartan(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF74D9EA),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdealRangeCard() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'Ideal Range',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF232323),
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          idealRange,
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, double bmi) {
    return GestureDetector(
      onTap: () => _saveBMIAndNavigate(bmi, context),
      child: Container(
        width: 199,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE2F163),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            'Continue',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}