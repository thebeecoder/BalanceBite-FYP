import 'dart:math';
import 'dart:ui';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:balancebite/screens/activity.dart';
import 'package:balancebite/screens/activityrecognition.dart';
import 'package:balancebite/screens/recommendation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'foodrecognition.dart';
import 'package:flutter/material.dart';
import 'menu.dart';

class NutritionDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const NutritionDashboard(this.userData, {Key? key}) : super(key: key);

  @override
  _NutritionDashboardState createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends State<NutritionDashboard> {
  Map<String, dynamic>? _userData;
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
    _loadLocalData();
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
    if (_isOnline) {
      _syncLocalData();
    }
  }

  Future<void> _loadLocalData() async {
    if (_userData == null || _userData!['_id'] == null) return;
    
    try {
      final localUser = await LocalDatabase.getUserById(_userData!['_id']);
      if (localUser != null) {
        setState(() {
          _userData = {
            ...?_userData,
            ...localUser,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  Future<void> _syncLocalData() async {
  try {
    if (_userData != null && _userData!['_id'] != null) {
      final localUser = await LocalDatabase.getUserById(_userData!['_id']);
      if (localUser != null && localUser['isSynced'] == false) {
        // Implement your sync logic here
        final updatedUserData = {
          ...localUser,
          'isSynced': true,
        };
        // Pass both the original data (localUser) and the updated data (updatedUserData)
        await LocalDatabase.updateUser(localUser, updatedUserData); 
      }
    }
  } catch (e) {
    debugPrint('Error syncing data: $e');
  }
}


  void _updateProfile(Map<String, dynamic> updatedData) {
  setState(() {
    _userData = updatedData;
  });

  if (updatedData['_id'] != null) {
    // Pass both user data (original) and updated data (new fields)
    LocalDatabase.updateUser(widget.userData!, updatedData); // <-- Pass both
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final firstName = (_userData?['full_name']?.toString().split(' ') ?? ['User']).first;

    return Scaffold(
      backgroundColor: const Color(0xFF212020),
      drawer: MenuDrawer(userData: _userData, onProfileUpdated: _updateProfile),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              return SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(maxWidth: screenWidth),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Image.asset(
                              'assets/Menu.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                          Image.asset(
                            'assets/logobd.png',
                            width: 120,
                            semanticLabel: 'Nutrition Tracker Logo',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 37,
                            fontFamily: 'Baloo',
                            color: Colors.white,
                          ),
                          children: [
                            const TextSpan(text: 'Hello '),
                            TextSpan(text: '$firstName,'),
                          ],
                        ),
                      ),
                      const Text(
                        "It's time to challenge your limits.",
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 21),
                      ProgressCircle(
                        currentCalories: (_userData?['currentCalories'] ?? 1000).toDouble(),
                        targetCalories: (_userData?['targetCalories'] ?? 1200).toDouble(),
                      ),
                      const SizedBox(height: 5),
                      MacroNutrientsBar(
                        carbs: (_userData?['carbs'] ?? 0).toDouble(),
                        protein: (_userData?['protein'] ?? 0).toDouble(),
                        fat: (_userData?['fat'] ?? 0).toDouble(),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: CalorieChart(
                              title: 'Calories Intake',
                              value: _userData?['caloriesIntake'] ?? 0,
                            ),
                          ),
                          const SizedBox(width: 17),
                          Expanded(
                            child: CalorieChart(
                              title: 'Calories Burnt',
                              value: _userData?['caloriesBurnt'] ?? 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF000000),
        ),
        child: BottomNavigationBar(
          selectedItemColor: const Color(0xFF74D9EA),
          unselectedItemColor: Colors.white54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NutritionDashboard(_userData)),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FoodRecognition(userData: _userData)),
                );
                break;
              case 2:
                Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActivityRecognitionScreen(userData: _userData)),
          );
                break;
              case 3:
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecommendationsScreen(userData: _userData!),
              ),
            );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/home.png')),
              activeIcon: ImageIcon(
                AssetImage('assets/home.png'),
                color: Color(0xFF74D9EA),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/food.png')),
              activeIcon: ImageIcon(AssetImage('assets/food.png')),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/activity.png'),
                color: Colors.white54,
              ),
              activeIcon: ImageIcon(
                AssetImage('assets/activity.png'),
                color: Color(0xFF74D9EA),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/recommendation.png'),
                color: Colors.white54,
              ),
              activeIcon: ImageIcon(
                AssetImage('assets/recommendation.png'),
                color: Color(0xFF74D9EA),
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final radius = size.width / 2;

    var startAngle = 0.0;
    while (startAngle < 2 * pi) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        dashWidth * pi / 180,
        false,
        paint,
      );
      startAngle += (dashWidth + dashSpace) * pi / 180;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ProgressCircle extends StatelessWidget {
  final double currentCalories;
  final double targetCalories;

  const ProgressCircle({
    Key? key,
    required this.currentCalories,
    required this.targetCalories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 78),
      decoration: BoxDecoration(
        color: const Color(0xFF74D9EA),
        borderRadius: BorderRadius.circular(29),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 110),
            painter: DashedCirclePainter(),
          ),
          Container(
            width: 204,
            height: 204,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE2F163),
                width: 19,
              ),
            ),
          ),
          Container(
            width: 166,
            height: 166,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF549D4C),
                width: 5,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Baloo Bhai',
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: '${currentCalories.toStringAsFixed(0)}\n',
                      style: const TextStyle(fontSize: 25),
                    ),
                    const TextSpan(
                      text: 'kcal',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              Text(
                '/${targetCalories.toStringAsFixed(0)} Kcal',
                style: const TextStyle(
                  fontFamily: 'Baloo Bhai',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MacroNutrientsBar extends StatelessWidget {
  final double carbs;
  final double protein;
  final double fat;

  const MacroNutrientsBar({
    Key? key,
    required this.carbs,
    required this.protein,
    required this.fat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 101,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(29),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MacroNutrient(
            label: 'Carbs',
            current: carbs,
            target: 120,
            progress: carbs / 120,
          ),
          MacroNutrient(
            label: 'Protein',
            current: protein,
            target: 70,
            progress: protein / 70,
          ),
          MacroNutrient(
            label: 'Fat',
            current: fat,
            target: 50,
            progress: fat / 50,
          ),
        ],
      ),
    );
  }
}

class MacroNutrient extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final double progress;

  const MacroNutrient({
    Key? key,
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: '${current.toStringAsFixed(0)}\n',
                style: const TextStyle(fontSize: 27),
              ),
              TextSpan(
                text: '/${target.toStringAsFixed(0)}g',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xB3000000),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              width: 80,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            Container(
              width: 80 * progress,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CalorieChart extends StatelessWidget {
  final String title;
  final int value;

  const CalorieChart({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F163),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value kcal',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}