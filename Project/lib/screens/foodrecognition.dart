import 'dart:convert';
import 'package:balancebite/screens/activityrecognition.dart';
import 'package:balancebite/screens/recommendation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'fooddetail.dart';
import 'package:balancebite/dbHelper/mongodb.dart'; // Import MongoDBService
import 'home.dart';
import 'menu.dart';

class FoodRecognition extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const FoodRecognition({Key? key, this.userData}) : super(key: key);

  @override
  _FoodRecognitionState createState() => _FoodRecognitionState();
}

class _FoodRecognitionState extends State<FoodRecognition> {
  List<Map<String, dynamic>> foodDiary = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFoodDiary();
  }

  Future<void> _fetchFoodDiary() async {
  try {
    final userId = widget.userData?['_id'];
    if (userId != null) {
      print('Fetching food diary for user ID: $userId'); // Debug log
      final diary = await MongoDBService.getFoodDiary(userId);

      // Debug log to check the fetched data
      print('Fetched food diary: $diary');

      // Sort the diary by date in descending order (latest first)
      diary.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA); // Sort in descending order
      });

      setState(() {
        foodDiary = diary;
        isLoading = false;
      });
    } else {
      print('User ID is null'); // Debug log
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching food diary: $e'); // Debug log
    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> _deleteFoodItem(String foodId) async {
    print('Deleting food item with ID: $foodId'); // Debug log
    print('User ID: ${widget.userData?['_id']}'); // Debug log

    if (foodId == null || foodId.isEmpty) {
      print('Error: Food ID is null or empty'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid food ID')),
      );
      return;
    }

    try {
      final userId = widget.userData?['_id'];
      if (userId != null) {
        await MongoDBService.deleteFoodDiaryEntry(userId, foodId);
        // Refresh the food diary after deletion
        await _fetchFoodDiary(); // Fetch the updated food diary from the database
      } else {
        throw Exception('Invalid user ID');
      }
    } catch (e) {
      print('Error deleting food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete food item: $e')),
      );
    }
}

  Future<void> _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodDetail(imagePath: pickedFile.path, userData: widget.userData),
        ),
      );
    }
  }

  Future<void> _openGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodDetail(imagePath: pickedFile.path, userData: widget.userData),
        ),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF212020),
    drawer: MenuDrawer(userData: widget.userData), // Add the MenuDrawer here
    body: Builder(
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu Icon to open the drawer
                    IconButton(
                      icon: Image.asset(
                        'assets/Menu.png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer(); // Open the drawer
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
                const Text(
                  "Food Recognition",
                  style: TextStyle(
                    fontSize: 37,
                    fontFamily: 'Baloo',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openCamera(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF74D9EA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, color: Colors.white, size: 50),
                              SizedBox(height: 8),
                              Text(
                                'Open Camera',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openGallery(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F163),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.upload, color: Colors.black, size: 50),
                              SizedBox(height: 8),
                              Text(
                                'Upload',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  "Daily Nutrition",
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'Baloo',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Display food diary entries
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : foodDiary.isEmpty
                        ? const Text(
                            "No food diary entries found.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            children: foodDiary
                                .where((entry) => entry['foodId'] != null) // Filter out entries with null foodId
                                .map((entry) {
                                  return FoodItem(
                                    name: entry['foodName'],
                                    calories: '${entry['kcal']} kcal',
                                    protein: '${entry['protein']}g',
                                    fats: '${entry['fat']}g',
                                    carbs: '${entry['carbs']}g',
                                    servings: '${entry['servings']}',
                                    image: entry['image'], // Base64 image string
                                    onDelete: () {
                                      _deleteFoodItem(entry['foodId']);
                                    },
                                  );
                                })
                                .toList(),
                          ),
              ],
            ),
          ),
        );
      },
    ),
    bottomNavigationBar: Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF000000), // Background color for the navigation bar
      ),
      child: BottomNavigationBar(
        selectedItemColor: const Color(0xFF74D9EA), // Color for selected item
        unselectedItemColor: Colors.white54, // Color for unselected items
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          // Handle navigation based on the index
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NutritionDashboard(widget.userData)),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodRecognition(userData: widget.userData)),
              );
              break;
            case 2:
              Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActivityRecognitionScreen(userData: widget.userData)),
          );
              break;
            case 3:
              Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecommendationsScreen(userData: widget.userData!)),

              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/home.png'),
              color: Colors.white54, // Default color for unselected icon
            ),
            activeIcon: ImageIcon(
              AssetImage('assets/home.png'),
              color: Colors.white54, // Color for selected icon
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/food.png'),
              color: Color(0xFF74D9EA), // Default color for unselected icon
            ),
            activeIcon: ImageIcon(
              AssetImage('assets/food.png'),
              color: Color(0xFF74D9EA), // Color for selected icon
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/activity.png'),
              color: Colors.white54, // Default color for unselected icon
            ),
            activeIcon: ImageIcon(
              AssetImage('assets/activity.png'),
              color: Color(0xFF74D9EA), // Color for selected icon
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/recommendation.png'),
              color: Colors.white54, // Default color for unselected icon
            ),
            activeIcon: ImageIcon(
              AssetImage('assets/recommendation.png'),
              color: Color(0xFF74D9EA), // Color for selected icon
            ),
            label: '',
          ),
        ],
      ),
    ),
  );
}
}

class FoodItem extends StatelessWidget {
  final String name;
  final String calories;
  final String protein;
  final String fats;
  final String carbs;
  final String servings;
  final String? image; // Base64 image string
  final VoidCallback onDelete;

  const FoodItem({
    Key? key,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fats,
    required this.carbs,
    required this.servings,
    this.image,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (image != null)
                GestureDetector(
                  onTap: () {
                    // Open the image in a larger view
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Image.memory(
                          base64Decode(image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  child: Image.memory(
                    base64Decode(image!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Show a confirmation dialog before deleting
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Record'),
                      content: const Text('Are you sure you want to delete this record?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            onDelete(); // Call the delete function
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            calories,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Servings: $servings',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Protein: $protein',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Text(
                'Fats: $fats',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Text(
                'Carbs: $carbs',
                style: const TextStyle(
                  fontFamily: 'Inter',
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