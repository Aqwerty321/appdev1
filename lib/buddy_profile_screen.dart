// lib/buddy_profile_screen.dart
import 'package:flutter/material.dart';
import 'widgets/neon_border_tile.dart';
import 'widgets/interest_chip.dart';
import 'globals.dart'; // ✅ 1. Import your globals file
import 'search_results_screen.dart';

class BuddyProfileScreen extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String bio;
  final int matchPercentage;
  final Set<String>? interests;

  const BuddyProfileScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.bio,
    required this.matchPercentage,
    this.interests,
  });

  static const Color _darkBlue = Color.fromARGB(255, 19, 35, 63);
  static const Color _neonPurple = Color(0xFF986AF0);
  static const Color _lightBlue = Color.fromARGB(255, 129, 167, 238);

  @override
  Widget build(BuildContext context) {
    // ✅ 2. Wrap the Scaffold with the MouseRegion
    return MouseRegion(
      onHover: (event) => globalMousePosition.value = event.position,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(name, style: const TextStyle(color: _lightBlue)),
          backgroundColor: _darkBlue,
          iconTheme: const IconThemeData(color: _lightBlue),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 85,
                    backgroundColor: _neonPurple,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey.shade900,
                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty ? const Icon(Icons.person, size: 80, color: Colors.white30) : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$matchPercentage% Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _lightBlue.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'About',
                    style: TextStyle(
                      color: _neonPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: NeonBorderGradientTile(
                      width: double.infinity,
                      text: bio,
                      textSize: 16,
                      padding: const EdgeInsets.all(20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (interests != null && interests!.isNotEmpty) ...[
                    const Text(
                      'Interests',
                      style: TextStyle(
                        color: _neonPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests!.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchResultsScreen(hashtag: tag),
                              ),
                            );
                          },
                          child: InterestChip(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}