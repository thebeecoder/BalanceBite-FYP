import 'package:balancebite/screens/activityrecognition.dart';
import 'package:balancebite/screens/foodrecognition.dart';
import 'package:balancebite/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecommendationsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;  // Expecting userData to be passed in the constructor

  const RecommendationsScreen({Key? key, required this.userData}) : super(key: key); // Use required

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}


class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late Map<String, dynamic> _userData; // Declare _userData

  bool isNutritionSelected = true; // Toggle for Nutrition/Exercise
  String timeFilter = "Today"; // Time filter: Today, This Week, This Month
  double intakeProgress = 7500 / 10000; // Example: 7500 / 10000 calories to be consumed
  double burntProgress = 7500 / 10000; // Example: 7500 / 10000 calories burnt

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;  // Assign the passed userData to _userData
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF212020),
      appBar: AppBar(
        title: const Text('Reach Your Goal!'),
        backgroundColor: const Color(0xFF232323),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/Recommendation.png',
              width: 24,
              height: 24,
              color: const Color(0xFFE2F163),
            ),
            onPressed: () {}, // Handle navigation or functionality here
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF74D9EA),
        unselectedItemColor: Colors.white54,
        currentIndex: 0, // Set "Recommendation" tab as selected
        onTap: (index) {
          setState(() {
            // Handle tab selection
            if (index == 0) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => NutritionDashboard(_userData)),);
            } else if (index == 1) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => FoodRecognition(userData: _userData)),);
            } else if (index == 2) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => ActivityRecognitionScreen(userData: _userData)),);
            } else {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => RecommendationsScreen(userData: _userData)));
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/home.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/food.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/activity.png')),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/recommendation.png')),
            label: '',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Recommendations
              const SizedBox(height: 20),
              Text(
                'Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Nutrition and Exercise Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton('Nutrition', isNutritionSelected),
                  SizedBox(width: screenWidth * 0.05),
                  _buildButton('Exercise', !isNutritionSelected),
                ],
              ),

              // Time Filter Buttons (Today, This Week, This Month)
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterButton('Today'),
                  _buildFilterButton('This Week'),
                  _buildFilterButton('This Month'),
                ],
              ),

              // Graph or Progress Bars for Calories Intake and Calories Burnt
              SizedBox(height: screenHeight * 0.04),
              _buildProgressBar('Calories to Intake', intakeProgress),
              SizedBox(height: screenHeight * 0.03),
              _buildProgressBar('Calories to be Burnt', burntProgress),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle buttons for Nutrition and Exercise
  Widget _buildButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isNutritionSelected = label == 'Nutrition';
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF74D9EA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2F163),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : const Color(0xFFE2F163),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Filter buttons for Today, This Week, This Month
  Widget _buildFilterButton(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          timeFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 18),
        decoration: BoxDecoration(
          color: timeFilter == label ? const Color(0xFF74D9EA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: timeFilter == label ? Colors.transparent : const Color(0xFFE2F163),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: timeFilter == label ? Colors.white : const Color(0xFFE2F163),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Progress bar for Calories Intake and Burnt
  Widget _buildProgressBar(String label, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFE2F163)),
        ),
      ],
    );
  }
}
