import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'user_data_service.dart';
import 'home.dart';
import 'login_screen.dart';

/// Root widget that determines whether to show login or main app based on auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = false;
  String? _lastInitializedUid;

  Future<void> _initializeUserData(User user) async {
    // Only initialize once per user
    if (_isInitializing || _lastInitializedUid == user.uid) return;
    
    setState(() => _isInitializing = true);

    try {
      // Initialize Firestore profile if first login
      await FirestoreService().initializeUserProfile(
        user.displayName ?? user.email?.split('@').first ?? 'User',
        user.email ?? '',
      );

      // Load profile from Firestore
      final firestoreData = await FirestoreService().loadUserProfile();
      
      if (firestoreData != null) {
        // Update local UserDataService with Firestore data
        final userData = UserDataService().currentUser;
        userData.name = firestoreData.name;
        userData.bio = firestoreData.bio;
        userData.interests.clear();
        userData.interests.addAll(firestoreData.interests);
        userData.availability = firestoreData.availability;
        userData.streakCount = firestoreData.streakCount;
        userData.lastStreakDay = firestoreData.lastStreakDay;
        userData.achievements.clear();
        userData.achievements.addAll(firestoreData.achievements);
      }
      
      // Mark this user as initialized
      _lastInitializedUid = user.uid;
    } catch (e) {
      print('Error initializing user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting || _isInitializing) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81A7EE)),
              ),
            ),
          );
        }

        // Show login if not authenticated
        if (!snapshot.hasData || snapshot.data == null) {
          // Clear initialized user when logged out
          _lastInitializedUid = null;
          return const LoginScreen();
        }

        // Initialize user data on login (only once per user)
        final user = snapshot.data!;
        if (_lastInitializedUid != user.uid) {
          _initializeUserData(user);
        }

        // Show main app if authenticated
        return const HomeScreen();
      },
    );
  }
}
