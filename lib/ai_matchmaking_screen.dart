import 'package:flutter/material.dart';
import 'ai_matchmaking_service.dart';
import 'user_data_service.dart';
import 'buddy_profile_screen.dart';
import 'widgets/neon_border_tile.dart';
import 'widgets/interest_chip.dart';

/// AI-powered study buddy discovery screen with smart matching
class AiMatchmakingScreen extends StatefulWidget {
  const AiMatchmakingScreen({super.key});

  @override
  State<AiMatchmakingScreen> createState() => _AiMatchmakingScreenState();
}

class _AiMatchmakingScreenState extends State<AiMatchmakingScreen> {
  final AiMatchmakingService _aiService = AiMatchmakingService();
  final UserDataService _userService = UserDataService();
  
  List<AiMatchedBuddy>? _matches;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _findMatches();
  }

  Future<void> _findMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _userService.currentUser;
      
      // Check if user has interests
      if (currentUser.interests.isEmpty) {
        setState(() {
          _error = 'Please add interests to your profile first!\n\nGo to Profile → Edit Profile and add some interests (like #flutter, #webdev, etc.) so the AI can find compatible study buddies for you.';
          _isLoading = false;
        });
        return;
      }

      final matches = await _aiService.findMatches(
        interests: currentUser.interests,
        bio: currentUser.bio,
      );

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3A),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00D9FF), size: 24),
            const SizedBox(width: 8),
            const Text(
              'AI Matchmaking',
              style: TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFB366FF)),
            onPressed: _isLoading ? null : _findMatches,
            tooltip: 'Refresh matches',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00D9FF)),
            SizedBox(height: 16),
            Text(
              '🤖 AI is analyzing profiles...',
              style: TextStyle(color: Color(0xFF00D9FF), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      // Check if error is about missing interests
      final isMissingInterests = _error!.contains('add interests');
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMissingInterests ? Icons.interests : Icons.error_outline,
                color: isMissingInterests ? Color(0xFFFFB800) : Color(0xFFFF2E97),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isMissingInterests ? 'No Interests Yet!' : 'Oops! Something went wrong',
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF81A7EE)),
              ),
              const SizedBox(height: 24),
              if (isMissingInterests)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Go back
                    // User can then navigate to profile
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('Go to Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF94),
                    foregroundColor: Colors.black,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _findMatches,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB366FF),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (_matches == null || _matches!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, color: Color(0xFF81A7EE), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No matches found yet',
              style: TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Try adding more interests to your profile or check back later!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF81A7EE)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _findMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB366FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches!.length,
      itemBuilder: (context, index) {
        final match = _matches![index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(AiMatchedBuddy match) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuddyProfileScreen(
              name: match.name,
              imageUrl: match.imageUrl,
              bio: match.bio,
              matchPercentage: match.matchScore,
              interests: match.interests,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: NeonBorderGradientTile(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header with name and match score
            Row(
              children: [
                // Profile image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getScoreColor(match.matchScore),
                      width: 3,
                    ),
                    image: match.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(match.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: match.imageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: _getScoreColor(match.matchScore),
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name and score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.name,
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: _getScoreColor(match.matchScore),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match.matchScore}% Match',
                            style: TextStyle(
                              color: _getScoreColor(match.matchScore),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // AI-generated match reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0E3E).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFB366FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Color(0xFFFFB800),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.matchReason,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bio
            if (match.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                match.bio,
                style: const TextStyle(
                  color: Color(0xFF81A7EE),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Interests
            if (match.interests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.interests.take(5).map((interest) {
                  return InterestChip(
                    interest,
                    selected: false,
                    clickable: false,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF00FF94); // Success green
    if (score >= 60) return const Color(0xFF00D9FF); // Bright cyan
    return const Color(0xFFB366FF); // Purple
  }
}
