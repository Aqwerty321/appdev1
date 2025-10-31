/// Central configuration file for StudyBuddy App
/// Modify values here to quickly customize the app during presentations
/// 
/// INSTRUCTIONS:
/// 1. Change colors, text, or feature flags below
/// 2. Save this file
/// 3. Hot reload (press 'r' in terminal or click hot reload button)
/// 4. Changes will apply across the entire app
library;

import 'package:flutter/material.dart';

class AppConfig {
  /// Message when no tags are available
  static const String noTagsAvailableMessage = 'No tags available yet.';
  // ==================== APP INFORMATION ====================
  
  /// App name displayed in UI
  static const String appName = 'StudyBuddy';
  
  /// App tagline/subtitle
  static const String appTagline = 'Find Your Perfect Study Partner';
  
  /// Home screen greeting prefix (e.g., "Good Morning")
  static bool showTimeBasedGreeting = true;
  
  /// Alternative greeting if not using time-based
  static const String staticGreeting = 'Welcome Back';
  
  // ==================== COLORS & THEME ====================
  
  /// Primary background color - Deep rich navy
  static const Color darkBlue = Color(0xFF0A1628);
  
  /// Secondary background color - Slightly lighter navy
  static const Color darkBlueLight = Color(0xFF142844);
  
  /// Accent color 1 (purple/violet for highlights) - Vibrant electric purple
  static const Color neonPurple = Color(0xFFB366FF);
  
  /// Accent color 2 (cyan/blue for buttons, icons) - Bright cyan
  static const Color lightBlue = Color(0xFF00D9FF);
  
  /// Accent color 3 (pink for special highlights) - Electric pink
  static const Color accentPink = Color(0xFFFF2E97);
  
  /// Success/positive color - Vibrant green
  static const Color successGreen = Color(0xFF00FF94);
  
  /// Warning/attention color - Bright amber
  static const Color warningAmber = Color(0xFFFFB800);
  
  /// Text color for primary content - Pure white
  static const Color primaryTextColor = Color(0xFFFFFFFF);
  
  /// Text color for secondary content - Light gray with blue tint
  static const Color secondaryTextColor = Color(0xFFB8C5D6);
  
  /// Card gradient start color - Deep purple
  static const Color cardGradientStart = Color(0xFF1A0E3E);
  
  /// Card gradient end color - Deep blue
  static const Color cardGradientEnd = Color(0xFF0D1B3A);
  
  // ==================== TYPOGRAPHY ====================
  
  /// Main heading font size
  static const double headingFontSize = 48.0;
  
  /// Subheading font size
  static const double subheadingFontSize = 20.0;
  
  /// Body text font size
  static const double bodyFontSize = 16.0;
  
  /// Small text font size
  static const double smallFontSize = 14.0;
  
  // ==================== FEATURE FLAGS ====================
  
  /// Show "Discover Buddies" section on home screen
  static const bool showDiscoverBuddies = true;
  
  /// Show "Find by Interest" section on home screen
  static const bool showFindByInterest = true;
  
  /// Show "My Study Groups" section on home screen
  static const bool showMyStudyGroups = true;
  
  /// Enable profile picture uploads
  static const bool enableProfilePictures = true;
  
  /// Enable study group creation
  static const bool enableGroupCreation = true;
  
  /// Enable messaging in study groups
  static const bool enableGroupMessaging = true;
  
  /// Enable reactions on messages
  static const bool enableMessageReactions = true;
  
  /// Enable session scheduling
  static const bool enableSessionScheduling = true;
  
  /// Show match percentage on buddy cards
  static const bool showMatchPercentage = true;
  
  // ==================== UI CUSTOMIZATION ====================
  
  /// Number of interests to show in "Popular Tags"
  static const int popularTagsCount = 12;
  
  /// Maximum interests a user can add
  static const int maxUserInterests = 20;
  
  /// Profile picture max size (in MB)
  static const int maxProfileImageSizeMB = 5;
  
  /// Buddy card height
  static const double buddyCardHeight = 480.0;
  
  /// Show bio on buddy cards
  static const bool showBioOnCards = true;
  
  /// Maximum bio length (characters)
  static const int maxBioLength = 500;
  
  // ==================== SECTION TITLES & QUOTES ====================
  
  /// Discover Buddies section title
  static const String discoverBuddiesTitle = 'Discover Buddies';
  
  /// Discover Buddies quote
  static const String discoverBuddiesQuote = 
      '"O brave new world, that has such study mates in\'t."';
  
  /// Find by Interest section title
  static const String findByInterestTitle = 'Find by Interest';
  
  /// Find by Interest quote
  static const String findByInterestQuote = 
      '"Our interests be the stars to steer by—seek and ye shall find."';
  
  /// My Study Groups section title
  static const String myStudyGroupsTitle = 'My Study Groups';
  
  /// Study Groups page title
  static const String studyGroupsPageTitle = 'Study Groups';
  
  // ==================== MESSAGES & LABELS ====================
  
  /// Empty state message for no buddies
  static const String noBuddiesMessage = 
      'No buddies found yet. Invite friends to join!';
  
  /// Empty state message for no groups
  static const String noGroupsMessage = 
      'No study groups yet. Create one to get started!';
  
  /// Empty state message for no messages
  static const String noMessagesMessage = 
      'No messages yet. Start the conversation!';
  
  /// Message when no tags selected
  static const String selectTagsMessage = 
      'Select one or more tags to see matching buddies.';
  
  /// Message when no profiles match selected tags
  static const String noMatchingProfilesMessage = 
      'No profiles match the selected tags yet. Try other tags!';
  
  /// Edit profile button text
  static const String editProfileButtonText = 'Edit Profile';
  
  /// Create group button text
  static const String createGroupButtonText = 'Create Study Group';
  
  /// Join group button text
  static const String joinGroupButtonText = 'Join';
  
  /// Leave group button text
  static const String leaveGroupButtonText = 'Leave';
  
  // ==================== ADMIN FEATURES ====================
  
  /// Show admin controls in study groups
  static const bool showAdminControls = true;
  
  /// Admin badge text
  static const String adminBadgeText = 'ADMIN';
  
  /// Member badge text
  static const String memberBadgeText = 'MEMBER';
  
  // ==================== QUICK CUSTOMIZATION PRESETS ====================
  
  /// Apply a preset theme (call this method to switch themes)
  static void applyPreset(String presetName) {
    // You can add preset logic here if needed
    // For now, just modify the constants above manually
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Get gradient for cards
  static LinearGradient getCardGradient() {
    return LinearGradient(
      colors: [cardGradientStart, cardGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  /// Get neon text style
  static TextStyle getNeonTextStyle({
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.bold,
    Color? color,
  }) {
    return TextStyle(
      color: color ?? neonPurple,
      fontSize: fontSize,
      fontWeight: fontWeight,
      shadows: const [
        Shadow(
          blurRadius: 4.0,
          color: Colors.black54,
          offset: Offset(2.0, 2.0),
        ),
      ],
    );
  }
  
  /// Get button style
  static ButtonStyle getButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? darkBlue,
      foregroundColor: lightBlue,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      side: const BorderSide(color: lightBlue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

// ==================== PRESET THEMES ====================
// Uncomment and modify these to quickly switch between different looks

/*
/// Blue Ocean Theme
class BlueOceanPreset {
  static const Color darkBlue = Color(0xFF0A1929);
  static const Color lightBlue = Color(0xFF4FC3F7);
  static const Color neonPurple = Color(0xFF7C4DFF);
}

/// Forest Green Theme
class ForestGreenPreset {
  static const Color darkBlue = Color(0xFF1B5E20);
  static const Color lightBlue = Color(0xFF81C784);
  static const Color neonPurple = Color(0xFFAED581);
}

/// Sunset Orange Theme
class SunsetOrangePreset {
  static const Color darkBlue = Color(0xFF3E2723);
  static const Color lightBlue = Color(0xFFFF7043);
  static const Color neonPurple = Color(0xFFFFB74D);
}
*/
