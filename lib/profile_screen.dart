import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'widgets/neon_border_tile.dart';
import 'widgets/interest_chip.dart';
import 'globals.dart';
import 'user_data_service.dart';
import 'search_results_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserDataService _userDataService = UserDataService();
  // ✅ Define your app's color theme
  static const Color _darkBlue = Color.fromARGB(255, 19, 35, 63);
  static const Color _neonPurple = Color(0xFF986AF0);
  static const Color _lightBlue = Color.fromARGB(255, 129, 167, 238);

  Future<void> _navigateToEditScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(
          currentName: _userDataService.currentUser.name,
          currentBio: _userDataService.currentUser.bio,
          currentImageData: _userDataService.currentUser.imageData,
        )
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _userDataService.profileChangedNotifier,
      builder: (context, value, _) {
        final user = _userDataService.currentUser;
        return MouseRegion(
          onHover: (event) => globalMousePosition.value = event.position,
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text('My Profile', style: TextStyle(color: _lightBlue)),
              backgroundColor: _darkBlue,
              iconTheme: const IconThemeData(color: _lightBlue),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 85,
                      backgroundColor: _neonPurple,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.grey.shade900,
                        backgroundImage: user.imageData != null ? MemoryImage(user.imageData!) : null,
                        child: user.imageData == null ? const Icon(Icons.person, size: 80, color: Colors.white30) : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToEditScreen,
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkBlue,
                        foregroundColor: _lightBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        side: const BorderSide(color: _lightBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text('About Me', style: TextStyle(color: _neonPurple, fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: NeonBorderGradientTile(
                          width: double.infinity,
                          text: user.bio,
                          textSize: 16,
                          padding: const EdgeInsets.all(20),
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 47, 43, 108), Color.fromARGB(255, 49, 40, 181)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (user.interests.isNotEmpty) ...[
                      const Text('Interests', style: TextStyle(color: _neonPurple, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.interests.map((tag) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultsScreen(hashtag: tag),
                                ),
                              );
                            },
                            child: InterestChip(tag, compact: false),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}