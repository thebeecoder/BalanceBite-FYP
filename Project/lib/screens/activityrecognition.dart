import 'dart:async';
import 'dart:math';
import 'package:balancebite/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:intl/intl.dart';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:balancebite/screens/foodrecognition.dart';
import 'package:balancebite/screens/menu.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ActivityRecognitionScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ActivityRecognitionScreen({super.key, this.userData});

  @override
  State<ActivityRecognitionScreen> createState() =>
      _ActivityRecognitionScreenState();
}

class _ActivityRecognitionScreenState extends State<ActivityRecognitionScreen> {
  List<double> _accMagnitudes = [];
  List<double> _gyroValues = [];
  double _lightLevel = 0.0;
  String _predictedActivity = 'Detecting...';
  String _lastActivity = '';
  Map<String, int> _activityDurations = {};
  Map<String, int> _activityGoals = {
    'Running': 300,
    'Walking': 600,
    'Jumping': 180,
    'Sleeping': 28800,
    'Sitting': 1200, // for example, 20 minutes
  };

  // Date filtering related variables
  DateTime _selectedDate = DateTime.now();
  DateTime _filterStartDate = DateTime.now();
  DateTime _filterEndDate = DateTime.now();
  String _filterType = 'Today'; // 'Today', 'Date Range', 'All Time'

  late Timer _processingTimer;
  late Timer _durationTimer;
  int _currentActivityDuration = 0;
  DateTime? _currentActivityStartTime;
  DateTime? _stillStartTime;

  Light? _light;
  StreamSubscription? _lightSubscription;

  // Dark theme colors
  final _darkBackground = Color(0xFF121212);
  final _cardBackground = Color(0xFF1E1E1E);
  final _surfaceColor = Color(0xFF2C2C2C);
  final _primaryTextColor = Colors.white;
  final _secondaryTextColor = Colors.white70;
  double _userWeight = 70.0; // Default weight in kg

  Map<String, dynamic>? _userData;
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  int _selectedIndex = 2; // Activity is the 3rd index (0-based)

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
    _startSensorListeners();
    _processingTimer = Timer.periodic(
      Duration(seconds: 2),
      (_) => _classifyActivity(),
    );
    _durationTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) => _updateCurrentActivityDuration(),
    );
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

  void _startSensorListeners() {
    accelerometerEvents.listen((event) {
      double mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      _accMagnitudes.add(mag);
      if (_accMagnitudes.length > 100) _accMagnitudes.removeAt(0);
    });

    gyroscopeEvents.listen((event) {
      double motion = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      _gyroValues.add(motion);
      if (_gyroValues.length > 100) _gyroValues.removeAt(0);
    });

    _initializeLightSensor();
  }

  void _initializeLightSensor() {
    try {
      _light = Light();
      _lightSubscription = _light?.lightSensorStream.listen((int luxValue) {
        setState(() {
          _lightLevel = luxValue.toDouble();
        });
      });
    } catch (e) {
      print('Error initializing light sensor: $e');
      setState(() {
        _lightLevel = -1.0;
      });
    }
  }

  void _updateCurrentActivityDuration() {
    if (_currentActivityStartTime != null) {
      setState(() {
        _currentActivityDuration =
            DateTime.now().difference(_currentActivityStartTime!).inSeconds;
      });
    }
  }

  void _classifyActivity() {
    if (_accMagnitudes.length < 10 || _gyroValues.length < 10) return;

    double avgAcc =
        _accMagnitudes.reduce((a, b) => a + b) / _accMagnitudes.length;
    double varAcc =
        _accMagnitudes
            .map((e) => pow(e - avgAcc, 2).toDouble())
            .reduce((a, b) => a + b) /
        _accMagnitudes.length;
    double avgGyro = _gyroValues.reduce((a, b) => a + b) / _gyroValues.length;

    String activity;
    bool isStill = varAcc < 0.01 && avgGyro < 0.3;

    if (isStill) {
      _stillStartTime ??= DateTime.now();
      int stillDuration = DateTime.now().difference(_stillStartTime!).inSeconds;

      if (_lightLevel < 10 && stillDuration > 60) {
        activity = 'Sleeping';
      } else {
        activity = 'Sitting';
      }
    } else {
      _stillStartTime = null;

      if (avgAcc > 18 && varAcc > 8.0 && avgGyro > 0.5) {
        activity = 'Jumping';
      } else if (avgAcc > 13 && avgGyro > 1.5 && varAcc > 3.0 && varAcc < 8.0) {
        activity = 'Running';
      } else if (avgAcc > 9.5 && varAcc > 1.0 && avgAcc < 13) {
        activity = 'Walking';
      } else {
        activity = 'Sitting';
      }
    }

    setState(() {
      _predictedActivity = activity;
    });
  }

  void _updateProfile(Map<String, dynamic> updatedData) {
  setState(() {
    _userData = updatedData;
  });

  // Assuming that LocalDatabase.updateUser is the function to update user info in the local database
  if (updatedData['_id'] != null) {
    // Pass both the original data (userData) and updated data (updatedData)
    LocalDatabase.updateUser(_userData!, updatedData);  // <-- Pass both _userData and updatedData
  }
}


  @override
  void dispose() {
    _processingTimer.cancel();
    _durationTimer.cancel();
    _lightSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF212020),
      drawer: MenuDrawer(userData: _userData, onProfileUpdated: _updateProfile),
      body: Column(
        children: [
          // Header Section
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Row(
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
          ),
          const SizedBox(height: 16),

          // Activity Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Your Activity Data Widgets here
                ],
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
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF74D9EA),
          unselectedItemColor: Colors.white54,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
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
              icon: ImageIcon(AssetImage('assets/activity.png')),
              activeIcon: ImageIcon(
                AssetImage('assets/activity.png'),
                color: Color(0xFF74D9EA),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/recommendation.png')),
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
