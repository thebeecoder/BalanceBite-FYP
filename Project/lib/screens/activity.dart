import 'package:balancebite/dbHelper/local_database.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'home.dart';

class PhysicalActivityScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PhysicalActivityScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _PhysicalActivityScreenState createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> {
  String? _selectedActivity;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Semantics(
      label: 'Physical Activity Level Selection Screen',
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, // 5% of screen width
                vertical: screenHeight * 0.02, // 2% of screen height
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomBackButton(), // Back button at the top-left
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  Center(
                    child: Text(
                      'Physical Activity Level',
                      textAlign: TextAlign.center, // Ensures text stays centered
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Text(
                      "Everyone's fitness journey is unique. Select an activity level that resonates with you, and we'll create a plan tailored to your needs.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035, // Responsive font size
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // 5% of screen height
                  ActivityButton(
                    label: 'Beginner',
                    isSelected: _selectedActivity == 'Beginner',
                    onTap: () => _selectActivity('Beginner'),
                  ),
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  ActivityButton(
                    label: 'Intermediate',
                    isSelected: _selectedActivity == 'Intermediate',
                    onTap: () => _selectActivity('Intermediate'),
                  ),
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  ActivityButton(
                    label: 'Advance',
                    isSelected: _selectedActivity == 'Advance',
                    onTap: () => _selectActivity('Advance'),
                  ),
                  SizedBox(height: screenHeight * 0.1), // 10% of screen height
                  Center(
                    child: ContinueButton(
                      isEnabled: _selectedActivity != null,
                      onPressed: _handleContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectActivity(String activity) {
    setState(() {
      _selectedActivity = activity;
    });
  }

  Future<bool> _isOnline() async {
  // Check network connectivity (use a package like connectivity_plus)
  final connectivityResult = await (Connectivity().checkConnectivity());
  return connectivityResult != ConnectivityResult.none;
}

  void _handleContinue() async {
  if (_selectedActivity == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an activity level')),
    );
    return;
  }

  try {
    // Ensure the userData has an _id, generate locally if missing (offline case)
    final updatedUserData = {
      ...widget.userData,
      'activityLevel': _selectedActivity,
    };

    // Debugging: Print the type and content of updatedUserData
    print('updatedUserData: $updatedUserData');
    print('Type of updatedUserData: ${updatedUserData.runtimeType}');

    // Generate a local _id if it doesn't exist (offline scenario)
    if (!updatedUserData.containsKey('_id') || updatedUserData['_id'] == null) {
      updatedUserData['_id'] = Uuid().v4(); // Ensure uuid package is imported and initialized
    }

    // Ensure updatedUserData is still a Map<String, dynamic>
    if (updatedUserData is! Map<String, dynamic>) {
      throw Exception('User data is not in the expected format');
    }

    // Update the local database with the user data
    await LocalDatabase.updateUser(updatedUserData['_id'], updatedUserData);

    // Sync with MongoDB if online
    if (await _isOnline()) {
      await MongoDBService.updateUseractivity_level(
        updatedUserData['_id'], 
        _selectedActivity!,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionDashboard(updatedUserData),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving activity level: $e')),
    );
  }
}

}

class ActivityButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ActivityButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label activity level',
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.08, // 8% of screen height
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE2F163) : Colors.white,
            borderRadius: BorderRadius.circular(38),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.leagueSpartan(
              color: const Color(0xFF232323),
              fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive font size
              fontWeight: FontWeight.w500,
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
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/Arrow2.png',
              width: 6,
              height: 11,
              semanticLabel: 'Back arrow icon',
            ),
            const SizedBox(width: 9),
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
      label: 'Continue to next screen',
      child: InkWell(
        onTap: isEnabled ? onPressed : null, // Disable onTap if not enabled
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 199,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isEnabled ? 0.09 : 0.05), // Adjust opacity based on enabled state
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Container(
              width: 199,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isEnabled ? Colors.white : Colors.grey, // Adjust border color based on enabled state
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Text(
              'Continue',
              style: GoogleFonts.poppins(
                color: isEnabled ? Colors.white : Colors.grey, // Adjust text color based on enabled state
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}