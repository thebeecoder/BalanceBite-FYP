import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'activity.dart';
import 'dart:developer' as developer;

class GoalSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const GoalSelectionScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _GoalSelectionScreenState createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  List<String> _selectedGoals = [];
  bool _isOnline = true;
  bool _isLoading = false;
  final Connectivity _connectivity = Connectivity();
  final List<String> _allGoals = [
    'Lose Weight',
    'Gain Weight',
    'Muscle Mass Gain',
    'Shape Body',
    'Maintain Health',
    'Improve Endurance'
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
    // Initialize with any previously selected goals
    if (widget.userData['goal'] != null) {
      if (widget.userData['goal'] is List) {
        _selectedGoals = List<String>.from(widget.userData['goal']);
      } else {
        _selectedGoals = [widget.userData['goal'].toString()];
      }
    }
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

  Future<void> _handleContinue() async {
  if (_selectedGoals.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one goal')),
    );
    return;
  }

  setState(() => _isLoading = true);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Update user data with selected goals
    final updatedUserData = {
      ...widget.userData,  // Existing user data
      'goal': _selectedGoals,
      'isSynced': _isOnline,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Try online first if available
    if (_isOnline) {
      try {
        await MongoDBService.updateUsergoals(
          updatedUserData['_id'],
          _selectedGoals,
        );
        updatedUserData['isSynced'] = true;
      } catch (e) {
        updatedUserData['isSynced'] = false;
        developer.log('Online goal update failed: $e');
      }
    }

    // Always update local database
    await LocalDatabase.updateUser(widget.userData, updatedUserData); // Pass both userData and updatedData

    Navigator.of(context).pop(); // Remove loading dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhysicalActivityScreen(
          userData: updatedUserData,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline
            ? 'Goals saved successfully!'
            : 'Goals saved successfully!'),
      ),
    );
  } catch (e) {
    Navigator.of(context).pop(); // Remove loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save goals: ${e.toString()}')),
    );
    developer.log('Goal save error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}


  void _toggleGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Semantics(
      label: 'Goal Selection Screen',
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  children: [
                    const CustomBackButton(),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'What Are Your Goals?',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        'Select all that apply to you. Setting clear goals helps us personalize your experience.',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.04),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.03,
                        horizontal: screenWidth * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF74D9EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: _allGoals.map((goal) => 
                          _buildGoalOption(goal)
                        ).toList(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    ContinueButton(
                      isEnabled: _selectedGoals.isNotEmpty,
                      onPressed: _handleContinue,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: GoalOptionCard(
        label: label,
        isSelected: _selectedGoals.contains(label),
        onSelect: () => _toggleGoal(label),
      ),
    );
  }
}

class GoalOptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  const GoalOptionCard({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Select $label as goal',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onSelect,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.02,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF232323),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.09,
                  height: MediaQuery.of(context).size.width * 0.09,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFFE2F163) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE2F163) : const Color(0xFF232323),
                      width: 2,
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

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go back',
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios,
              size: 12,
              color: Color(0xFFE2F163),
            ),
            const SizedBox(width: 9),
            Text(
              'Back',
              style: GoogleFonts.leagueSpartan(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE2F163),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContinueButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const ContinueButton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue to next step',
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 199,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white.withOpacity(isEnabled ? 0.09 : 0.05),
            ),
          ),
          Container(
            width: 199,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isEnabled ? Colors.white : Colors.grey,
                width: 0.5,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? onPressed : null,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 199,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}