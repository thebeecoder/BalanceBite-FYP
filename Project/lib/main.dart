import 'dart:async';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:balancebite/screens/launch_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await LocalDatabase.init();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Connect to MongoDB
  await MongoDBService.connectToDatabase();
  
  startSyncService();

  runApp(const MyApp());
}

Future<bool> _isOnline() async {
  final connectivityResult = await (Connectivity().checkConnectivity());
  return connectivityResult != ConnectivityResult.none;
}


void startSyncService() {
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await LocalDatabase.syncPendingUsers();
      await _processQueuedResets();
    }
  });
}

Future<void> _processQueuedResets() async {
  final queue = Hive.box<Map>(LocalDatabase.syncQueueBoxName);
  final keys = queue.keys.toList();

  for (final key in keys) {
    final entry = queue.get(key);
    if (entry != null && 
        entry['type'] == 'passwordReset' && 
        entry['status'] == 'pending') {
      try {
        final email = entry['email']?.toString();
        final token = entry['token']?.toString();
        
        if (email != null && token != null) {
          await MongoDBService.sendResetEmail(email, token);
          await queue.put(key, {...entry, 'status': 'completed'});
        }
      } catch (e) {
        debugPrint('Failed to process reset for key $key: $e');
      }
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BalanceBite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LaunchPage(),
    );
  }
}