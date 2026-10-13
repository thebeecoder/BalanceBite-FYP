import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalDatabase {
  // Box names and UUID initialization
  static const String _usersBox = 'users';
  static const String _foodItemsBox = 'food_items';
  static const String _bmiClassificationsBox = 'bmi_classifications';
  static const String _syncQueueBox = 'sync_queue';
  static const String _pendingFoodDiaryBox = 'pending_food_diary';
  static const Uuid uuid = Uuid();
  static const String syncQueueBoxName = '_syncQueueBox';

  // Hive initialization
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<Map>(_foodItemsBox);
    await Hive.openBox<Map>(_bmiClassificationsBox);
    await Hive.openBox<Map>(_syncQueueBox);
    await Hive.openBox<Map>(_pendingFoodDiaryBox);

    // Initialize users.json if it doesn't exist
    final jsonFile = await _usersJsonFile;
    if (!await jsonFile.exists()) {
      await jsonFile.writeAsString('[]');
    }
  }

  // JSON file handling
static Future<File> get _usersJsonFile async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/users.json';
  debugPrint('Users JSON file path: $path'); // Debugging the file path
  return File(path);
}

static Future<void> _saveJsonUsers(List<Map<String, dynamic>> users) async {
  try {
    final file = await _usersJsonFile;
    // Write the JSON data to the file
    await file.writeAsString(json.encode(users));
    debugPrint('Users saved to JSON: $users');  // Debug print to confirm data is saved
  } catch (e) {
    debugPrint('Error saving users.json: $e');
  }
}


  static Future<List<Map<String, dynamic>>> _loadJsonUsers() async {
    try {
      final file = await _usersJsonFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return List<Map<String, dynamic>>.from(json.decode(contents));
      }
    } catch (e) {
      debugPrint('Error loading users.json: $e');
    }
    return [];
  }

  // User operations
  static Box<Map> get _users => Hive.box<Map>(_usersBox);

  static Future<void> insertUser(Map<String, dynamic> userData) async {
    final email = userData['email'].toString().toLowerCase();
    
    if (_users.containsKey(email)) {
      throw Exception("Email already exists in Hive.");
    }

    final jsonUsers = await _loadJsonUsers();
    if (jsonUsers.any((u) => u['email'].toString().toLowerCase() == email)) {
      throw Exception("Email already exists in JSON.");
    }
    debugPrint('JSON Users: $jsonUsers'); 

    await _users.put(email, userData);
    jsonUsers.add(userData);
    await _saveJsonUsers(jsonUsers);
    await _queueSyncOperation('insertUser', userData);
  }

  static Future<bool> doesEmailExist(String email) async {
    email = email.toLowerCase();
    if (_users.containsKey(email)) return true;
    final jsonUsers = await _loadJsonUsers();
    return jsonUsers.any((u) => u['email'].toString().toLowerCase() == email);
  }

static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
  final box = _users; // Use the pre-opened box
  try {
    // Check Hive box first
    Map<dynamic, dynamic>? hiveUser;
    for (final user in box.values) {
      final userEmail = user['email']?.toString().toLowerCase();
      if (userEmail == email.toLowerCase()) {
        hiveUser = user;
        break;
      }
    }

    // Return Hive user if found
    if (hiveUser != null) {
      return Map<String, dynamic>.from(hiveUser);
    }

    // Fallback to JSON users
    final jsonUsers = await _loadJsonUsers();
    for (final user in jsonUsers) {
      final userEmail = user['email']?.toString().toLowerCase();
      if (userEmail == email.toLowerCase()) {
        return user;
      }
    }

    return null; // No user found
  } catch (e) {
    debugPrint('Error in getUserByEmail: $e');
    return null;
  }
}
  // Credential validation
  static Future<bool> validateLocalCredentials(String email, String hashedPassword) async {
    try {
      final user = await getUserByEmail(email);
      return user != null && user['password'] == hashedPassword;
    } catch (e) {
      debugPrint('Local credential validation error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
  try {
    // Convert to list for safe iteration
    final allUsers = _users.values.toList();
    
    // Find matching user with type safety
    final matchingUsers = allUsers.where(
      (user) => user['_id']?.toString() == userId
    );

    if (matchingUsers.isNotEmpty) {
      return Map<String, dynamic>.from(matchingUsers.first);
    }

    // Check JSON storage as fallback
    final jsonUsers = await _loadJsonUsers();
    final jsonMatch = jsonUsers.where(
      (u) => u['_id']?.toString() == userId
    );
    
    return jsonMatch.isNotEmpty 
        ? Map<String, dynamic>.from(jsonMatch.first)
        : null;
  } catch (e) {
    debugPrint('Error in getUserById: $e');
    return null;
  }
}

  // Update operations
  static Future<void> _updateUserField(
    String userId, 
    String field, 
    dynamic value,
    String operationType
  ) async {
    final user = await getUserById(userId);
    if (user == null) throw Exception("User not found");
    
    final updatedUser = Map<String, dynamic>.from(user);
    updatedUser[field] = value;
    updatedUser['isSynced'] = false;
    updatedUser['lastUpdated'] = DateTime.now().toIso8601String();

    final email = updatedUser['email'].toString().toLowerCase();
    await _users.put(email, updatedUser);
    await _queueSyncOperation(operationType, {
      'userId': userId,
      field: value,
      'timestamp': updatedUser['lastUpdated']
    });

    final jsonUsers = await _loadJsonUsers();
    final index = jsonUsers.indexWhere((u) => u['_id'] == userId);
    if (index != -1) {
      jsonUsers[index] = updatedUser;
      await _saveJsonUsers(jsonUsers);
    }
  }

  // Full user update
  // Modify updateUser to accept Map<String, dynamic> instead of Map<String, Object>
static Future<void> updateUser(Map<String, dynamic> userData, Map<String, dynamic> updatedData) async {
  final userId = userData['_id'];
  final email = userData['email'].toString().toLowerCase();

  await _users.put(email, userData);

  final jsonUsers = await _loadJsonUsers();
  final index = jsonUsers.indexWhere((u) => u['_id'] == userId);
  if (index != -1) {
    jsonUsers[index] = userData;
    await _saveJsonUsers(jsonUsers);
  }

  await _queueSyncOperation('fullUpdate', userData);
}


  // Field-specific updates
  static Future<void> updateUserGender(String userId, String gender) => 
    _updateUserField(userId, 'gender', gender, 'updateUserGender');

  static Future<void> updateUserAge(String userId, int age) => 
    _updateUserField(userId, 'age', age, 'updateUserAge');

  static Future<void> updateUserWeight(String userId, double weight) => 
    _updateUserField(userId, 'weight', weight, 'updateUserWeight');

  static Future<void> updateUserGoals(String userId, List<String> goals) => 
    _updateUserField(userId, 'goal', goals, 'updateUserGoals');

  static Future<void> updateUserActivityLevel(String userId, String activityLevel) => 
    _updateUserField(userId, 'activity_level', activityLevel, 'updateUserActivityLevel');

  // Food diary operations
  static Future<void> addFoodToDiary(String userId, Map<String, dynamic> foodDetails, List<int> imageBytes) async {
    final foodId = uuid.v4();
    final base64Image = base64Encode(imageBytes);
    
    final entry = {
      ...foodDetails,
      'foodId': foodId,
      'image': base64Image,
      'date': DateTime.now().toIso8601String(),
      'userId': userId,
    };
    
    await Hive.box<Map>(_pendingFoodDiaryBox).put(foodId, entry);
    await _queueSyncOperation('addFoodToDiary', {
      'userId': userId,
      'foodDetails': foodDetails,
      'imageBytes': imageBytes,
    });
  }

  // Sync operations
  static Future<void> _queueSyncOperation(String operationType, dynamic data) async {
  await Hive.box<Map>(_syncQueueBox).add({
    'type': operationType,
    'data': data,
    'timestamp': DateTime.now().toIso8601String(),
  });
}


  static List<Map<String, dynamic>> getPendingSyncOperations() {
    return Hive.box<Map>(_syncQueueBox)
        .values
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  static Future<void> clearSyncQueue() async {
    await Hive.box<Map>(_syncQueueBox).clear();
  }

  // Helper methods
  static String _generateRandomToken() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (i) => random.nextInt(256)));
  }

  static Future<void> syncPendingUsers() async {
  try {
    final syncQueue = Hive.box<Map>(syncQueueBoxName);
    final pendingEntries = syncQueue.values.toList();

    for (var i = 0; i < pendingEntries.length; i++) {
      final entry = pendingEntries[i];
      if (entry['type'] == 'insertUser') {
        try {
          await MongoDBService.insertUserDirect(entry['data']);
          
          // Update local record
          final email = entry['data']['email'].toString().toLowerCase();
          await _users.put(email, {
            ...entry['data'],
            'isSynced': true
          });

          // Remove from sync queue using index
          await syncQueue.deleteAt(i);
          i--; // Adjust index after removal
        } catch (e) {
          debugPrint('Sync failed for ${entry['data']['email']}: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Sync error: $e');
  }
}

static Future<void> queuePasswordReset(String email, String token) async {
  await Hive.box<Map>(_syncQueueBox).add({
    'type': 'passwordReset',
    'email': email,
    'token': token,
    'timestamp': DateTime.now().toIso8601String(),
    'status': 'pending'
  });
}

// Add these methods to your LocalDatabase class
static Future<void> saveBMIClassifications(List<Map<String, dynamic>> classifications) async {
  final box = Hive.box<Map>(_bmiClassificationsBox);
  await box.clear();
  for (final entry in classifications) {
    await box.add(entry);
  }
}

static Future<List<Map<String, dynamic>>> getBMIClassifications() async {
  try {
    final box = Hive.box<Map>(_bmiClassificationsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (e) {
    debugPrint('Error getting BMI classifications: $e');
    return [];
  }
}

// Check if the device is connected to the internet
static Future<bool> isConnected() async {
  final connectivityResult = await (Connectivity().checkConnectivity());
  return connectivityResult != ConnectivityResult.none;
}

// Save operations to a sync queue
static Future<void> queueSyncOperation(String operationType, dynamic data) async {
  final syncQueueBox = await Hive.openBox<Map>(_syncQueueBox);
  await syncQueueBox.add({
    'operationType': operationType,
    'data': data,
    'timestamp': DateTime.now().toIso8601String(),
  });
}


}