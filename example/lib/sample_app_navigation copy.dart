import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/activity_controller.dart';
import 'controllers/navigation_controller.dart';

// Activity callback function type
typedef ActivityUpdateCallback = void Function(String activity);

class SampleAppNavigation extends StatelessWidget {
  final ActivityUpdateCallback? onActivityUpdate;
  
  const SampleAppNavigation({Key? key, this.onActivityUpdate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the ActivityController with the callback
    Get.put(ActivityController(onActivityUpdate: onActivityUpdate));
    
    return GetMaterialApp(
      title: 'Sample Mobile App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(NavigationController());
    final activityController = Get.find<ActivityController>();
    
    // Update activity when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      activityController.updateActivity("Browsing Home");
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Obx(() => _getSelectedPage(navController.selectedIndex.value)),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: navController.selectedIndex.value,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          navController.changeTab(index);
          
          switch (index) {
            case 0:
              activityController.updateActivity("Browsing Home");
              break;
            case 1:
              activityController.updateActivity("Viewing Profile");
              break;
            case 2:
              activityController.updateActivity("Browsing Settings");
              break;
          }
        },
      )),
    );
  }

  Widget _getSelectedPage(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return HomeContent();
      case 1:
        return ProfileScreen();
      case 2:
        return SettingsScreen();
      default:
        return HomeContent();
    }
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When app comes back to foreground, update to browsing home
      final activityController = Get.find<ActivityController>();
      activityController.updateActivity("Browsing Home");
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Featured Cards
          const Text(
            'Featured',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFeatureCard(context, 'Messages', Icons.message, () async {
                  activityController.updateActivity("Viewing Messages");
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen()));
                  // Update activity when returning from Messages
                  activityController.updateActivity("Browsing Home");
                }),
                _buildFeatureCard(context, 'Photos', Icons.photo, () async {
                  activityController.updateActivity("Browsing Photos");
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => PhotosScreen()));
                  // Update activity when returning from Photos
                  activityController.updateActivity("Browsing Home");
                }),
                _buildFeatureCard(context, 'Notes', Icons.note, () async {
                  activityController.updateActivity("Taking Notes");
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen()));
                  // Update activity when returning from Notes
                  activityController.updateActivity("Browsing Home");
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildActionCard('Search', Icons.search, () => activityController.updateActivity("Searching")),
              _buildActionCard('Calendar', Icons.calendar_today, () => activityController.updateActivity("Viewing Calendar")),
              _buildActionCard('Tasks', Icons.task, () => activityController.updateActivity("Managing Tasks")),
              _buildActionCard('Files', Icons.folder, () => activityController.updateActivity("Browsing Files")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'john.doe@example.com',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () async {
              activityController.updateActivity("Editing Profile");
              await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
              // Update activity when returning from Edit Profile
              activityController.updateActivity("Viewing Profile");
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy Settings'),
            onTap: () => activityController.updateActivity("Viewing Privacy Settings"),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () => activityController.updateActivity("Viewing Help"),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Manage notification preferences'),
          onTap: () => activityController.updateActivity("Configuring Notifications"),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Theme'),
          subtitle: const Text('Light/Dark mode'),
          onTap: () => activityController.updateActivity("Changing Theme"),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: const Text('Select app language'),
          onTap: () => activityController.updateActivity("Selecting Language"),
        ),
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Storage'),
          subtitle: const Text('Manage app storage'),
          onTap: () => activityController.updateActivity("Managing Storage"),
        ),
      ],
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = ['Hello!', 'How are you?', 'Good morning!'];

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the build is complete before updating activity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityController = Get.find<ActivityController>();
      activityController.updateActivity("Reading Messages");
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(_messages[index]),
                  onTap: () => activityController.updateActivity("Reading Message"),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => activityController.updateActivity("Typing Message"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    activityController.updateActivity("Sending Message");
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        _messages.add(_messageController.text);
                        _messageController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({Key? key}) : super(key: key);

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityController = Get.find<ActivityController>();
      activityController.updateActivity("Browsing Photos");
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: 15,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => activityController.updateActivity("Viewing Photo ${index + 1}"),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image,
                size: 50,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the build is complete before updating activity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityController = Get.find<ActivityController>();
      activityController.updateActivity("Taking Notes");
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start typing your notes...',
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  if (!_isTyping) {
                    _isTyping = true;
                    // Use addPostFrameCallback to avoid calling during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      activityController.updateActivity("Writing Notes");
                    });
                  }
                  
                  // Reset typing status after a delay
                  _typingTimer?.cancel();
                  _typingTimer = Timer(const Duration(seconds: 2), () {
                    if (mounted) {
                      _isTyping = false;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        activityController.updateActivity("Taking Notes");
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  final TextEditingController _emailController = TextEditingController(text: 'john.doe@example.com');

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the build is complete before updating activity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityController = Get.find<ActivityController>();
      activityController.updateActivity("Editing Profile");
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityController = Get.find<ActivityController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => activityController.updateActivity("Editing Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => activityController.updateActivity("Editing Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                activityController.updateActivity("Saving Profile");
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}