import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:balancebite/dbHelper/local_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class MongoDBService {
  static late Db db;
  static late DbCollection usersCollection;

   static Future<void> connectToDatabase() async {
    try {
      var mongoUri = dotenv.env['MONGO_DB_URI'];
      if (mongoUri == null) throw Exception("MongoDB URI is not set in .env file.");
      db = await Db.create(mongoUri);
      await db.open();
      usersCollection = db.collection('Users');
      // Create a unique index for the email field to prevent duplicates
      await usersCollection.createIndex(keys: {'email': 1}, unique: true);
      print('MongoDB connection established and index created.');
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      rethrow;  
    }
  }

  static Future<void> insertUser(Map<String, dynamic> userData) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      await usersCollection.insert(userData);
    } on MongoDartError catch (e) {
      if (e.message.contains("duplicate key")) {
        throw Exception("Email already exists.");
      }
      
      throw Exception("Failed to insert user: ${e.message}");
    }
  }

  // method to update user's gender
  static Future<void> updateUserGender(String userId, String gender) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      var result = await usersCollection.update(
        where.eq('_id', userId), 
        modify.set('gender', gender)
      );
      if (result['nModified'] == 0) {
        throw Exception("No user found with the provided ID");
      }
    } catch (e) {
      throw Exception("Failed to update gender: $e");
    }
  }

  // method to update user's Age
  static Future<void> updateUserAge(String userId, String age) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      var result = await usersCollection.update(
        where.eq('_id', userId), 
        modify.set('age', age)
      );
      if (result['nModified'] == 0) {
        throw Exception("No user found with the provided ID");
      }
    } catch (e) {
      throw Exception("Failed to update age: $e");
    }
  }

  // method to update user's weight
  static Future<void> updateUserweight(String userId, String weight) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      var result = await usersCollection.update(
        where.eq('_id', userId), 
        modify.set('weight', weight)
      );
      if (result['nModified'] == 0) {
        throw Exception("No user found with the provided ID");
      }
    } catch (e) {
      throw Exception("Failed to update weight: $e");
    }
  }

  // method to update user's height
  static Future<void> updateUserheight(String userId, String height) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      print("Updating height for user: $userId to $height");
      var result = await usersCollection.update(
        where.eq('_id', userId), 
        modify.set('height', height)
      );
      if (result['nModified'] == 0) {
        throw Exception("No user found with the provided ID");
      }
    } catch (e) {
      throw Exception("Failed to update height: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getBMIClassifications() async {
  try {
    final collection = db.collection('bmi_classifications');
    return await collection.find().toList();
  } catch (e) {
    print('Error fetching BMI classifications: $e');
    return [];
  }
  }


  // method to update user's bmi
  static Future<void> updateUserbmi(
  String userId, 
  String bmi, 
  String classification, 
  String idealRange,
) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    print("Updating BMI for user: $userId to $bmi");

    // Update multiple fields using chained .set calls
    var result = await usersCollection.update(
      where.eq('_id', userId), 
      modify
        .set('bmi', bmi) // Set the BMI field
        .set('classification', classification) // Set the classification field
        .set('ideal_range', idealRange), // Set the ideal range field
    );

    if (result['nModified'] == 0) {
      throw Exception("No user found with the provided ID");
    }
  } catch (e) {
    throw Exception("Failed to update BMI: $e");
  }
}
  // method to update user's goal
  static Future<void> updateUsergoals(String userId, List<String> goals) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    var result = await usersCollection.update(
      where.eq('_id', userId), 
      modify.set('goal', goals)
    );
    if (result['nModified'] == 0) {
      throw Exception("No user found with the provided ID");
    }
  } catch (e) {
    throw Exception("Failed to update goals: $e");
  }
}


  // method to update user's activity
  static Future<void> updateUseractivity_level(String userId, String activity_level) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      var result = await usersCollection.update(
        where.eq('_id', userId), 
        modify.set('activity_level', activity_level)
      );
      if (result['nModified'] == 0) {
        throw Exception("No user found with the provided ID");
      }
    } catch (e) {
      throw Exception("Failed to update activity_level: $e");
    }
  }

  

  // method to update user's activity
  static Future<void> updateUsernickname(String userId, String nickname) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      var result = await usersCollection.update(
        where.eq('_id', userId), 
        modify.set('nickname', nickname)
      );
      if (result['nModified'] == 0) {
        throw Exception("No user found with the provided ID");
      }
    } catch (e) {
      throw Exception("Failed to update nickname: $e");
    }
  }

  static Future<bool> doesEmailExist(String email) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    var user = await usersCollection.findOne(where.eq('email', email));
    return user != null;
  } catch (e) {
    throw Exception("Failed to check email: $e");
  }
}

static Future<bool> signIn(String email, String hashedPassword) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    final user = await usersCollection.findOne({
      'email': email,
      'password': hashedPassword, // Ensure it matches the hashed password
    });

    return user != null;
  } catch (e) {
    print("MongoDB SignIn Error: $e");
    return false;
  }
}

static Future<Map<String, dynamic>?> getUserData(String email) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    final user = await usersCollection.findOne({'email': email});
    return user; // This returns the user data from the MongoDB collection
  } catch (e) {
    print("MongoDB getUserData Error: $e");
    return null;
  }
}

static Future<Map<String, dynamic>> fetchFoodInfo(String foodName) async {
  try {
    final collection = db.collection('fooditems'); // Replace 'foods' with your collection name

    // Find the food item in the database that matches the provided food name
    final foodItem = await collection.findOne(where.eq('Food Name', foodName));

    if (foodItem != null) {
      return {
        'kcal': foodItem['Calories'],    // Access the 'Calories' field
        'fat': foodItem['Fats'],         // Access the 'Fats' field
        'carbs': foodItem['Carbs'],      // Access the 'Carbs' field
        'protein': foodItem['Proteins'], // Access the 'Proteins' field
      };
    } else {
      throw Exception('Food item not found');
    }
  } catch (e) {
    print('Error fetching food info: $e');
    rethrow;
  }
}

static Future<void> addFoodToDiary(String userId, Map<String, dynamic> foodDetails, File imageFile) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    // Generate a unique foodId
    final foodId = Uuid().v4(); // Generates a random UUID
    foodDetails['foodId'] = foodId; // Add the foodId to the food details

    // Convert the image file to a base64 string
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Add the base64 image to the food details
    foodDetails['image'] = base64Image;

    // Add the current date and time to the food details
    foodDetails['date'] = DateTime.now().toIso8601String();

    // Insert the food details into the user's food diary
    await usersCollection.update(
      where.eq('_id', userId), // Find the user by their ID
      modify.push('foodDiary', foodDetails), // Add the food details to the 'foodDiary' array
    );

    print('Food added to diary successfully!');
  } catch (e) {
    print('Error adding food to diary: $e');
    rethrow;
  }
}

static Future<List<Map<String, dynamic>>> getFoodDiary(String userId) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    final user = await usersCollection.findOne(where.eq('_id', userId));
    if (user != null && user['foodDiary'] != null) {
      return List<Map<String, dynamic>>.from(user['foodDiary']);
    }
    return []; // Return an empty list if no food diary entries are found
  } catch (e) {
    print('Error fetching food diary: $e');
    rethrow;
  }
}

static Future<void> deleteFoodDiaryEntry(String userId, String foodId) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    // Find the user document
    final user = await usersCollection.findOne(where.eq('_id', userId));
    if (user != null && user['foodDiary'] != null) {
      // Filter out the food diary entry with the given foodId
      final updatedFoodDiary = List<Map<String, dynamic>>.from(user['foodDiary'])
          .where((entry) => entry['foodId'] != foodId)
          .toList();

      // Update the user document with the new foodDiary array
      await usersCollection.update(
        where.eq('_id', userId),
        modify.set('foodDiary', updatedFoodDiary),
      );

      print('Food diary entry deleted successfully'); // Debug log
    } else {
      throw Exception('User or food diary not found');
    }
  } catch (e) {
    print('Error deleting food diary entry: $e');
    rethrow;
  }
}

static Future<void> updateUserProfile(String userId, Map<String, dynamic> updatedData) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  
  try {
    await usersCollection.updateOne(
      where.eq('_id', userId),
      {
        '\$set': updatedData, // Use MongoDB's $set operator to update multiple fields
      },
    );
  } catch (e) {
    print('Error updating user profile: $e');
    rethrow;
  }
}


static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    final user = await usersCollection.findOne(where.eq('_id', userId));
    return user;
  } catch (e) {
    print('Error fetching user profile: $e');
    rethrow;
  }
}

static Future<bool> checkEmailExists(String email) async {
   if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
  // Query the database to check if the email exists
  final collection = db.collection('users');
  final user = await collection.findOne({'email': email});
  return user != null;
   } catch (e) {
    print('Error fetching user profile: $e');
    rethrow;
  }
}

static Future<bool> checkEmail(String email) async {
  if (!db.isConnected) throw Exception("Database connection is not open.");
  try {
    print('Email being checked: $email'); // Debug print
    final normalizedEmail = email.toLowerCase(); // Normalize email to lowercase
    print('Normalized email: $normalizedEmail'); // Debug print

    final collection = db.collection('Users');
    final user = await collection.findOne({'email': normalizedEmail});
    print('User found: $user'); // Debug print
    return user != null;
  } catch (e) {
    print('Error fetching user profile: $e');
    rethrow;
  }
}

static Future<String> generateResetToken(String email) async {
  final user = await usersCollection.findOne({'email': email});
  if (user == null) throw Exception('User not found');
  
  final token = _generateSecureToken(); // Implement token generation
  await usersCollection.updateOne(
    where.eq('email', email),
    modify.set('resetToken', token),
  );
  
  return token;
}

static String _generateSecureToken() {
  final random = Random.secure();
  return base64Url.encode(List<int>.generate(32, (i) => random.nextInt(256)));
}
  static Future<void> resetPassword(String token, String newPassword) async {
    if (!db.isConnected) throw Exception("Database connection is not open.");
    try {
      // Find the user by the reset token and check if the token is still valid
      final user = await usersCollection.findOne(
        where.eq('resetToken', token).gt('resetTokenExpiry', DateTime.now()),
      );

      if (user == null) {
        throw Exception('Invalid or expired token');
      }

      // Update the user's password and clear the reset token
      await usersCollection.update(
        where.eq('_id', user['_id']),
        modify.set('password', newPassword).unset('resetToken').unset('resetTokenExpiry'),
      );

      print('Password reset successfully for user: ${user['email']}');
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  static Future<void> sendResetEmail(String email, String token) async {
    try {
      // Set up the SMTP server (e.g., Gmail)
      final smtpServer = gmail('balancebitefyp@gmail.com', 'ukmq tijk kxfg ttnd');

      // Create the email message
      final resetLink = 'http://balancebite.com/reset-password?token=$token';
      final message = Message()
        ..from = Address('balancebitefyp@gmail.com', 'BalanceBite')
        ..recipients.add(email)
        ..subject = 'Password Reset'
        ..text = 'The given link will expire in 24 hours. Click here to reset your password: $resetLink';

      // Send the email
      await send(message, smtpServer);

      print('Reset email sent to: $email');
    } catch (e) {
      print('Error sending reset email: $e');
      rethrow;
    }
  }

  static Future<bool> checktheEmailExists(String email) async {
    try {
      // Check MongoDB first
      final existsOnline = await usersCollection.findOne({'email': email}) != null;
      if (existsOnline) return true;

      // Fallback to local check if online
      return LocalDatabase.doesEmailExist(email);
    } catch (e) {
      debugPrint('Email check error: $e');
      return LocalDatabase.doesEmailExist(email);
    }
  }

  static Future<void> insertUserDirect(Map<String, dynamic> userData) async {
    try {
      await usersCollection.insertOne(userData);
    } catch (e) {
      debugPrint('Direct insert error: $e');
      throw Exception('Failed to sync user');
    }
  }
}