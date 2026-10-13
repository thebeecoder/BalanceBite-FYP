import 'package:flutter/material.dart';
import 'aboutus.dart'; // Import AboutUs screen
import 'privacypolicy.dart'; // Import PrivacyPolicy screen
import 'myprofile.dart'; // Import MyProfile screen
import 'auth_service.dart';
import 'signin.dart'; // Import your authentication service for logout

class MenuDrawer extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(Map<String, dynamic>)? onProfileUpdated; // Callback for updated data

  const MenuDrawer({
    Key? key,
    this.userData,
    this.onProfileUpdated, // Add the callback
  }) : super(key: key);

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  @override
  void didUpdateWidget(MenuDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userData != widget.userData) {
      setState(() {
        _userData = widget.userData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract user data or display "Not Selected" if no value is available
    final fullName = (_userData?['full_name'] is String && (_userData?['full_name'] as String).isNotEmpty)
        ? _userData!['full_name']
        : 'Not Selected';

    final email = (_userData?['email'] is String && (_userData?['email'] as String).isNotEmpty)
        ? _userData!['email']
        : 'Not Selected';

    final age = _userData?['age'] != null ? _userData!['age'].toString() : 'Not Selected';
    final weight = _userData?['weight'] != null ? _userData!['weight'].toString() : 'Not Selected';
    final height = _userData?['height'] != null ? _userData!['height'].toString() : 'Not Selected';

    final profileImage = _userData?['profileImage']; // URL or base64 string for profile image

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(fullName),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: profileImage != null && profileImage.toString().isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        profileImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      fullName.isNotEmpty ? fullName.substring(0, 1) : 'N',
                      style: const TextStyle(fontSize: 40, color: Colors.black),
                    ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF74D9EA),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.black),
            title: Text(
              'Age: $age',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight, color: Colors.black),
            title: Text(
              'Weight: $weight',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.height, color: Colors.black),
            title: Text(
              'Height: $height',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyProfile(userData: _userData),
                ),
              );
              // Call the callback with the updated data
              if (updatedData != null && widget.onProfileUpdated != null) {
                widget.onProfileUpdated!(updatedData);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.black),
            title: const Text(
              'About Us',
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutUs(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.black),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicy(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              // Call logout function from your authentication service
              await AuthService.logout();

              // Navigate to the login screen and remove all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()), // Replace with your login route
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}