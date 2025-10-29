import 'package:flutter/material.dart';
import 'globals.dart';
import 'user_data_service.dart';
import 'buddy_profile_screen.dart';
import 'widgets/neon_border_tile.dart';
import 'widgets/interest_chip.dart';
import 'firestore_service.dart';

class SearchResultsScreen extends StatelessWidget {
  final String hashtag;
  SearchResultsScreen({super.key, required this.hashtag});

  final UserDataService _service = UserDataService();

  static const Color _darkBlue = Color.fromARGB(255, 19, 35, 63);
  static const Color _lightBlue = Color.fromARGB(255, 129, 167, 238);

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    return StreamBuilder<List<BuddyProfile>>(
      stream: _firestoreService.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allUsers = snapshot.data!;
        // Filter by hashtag and exclude current user
        final results = allUsers
            .where((p) => p.interests.map((e) => e.toLowerCase()).contains(hashtag.toLowerCase().replaceAll('#', '').trim()))
            .where((p) => p.name != _service.currentUser.name)
            .toList();
        return MouseRegion(
          onHover: (event) => globalMousePosition.value = event.position,
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: Text('#$hashtag', style: const TextStyle(color: _lightBlue)),
              backgroundColor: _darkBlue,
              iconTheme: const IconThemeData(color: _lightBlue),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final p = results[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BuddyProfileScreen(
                          name: p.name,
                          imageUrl: p.imageUrl,
                          bio: p.bio,
                          matchPercentage: p.matchPercentage,
                          interests: p.interests,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: NeonBorderGradientTile(
                      height: 120,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(p.imageUrl),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, height: 1.3),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: p.interests.take(5).map((t) => GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SearchResultsScreen(hashtag: t),
                                        ),
                                      );
                                    },
                                    child: InterestChip(t, compact: true),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${p.matchPercentage}%',
                            style: const TextStyle(color: _lightBlue, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
