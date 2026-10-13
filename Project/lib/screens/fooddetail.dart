import 'package:balancebite/dbHelper/mongodb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:io';
import 'package:image/image.dart' as img; 
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'foodrecognition.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class FoodDetail extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String imagePath;

  const FoodDetail({Key? key, required this.imagePath, required this.userData}) : super(key: key);

  @override
  _FoodDetailState createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  int servings = 1;
  String selectedFood = 'None';
  Map<String, dynamic> foodInfo = {
    'kcal': 0,
    'fat': 0,
    'carbs': 0,
    'protein': 0,
  };
  List<String> foodOptions = ['---'];
  bool isLoading = true;
  img.Image? fullImage;

  @override
  void initState() {
    super.initState();
    foodOptions = ['None'];
    predictFoodOptions().then((_) {
      if (foodOptions.isNotEmpty && foodOptions[0] != 'None') {
        fetchFoodInfo(foodOptions[0]);
      }
    });
  }

  Future<void> loadFullImage() async {
    try {
      final imageFile = File(widget.imagePath);
      final compressedFile = await compressImage(imageFile);  
      final imageBytes = await compressedFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      setState(() {
        fullImage = image;
      });
    } catch (e) {
      print('Error loading full image: $e');
    }
  }

  Future<void> predictFoodOptions() async {
    try {
      final predictions = await predictFood(widget.imagePath);
      setState(() {
        foodOptions = predictions.isNotEmpty ? predictions : ['None'];
        selectedFood = foodOptions[0];
        isLoading = false;
      });
    } catch (e) {
      print('Error during prediction: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<String>> predictFood(String imagePath) async {
  try {
    // Load the image from the file
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes)!;
    
    // Preprocess the image
    final inputData = preprocessImage(image);

    // Initialize the ONNX runtime environment
    OrtEnv.instance.init();

    // Load the ONNX model from assets
    final rawAssetFile = await rootBundle.load('assets/model.onnx');
    final bytes = rawAssetFile.buffer.asUint8List();

    // Create the session for running the model
    final sessionOptions = OrtSessionOptions();
    final session = OrtSession.fromBuffer(bytes, sessionOptions);

    // Prepare the input tensor for the model
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(inputData),
      [1, 3, 224, 224], // Shape of the input tensor (batch_size, channels, height, width)
    );

    final inputs = {'input': inputTensor};
    final runOptions = OrtRunOptions();

    // Run the model to get predictions
    final outputs = await session.run(runOptions, inputs);
    final outputTensor = outputs.first!.value as List<List<double>>;
    final flattenedOutput = outputTensor.expand((element) => element).toList();

    // Log the output to debug
    print("Model output (flattened): $flattenedOutput");

    // Get top predictions from the model output
    final topPredictions = getTopPredictions(flattenedOutput, 4);

    // Release resources after running the model
    inputTensor.release();
    runOptions.release();
    for (var tensor in outputs) {
      tensor!.release();
    }
    session.release();
    OrtEnv.instance.release();

    return topPredictions;
  } catch (e) {
    print('Error during inference: $e');
    return [];
  }
}



Float32List preprocessImage(img.Image image) {
  final inputData = Float32List(224 * 224 * 3);
  int index = 0;

  // Resize the image to 224x224
  final resizedImage = img.copyResize(image, width: 224, height: 224);

  // Normalize the pixel values (mean and std values from your model)
  final mean = [0.485, 0.456, 0.406]; // ImageNet Mean (Red, Green, Blue)
  final std = [0.229, 0.224, 0.225]; // ImageNet Std (Red, Green, Blue)

  // Normalize each pixel to the range [0, 1], subtract mean, and divide by std
  for (var y = 0; y < resizedImage.height; y++) {
    for (var x = 0; x < resizedImage.width; x++) {
      final pixel = resizedImage.getPixel(x, y);
      // Normalize the RGB values (subtract mean and divide by std)
      inputData[index++] = (img.getRed(pixel) / 255.0 - mean[0]) / std[0]; // Red channel
      inputData[index++] = (img.getGreen(pixel) / 255.0 - mean[1]) / std[1]; // Green channel
      inputData[index++] = (img.getBlue(pixel) / 255.0 - mean[2]) / std[2]; // Blue channel
    }
  }

  return inputData;
}


List<String> getTopPredictions(List<double> outputTensor, int topN) {
  // List of food labels (same as used in training the model)
  final foodLabels = [
    'Afghani Pulao', 'Almond Milk', 'Aloo Curry', 'Aloo Gosht', 'Aloo Bukhara', 'Alucha', 'Amlok', 
    'Amrood', 'Anar', 'Apple', 'Apricot', 'Banana', 'Banana Shake', 'Beef Burger', 'Beef Korma', 
    'Besan Ladoo', 'Black Berry', 'Carbonated Beverages', 'Chana Daal With Ghee Tarka', 'Chapli Kabab', 
    'Cheese Ball', 'Cheese Garlic Bread', 'Chicken Burger', 'Chicken Malai Boti', 'Chicken Nuggets', 
    'Chicken Sajji With Rice', 'Chicken Shawarma', 'Chicken Strips', 'Chicken Wings', 'Chinese Hotpot', 
    'Chocolate Custard', 'Club Sandwich', 'Coconut Ladoo', 'Coffee Cappucinno', 'Coffee Espresso', 
    'Coffee Iced Latte', 'Coffee Latte', 'Custard', 'Dates', 'Doodh Jalebi', 'Doodh Patti', 
    'Egg Custard', 'Falsa', 'Falsa Juice', 'Fried Rice', 'Fruit Custard', 'Fruit Smoothie', 
    'Gosht', 'Grapes', 'Green Tea', 'Jamun', 'Kalay Chanay', 'Kashmiri Chai', 'Kinno', 
    'Lahori Fried Fish', 'Lasagna With Chicken', 'Lasagna With Meat', 'Lassi', 'Lemon', 
    'Lemon Juice', 'Loaded Fries', 'Low-Fat Custard', 'Lukhnowi Korma', 'Lychee', 'Macaroni', 
    'Malta', 'Mango Juice', 'Mango Ripe', 'Milk Cake', 'Mutton Pulao', 'Naan', 'Narangi', 
    'Nashpati', 'Noodles', 'Papita', 'Paratha Shawarma', 'Pasta', 'Peshawari Karahi', 'Pineapple', 
    'Pizza', 'Protein Shake', 'Rabri', 'Rasgulla', 'Rooh Afza', 'Rusmalai', 'Sajji', 'Sarda', 
    'Shikarpuri Achar', 'Sindhi Kadhi', 'Spaghetti', 'Stawberry', 'Tarbuz', 'Tikka Kabab', 
    'Vanilla Custard', 'Vegetable Jalfrezi', 'Zinger Burger', 'Achari Chicken', 'Akhrot', 
    'Aloo Capsicum', 'Aloo Chaat', 'Aloo Gawar Phali', 'Aloo Gobhi', 'Aloo Ki Bhujia', 
    'Aloo Matar', 'Aloo Methi', 'Aloo Mungray', 'Aloo Paratha', 'Aloo Qeema', 'Aloo Tikki', 
    'Aloo Turai', 'Anda Bhurji', 'Anda Chana', 'Anday Ka Halwa', 'Anday Wala Burger', 'Arbi Sabzi', 
    'Badam', 'Baingan Ka Bharta', 'Banana Kheer', 'Barfi', 'Beef Chili Dry', 'Besan Ka Halwa', 'Bhel Puri', 
    'Bhindi', 'Bhuna Gosht', 'Bihari Kabab', 'Biryani', 'Biscuit', 'Boiled Egg', 'Bun Kebab', 'Butter Chicken', 
    'Chana Daal Halwa', 'Chana Masala', 'Chana_Puri', 'Chapati', 'Chicken Cheese Omelette', 'Chicken Chungay', 
    'Chicken Ginger Curry', 'Chicken Handi', 'Chicken Patties', 'Chicken Sandwiches', 'Chicken Shashlik', 
    'Chicken Yakhni Soup', 'Chilgoza', 'Chinese Spring Rolls', 'Chow Mein', 'Crab', 'Curry Pakora', 
    'Daal Chawal', 'Daal Gosht', 'Daal Mash', 'Dahi Baingan', 'Dahi Bhalla', 'Dahi Papri Chaat', 'Dahi Puri', 
    'Desi Murgh', 'Dhokla', 'Donuts', 'Double Roti', 'Dum Arbi', 'Dum Pukht', 'Dumplings', 'Egg Fried', 'Fafda', 'Falooda', 'Feerni', 'Fish (Khaga)', 'Fish (Promfret)', 'Fish (Roa)', 'Fish (Shanghara)', 'Fish (Soal)', 'Fish (Surmai)', 'Fish Biryani', 'Fish Karahi', 'Fish Pakora', 'Fish Tikka', 'French Toast', 'Fried Aloo', 'Fried Chicken Wings', 'Fried Fish', 'Gobi Manchurian', 'Gobi Paratha', 'Gol Gappay', 'Gola Kabab', 'Gur Wala Parathay', 'Haleem', 'Halwa Gajjar', 'Halwa Puri', 'Halwa Suji', 'Hot And Sour Soup', 'Icecream', 'Idli', 'Jalebi With Rabri', 'Jaleebi', 'Jau Ki Roti', 'Kachori With Chutney', 'Kaddu Ka Halwa', 'Kaju', 'Kaju Katli', 'Karahi', 'Karela Gosht', 'Kat A Kat', 'Keema', 'Keema Paratha', 'Kheer', 'Khopra', 'Khow Suey', 'Khoya', 'Kichri', 'Kofta', 'Kulcha', 'Kulfi', 'Kung Pao Beef', 'Lab E Shireen', 'Lachha Paratha', 'Lahori Chargha', 'Lemon Chicken', 'Lobia', 'Makki Roti', 'Malai Boti', 'Masoor Dal', 'Matar', 'Matar Paneer', 'Mathri', 'Methi Chicken', 'Mint Raita', 'Mithai', 'Mix Sabzi', 'Mooli Paratha', 'Muffin', 'Murgh Makhni', 'Mutton Chops Masala', 'Mutton Handi', 'Namak Paray', 'Nihari', 'Ojri', 'Omelette', 'Pakoras', 'Palak Gosht', 'Palak Paneer', 'Pancakes', 'Paratha', 'Paratha Rolls', 'Paya', 'Peshawari Chapli Kebab', 'Pista', 'Prawn', 'Prawn Karahi', 'Pulao', 'Qorma', 'Raan Roast', 'Raita', 'Rajma Chawal', 'Roghni Naan', 'Saag Paneera', 'Samosa', 'Samosa Chaat', 'Sarson Ka Saag', 'Seekh Kabab', 'Seviyan', 'Shalgam Ki Sabzi', 'Shami Kabab', 'Sheer Khurma', 'Sheermal', 'Sindhi Biryani', 'Siri Paye', 'Sohan Halwa', 'Sonf', 'Soup', 'Supari', 'Sweet And Sour Chicken', 'Tandoori Chicken', 'Tandoori Chicken Wraps', 'Tandoori Fish', 'Tandoori Roti', 'Tikka Boti', 'Tinda Sabzi', 'Trifle', 'Upma', 'Vegetable Pakora', 'Vegetable Spring Rolls', 'White Dalia', 'White Karahi', 'Yogurt', 'Zarda'
  ];

  // Sort the predictions based on the output tensor
  final sortedIndices = List<int>.generate(outputTensor.length, (i) => i)
    ..sort((a, b) => outputTensor[b].compareTo(outputTensor[a]));

  // Return the top N predictions
  return sortedIndices.take(topN).map((index) => foodLabels[index]).toList();
}

  Future<void> fetchFoodInfo(String foodName) async {
    try {
      final data = await MongoDBService.fetchFoodInfo(foodName);
      setState(() {
        foodInfo = {
          'kcal': data['kcal'],
          'fat': data['fat'],
          'carbs': data['carbs'],
          'protein': data['protein'],
        };
      });
    } catch (e) {
      print('Error fetching food info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Food Detail'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(
                      File(widget.imagePath),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selectedFood,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${foodInfo['kcal'] * servings} KCal',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (servings > 1) servings--;
                            });
                          },
                        ),
                        Text(
                          '$servings',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              servings++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButton<String>(
                      value: selectedFood,
                      items: foodOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedFood = newValue!;
                        });
                        fetchFoodInfo(selectedFood);
                      },
                      dropdownColor: const Color(0xFF212020),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nutritional Information',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildNutritionalInfo('KCal', '${foodInfo['kcal'] * servings}'),
                    _buildNutritionalInfo('Fat', '${foodInfo['fat'] * servings}g'),
                    _buildNutritionalInfo('Carbs', '${foodInfo['carbs'] * servings}g'),
                    _buildNutritionalInfo('Protein', '${foodInfo['protein'] * servings}g'),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final foodDetails = {
                              'foodName': selectedFood,
                              'servings': servings,
                              'kcal': foodInfo['kcal'] * servings,
                              'fat': foodInfo['fat'] * servings,
                              'carbs': foodInfo['carbs'] * servings,
                              'protein': foodInfo['protein'] * servings,
                            };

                            final imageFile = File(widget.imagePath);

                            final userId = widget.userData?['_id'];

                            if (userId == null) {
                              throw Exception('User ID or email not found in userData');
                            }

                            await MongoDBService.addFoodToDiary(userId, foodDetails, imageFile);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to food diary')),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodRecognition(userData: widget.userData),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add food to diary: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF74D9EA),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: const Text(
                          'Add to Food Diary',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNutritionalInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<File> compressImage(File file) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      tempFile.absolute.path,
      quality: 50,
    );

    if (result == null) {
      throw Exception('Failed to compress image');
    }

    return File(result.path);
  }
}
