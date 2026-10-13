import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'bmi.dart';

class HeightSelectorScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HeightSelectorScreen(this.userData, {Key? key}) : super(key: key);

  @override
  _HeightSelectorScreenState createState() => _HeightSelectorScreenState();
}

class _HeightSelectorScreenState extends State<HeightSelectorScreen> {
  double selectedHeight = 1.65;
  bool isLoading = false;
  bool isHeightSelected = false;
  bool _isOnline = true;
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

  Future<void> _updateHeight() async {
    setState(() => isLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updatedData = {
        ...widget.userData,
        'height': selectedHeight,
        'isSynced': _isOnline,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Try online first if available
      if (_isOnline) {
        try {
          await MongoDBService.updateUserheight(
            widget.userData['_id'],
            selectedHeight.toStringAsFixed(2),
          );
          updatedData['isSynced'] = true;
        } catch (e) {
          updatedData['isSynced'] = false;
          debugPrint('Online height update failed: $e');
        }
      }

      // Always update local database
      await LocalDatabase.updateUser(widget.userData, updatedData);

      Navigator.of(context).pop(); // Remove loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BMIResultScreen(updatedData),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline
              ? 'Height updated successfully!'
              : 'Height updated successfully!'),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update height: ${e.toString()}')),
      );
      debugPrint('Height update error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Color(0xFF232323)),
            child: Column(
              children: [
                _buildHeader(context, width),
                _buildTitleSection(width),
                _buildHeightDisplay(),
                _buildNumberPicker(),
                const Spacer(),
                _buildContinueButton(),
                SizedBox(height: height * 0.05),
              ],
            ),
          ), 
        ],    
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double width) {
    return Padding(
      padding: EdgeInsets.only(top: 60, left: width * 0.08, right: width * 0.08),
      child: Row(
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
      ),
    );
  }

  Widget _buildTitleSection(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: 24),
      child: Column(
        children: [
          Text(
            'What Is Your Height?',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please select your height to personalize your experience.',
            textAlign: TextAlign.center,
            style: GoogleFonts.leagueSpartan(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            selectedHeight.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'm',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.6),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker() {
    final values = List.generate(121, (index) => 1.00 + (index * 0.01));
    final initialIndex = values.indexOf(selectedHeight);

    return SizedBox(
      height: 200,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        diameterRatio: 2.0,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => setState(() {
          selectedHeight = values[index];
          isHeightSelected = true;
        }),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final number = values[index];
            final isSelected = number == selectedHeight;
            return Center(
              child: Text(
                number.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  fontSize: isSelected ? 40 : 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          childCount: values.length,
        ),
        controller: FixedExtentScrollController(initialItem: initialIndex),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: (isLoading || !isHeightSelected) ? null : _updateHeight, 
      child: Container(
        width: 199,
        height: 44,
        decoration: BoxDecoration(
          color: (isLoading || !isHeightSelected) 
              ? Colors.grey 
              : const Color(0xFFE2F163),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Color(0xFF232323))
              : Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF232323),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}