import 'package:cloud_functions/cloud_functions.dart';
import 'user_data_service.dart';

/// AI-powered matchmaking service using Firebase Cloud Functions + Gemini
class AiMatchmakingService {
  AiMatchmakingService._();
  static final AiMatchmakingService _instance = AiMatchmakingService._();
  factory AiMatchmakingService() => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Find AI-matched study buddies based on current user's profile
  /// 
  /// Returns a list of [AiMatchedBuddy] sorted by match score (highest first)
  /// Uses Gemini AI to analyze interests, bios, and compatibility
  Future<List<AiMatchedBuddy>> findMatches({
    required Set<String> interests,
    required String bio,
  }) async {
    try {
      final callable = _functions.httpsCallable('findStudyBuddyMatches');
      
      final result = await callable.call<Map<String, dynamic>>({
        'interests': interests.toList(),
        'bio': bio,
      });

      final matches = result.data['matches'] as List<dynamic>;
      
      return matches.map((m) {
        final match = m as Map<String, dynamic>;
        return AiMatchedBuddy(
          userId: match['userId'] as String,
          name: match['name'] as String,
          bio: match['bio'] as String,
          interests: Set<String>.from(match['interests'] as List),
          imageUrl: match['imageUrl'] as String? ?? '',
          matchScore: (match['matchScore'] as num).toInt(),
          matchReason: match['matchReason'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error fetching AI matches: $e');
      rethrow;
    }
  }

  /// Get AI-generated conversation starters for a specific user
  /// 
  /// Returns 3-5 personalized conversation starter suggestions
  /// based on shared interests and profiles
  Future<List<String>> getConversationStarters(String targetUserId) async {
    try {
      final callable = _functions.httpsCallable('getConversationStarters');
      
      final result = await callable.call<Map<String, dynamic>>({
        'targetUserId': targetUserId,
      });

      final starters = result.data['starters'] as List<dynamic>;
      return starters.cast<String>();
    } catch (e) {
      print('Error fetching conversation starters: $e');
      // Return fallback starters
      return [
        'Hey! Want to study together?',
        'I saw we have similar interests. Let\'s connect!',
        'Looking for a study buddy - interested?',
        'Would love to collaborate on projects!',
      ];
    }
  }
}

/// AI-matched buddy profile with match score and reasoning
class AiMatchedBuddy {
  final String userId;
  final String name;
  final String bio;
  final Set<String> interests;
  final String imageUrl;
  final int matchScore; // 0-100
  final String matchReason; // AI-generated explanation

  AiMatchedBuddy({
    required this.userId,
    required this.name,
    required this.bio,
    required this.interests,
    required this.imageUrl,
    required this.matchScore,
    required this.matchReason,
  });

  /// Convert to BuddyProfile for compatibility with existing UI
  BuddyProfile toBuddyProfile() {
    return BuddyProfile(
      userId: userId,
      name: name,
      imageUrl: imageUrl,
      bio: bio,
      interests: interests,
      matchPercentage: matchScore,
    );
  }
}
