import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'age.dart';

class GenderSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const GenderSelectionScreen(this.userData, {Key? key}) : super(key: key);

  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? selectedGender;
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  @override
void initState() {
  super.initState();
  _checkConnectivity();
  _connectivity.onConnectivityChanged.listen((results) {
    // Handle the list of results
    if (results.isNotEmpty) {
      _updateConnectionStatus(results.first); // Take the first result
    }
  });
}

  Future<void> _checkConnectivity() async {
  final results = await _connectivity.checkConnectivity();
  if (results.isNotEmpty) {
    _updateConnectionStatus(results.first); // Take the first result
  }
}

void _updateConnectionStatus(ConnectivityResult result) {
  setState(() {
    _isOnline = result != ConnectivityResult.none;
  });
}

  // Method to update gender in the database
  Future<void> _updateGender() async {
  if (selectedGender == null) return;

  showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

  try {
    final updatedData = {
      ...widget.userData,
      'gender': selectedGender,
      'isSynced': _isOnline,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Try online first if available
    if (_isOnline) {
      try {
        await MongoDBService.updateUserGender(widget.userData['_id'], selectedGender!);
        updatedData['isSynced'] = true;
      } catch (e) {
        updatedData['isSynced'] = false;
        debugPrint('Online update failed: $e');
      }
    }

    // Always update local database
    await LocalDatabase.updateUser(widget.userData, updatedData);

    Navigator.of(context).pop(); // Remove loading
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AgeSelectorScreen(updatedData),
    ));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isOnline 
        ? 'Gender updated successfully!'
        : 'Gender updated successfully!'),
    ));
  } catch (e) {
    Navigator.of(context).pop(); // Remove loading
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Failed to update: ${e.toString()}'),
    ));
    debugPrint('Gender update error: $e');
  }
}

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    backgroundColor: const Color(0xFF232323),
    body: Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 10),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/Arrow2.png',
                                  width: 16,
                                  height: 16,
                                  color: const Color(0xFFE2F163),
                                ),
                                const SizedBox(width: 8),
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
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          "What's Your Gender?",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF74D9EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Please select your gender to help us personalize your experience and tailor recommendations just for you.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w300,
                              color: const Color(0xFF232323),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          GenderOption(
                            icon: 'assets/male_icon.png',
                            label: 'Male',
                            isSelected: selectedGender == 'male',
                            onTap: () => setState(() => selectedGender = 'male'),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          GenderOption(
                            icon: 'assets/female_icon.png',
                            label: 'Female',
                            isSelected: selectedGender == 'female',
                            onTap: () => setState(() => selectedGender = 'female'),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: ElevatedButton(
                          onPressed: selectedGender != null
                              ? () {
                                  _updateGender();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedGender != null
                                ? Colors.white.withOpacity(0.09)
                                : Colors.grey.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: const BorderSide(color: Colors.white, width: 1),
                            ),
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                            minimumSize: Size(screenWidth * 0.8, 50),
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

class GenderOption extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderOption({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Semantics(
      button: true,
      label: '$label gender option',
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFE2F163) : Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: Center(
                child: Image.asset(
                  icon,
                  width: screenWidth * 0.18,
                  height: screenWidth * 0.18,
                  color: isSelected ? const Color(0xFF232323) : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
