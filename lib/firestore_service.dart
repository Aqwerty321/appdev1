import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'user_data_service.dart';

/// Firestore service for real-time multi-user data sync
class FirestoreService {
  FirestoreService._();
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _groups => _db.collection('study_groups');

  // Get current user ID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ==================== USER PROFILE ====================

  /// Create or update user profile in Firestore
  Future<void> saveUserProfile(UserData userData) async {
    if (_uid == null) return;

    final data = {
      'name': userData.name,
      'bio': userData.bio,
      'interests': userData.interests.toList(),
      'availability': userData.availability,
      'streakCount': userData.streakCount,
      'lastStreakDay': userData.lastStreakDay,
      'achievements': userData.achievements.toList(),
      'groupLastSeenIso': userData.groupLastSeenIso,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Use merge: true to preserve imageUrl if it exists
    await _users.doc(_uid).set(data, SetOptions(merge: true));
  }

  /// Upload profile image to Firebase Storage and save URL
  Future<String?> uploadProfileImage(Uint8List imageData) async {
    if (_uid == null) return null;

    try {
      final ref = _storage.ref().child('profile_images/$_uid.jpg');
      final uploadTask = await ref.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'cacheControl': 'public, max-age=31536000'},
        ),
      );
      
      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save URL to user document
      await _users.doc(_uid).update({'imageUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Load user profile from Firestore
  Future<UserData?> loadUserProfile() async {
    if (_uid == null) return null;

    try {
      final doc = await _users.doc(_uid).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      
      // Download profile image if URL exists
      Uint8List? imageData;
      final imageUrl = data['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await _storage.refFromURL(imageUrl).getData();
          imageData = response;
        } catch (e) {
          print('Error downloading profile image: $e');
        }
      }

      return UserData(
        name: data['name'] ?? '',
        bio: data['bio'] ?? '',
        imageData: imageData,
        interests: Set<String>.from(data['interests'] ?? []),
        availability: data['availability'] ?? 'open',
        streakCount: data['streakCount'] ?? 0,
        lastStreakDay: data['lastStreakDay'],
        achievements: Set<String>.from(data['achievements'] ?? []),
        groupLastSeenIso: Map<String, String>.from(data['groupLastSeenIso'] ?? {}),
      );
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  /// Stream user profile changes in real-time
  Stream<UserData?> watchUserProfile() {
    if (_uid == null) return Stream.value(null);

    return _users.doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return UserData(
        name: data['name'] ?? '',
        bio: data['bio'] ?? '',
        interests: Set<String>.from(data['interests'] ?? []),
        availability: data['availability'] ?? 'open',
        streakCount: data['streakCount'] ?? 0,
        lastStreakDay: data['lastStreakDay'],
        achievements: Set<String>.from(data['achievements'] ?? []),
        groupLastSeenIso: Map<String, String>.from(data['groupLastSeenIso'] ?? {}),
      );
    });
  }

  /// Stream all users for buddy discovery (excluding current user)
  Stream<List<BuddyProfile>> watchAllUsers() {
    if (_uid == null) return Stream.value([]);

    return _users.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != _uid) // Exclude current user
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['imageUrl'] as String? ?? '';
        return BuddyProfile(
          name: data['name'] ?? 'Unknown',
          imageUrl: imageUrl,
          bio: data['bio'] ?? '',
          interests: Set<String>.from(data['interests'] ?? []),
          matchPercentage: 0, // Calculate match percentage later if needed
        );
      }).toList();
    });
  }

  // ==================== STUDY GROUPS ====================

  /// Create a new study group
  Future<StudyGroup?> createGroup({
    required String name,
    required String description,
    Set<String>? topics,
  }) async {
    if (_uid == null) return null;

    try {
      final userData = UserDataService().currentUser;
      final docRef = _groups.doc();

      final group = StudyGroup(
        id: docRef.id,
        name: name.trim(),
        description: description.trim(),
        topics: topics ?? <String>{},
        memberNames: {userData.name},
        memberUids: {_uid!},
        createdAt: DateTime.now(),
        createdBy: userData.name,
        createdByUid: _uid!,
      );

      await docRef.set({
        'name': group.name,
        'description': group.description,
        'topics': group.topics.toList(),
        'memberNames': group.memberNames.toList(),
        'memberUids': group.memberUids.toList(),
        'admins': [userData.name],
        'adminUids': [_uid],
        'createdAt': Timestamp.fromDate(group.createdAt),
        'createdBy': group.createdBy,
        'createdByUid': _uid,
        'pinnedUrl': null,
      });

      return group;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  /// Join an existing study group
  Future<bool> joinGroup(String groupId) async {
    if (_uid == null) return false;

    try {
      final userData = UserDataService().currentUser;
      await _groups.doc(groupId).update({
        'memberNames': FieldValue.arrayUnion([userData.name]),
        'memberUids': FieldValue.arrayUnion([_uid]),
      });
      return true;
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }

  /// Leave a study group
  Future<bool> leaveGroup(String groupId) async {
    if (_uid == null) return false;

    try {
      final userData = UserDataService().currentUser;
      final docRef = _groups.doc(groupId);
      
      await docRef.update({
        'memberNames': FieldValue.arrayRemove([userData.name]),
        'memberUids': FieldValue.arrayRemove([_uid]),
      });

      // Check if group is empty and delete if so
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      final memberUids = List<String>.from(data?['memberUids'] ?? []);
      if (memberUids.isEmpty) {
        await docRef.delete();
      }

      return true;
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  /// Update group topics (admin only)
  Future<bool> updateGroupTopics(String groupId, Set<String> topics) async {
    if (_uid == null) return false;

    try {
      final groupRef = _groups.doc(groupId);
      final doc = await groupRef.get();
      
      if (!doc.exists) return false;
      
      // Check if user is admin
      final data = doc.data() as Map<String, dynamic>?;
      final admins = List<String>.from(data?['admins'] ?? []);
      final userData = UserDataService().currentUser;
      if (!admins.contains(userData.name)) return false;

      await groupRef.update({
        'topics': topics.toList(),
      });
      return true;
    } catch (e) {
      print('Error updating group topics: $e');
      return false;
    }
  }

  /// Remove a member from group (admin only)
  Future<bool> removeMember(String groupId, String memberName, String memberUid) async {
    if (_uid == null) return false;

    try {
      final groupRef = _groups.doc(groupId);
      final doc = await groupRef.get();
      
      if (!doc.exists) return false;
      
      // Check if user is admin
      final data = doc.data() as Map<String, dynamic>?;
      final admins = List<String>.from(data?['admins'] ?? []);
      final userData = UserDataService().currentUser;
      if (!admins.contains(userData.name)) return false;

      // Don't allow removing yourself or other admins
      if (memberName == userData.name || admins.contains(memberName)) return false;

      await groupRef.update({
        'memberNames': FieldValue.arrayRemove([memberName]),
        'memberUids': FieldValue.arrayRemove([memberUid]),
      });
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  /// Add a member by name or email (admin only)
  Future<bool> addMemberByNameOrEmail(String groupId, String nameOrEmail) async {
    if (_uid == null) return false;

    try {
      final groupRef = _groups.doc(groupId);
      final groupDoc = await groupRef.get();
      
      if (!groupDoc.exists) return false;
      
      // Check if user is admin
      final groupData = groupDoc.data() as Map<String, dynamic>?;
      final admins = List<String>.from(groupData?['admins'] ?? []);
      final userData = UserDataService().currentUser;
      if (!admins.contains(userData.name)) return false;

      // Search for user by name or email
      QuerySnapshot userQuery;
      if (nameOrEmail.contains('@')) {
        // Search by email
        userQuery = await _users.where('email', isEqualTo: nameOrEmail).limit(1).get();
      } else {
        // Search by name
        userQuery = await _users.where('name', isEqualTo: nameOrEmail).limit(1).get();
      }

      if (userQuery.docs.isEmpty) return false;

      final userDoc = userQuery.docs.first;
      final userName = userDoc.data() as Map<String, dynamic>;
      final userUid = userDoc.id;
      final name = userName['name'] ?? '';

      // Check if already a member
      final currentMembers = List<String>.from(groupData?['memberUids'] ?? []);
      if (currentMembers.contains(userUid)) return false;

      // Add to group
      await groupRef.update({
        'memberNames': FieldValue.arrayUnion([name]),
        'memberUids': FieldValue.arrayUnion([userUid]),
      });
      return true;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  /// Promote a member to admin (admin only)
  Future<bool> promoteToAdmin(String groupId, String memberName) async {
    if (_uid == null) return false;

    try {
      final groupRef = _groups.doc(groupId);
      final doc = await groupRef.get();
      
      if (!doc.exists) return false;
      
      // Check if user is admin
      final data = doc.data() as Map<String, dynamic>?;
      final admins = List<String>.from(data?['admins'] ?? []);
      final userData = UserDataService().currentUser;
      if (!admins.contains(userData.name)) return false;

      // Check if member is in the group
      final members = List<String>.from(data?['memberNames'] ?? []);
      if (!members.contains(memberName)) return false;

      await groupRef.update({
        'admins': FieldValue.arrayUnion([memberName]),
      });
      return true;
    } catch (e) {
      print('Error promoting to admin: $e');
      return false;
    }
  }

  /// Stream all study groups the user is a member of
  Stream<List<StudyGroup>> watchMyGroups() {
    if (_uid == null) return Stream.value([]);

    return _groups
        .where('memberUids', arrayContains: _uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StudyGroup(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          topics: Set<String>.from(data['topics'] ?? []),
          memberNames: Set<String>.from(data['memberNames'] ?? []),
          memberUids: Set<String>.from(data['memberUids'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdBy: data['createdBy'] ?? '',
          createdByUid: data['createdByUid'] ?? '',
          pinnedUrl: data['pinnedUrl'],
        )..admins.addAll(List<String>.from(data['admins'] ?? []));
      }).toList();
    });
  }

  /// Stream all available study groups (for discovery)
  Stream<List<StudyGroup>> watchAllGroups() {
    return _groups.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StudyGroup(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          topics: Set<String>.from(data['topics'] ?? []),
          memberNames: Set<String>.from(data['memberNames'] ?? []),
          memberUids: Set<String>.from(data['memberUids'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdBy: data['createdBy'] ?? '',
          createdByUid: data['createdByUid'] ?? '',
          pinnedUrl: data['pinnedUrl'],
        )..admins.addAll(List<String>.from(data['admins'] ?? []));
      }).toList();
    });
  }

  /// Stream a single study group by ID
  Stream<StudyGroup?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return StudyGroup(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        topics: Set<String>.from(data['topics'] ?? []),
        memberNames: Set<String>.from(data['memberNames'] ?? []),
        memberUids: Set<String>.from(data['memberUids'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: data['createdBy'] ?? '',
        createdByUid: data['createdByUid'] ?? '',
        pinnedUrl: data['pinnedUrl'],
      )..admins.addAll(List<String>.from(data['admins'] ?? []));
    });
  }

  // ==================== MESSAGES ====================

  /// Send a message to a study group
  Future<void> sendMessage(String groupId, String content) async {
    if (_uid == null) return;
    if (content.trim().isEmpty) return;

    try {
      final userData = UserDataService().currentUser;
      final messageRef = _groups.doc(groupId).collection('messages').doc();

      await messageRef.set({
        'authorName': userData.name,
        'authorUid': _uid,
        'content': content.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'editedAt': null,
        'reactions': [],
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Edit a message
  Future<bool> editMessage(String groupId, String messageId, String newContent) async {
    if (_uid == null) return false;
    if (newContent.trim().isEmpty) return false;

    try {
      final messageRef = _groups.doc(groupId).collection('messages').doc(messageId);
      final doc = await messageRef.get();
      
      if (!doc.exists) return false;
      if (doc.data()?['authorUid'] != _uid) return false; // Only author can edit

      await messageRef.update({
        'content': newContent.trim(),
        'editedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error editing message: $e');
      return false;
    }
  }

  /// Add a reaction to a message
  Future<void> addReaction(String groupId, String messageId, String emoji) async {
    if (_uid == null) return;

    try {
      final userData = UserDataService().currentUser;
      final messageRef = _groups.doc(groupId).collection('messages').doc(messageId);

      await messageRef.update({
        'reactions': FieldValue.arrayUnion([
          {'userName': userData.name, 'userUid': _uid, 'type': emoji}
        ]),
      });
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }

  /// Remove a reaction from a message
  Future<void> removeReaction(String groupId, String messageId, String emoji) async {
    if (_uid == null) return;

    try {
      final userData = UserDataService().currentUser;
      final messageRef = _groups.doc(groupId).collection('messages').doc(messageId);

      await messageRef.update({
        'reactions': FieldValue.arrayRemove([
          {'userName': userData.name, 'userUid': _uid, 'type': emoji}
        ]),
      });
    } catch (e) {
      print('Error removing reaction: $e');
    }
  }

  /// Toggle reaction (add if not present, remove if present)
  Future<void> toggleReaction(String groupId, String messageId, String emoji) async {
    if (_uid == null) return;

    try {
      final userData = UserDataService().currentUser;
      final messageRef = _groups.doc(groupId).collection('messages').doc(messageId);
      final doc = await messageRef.get();
      
      if (!doc.exists) return;
      
      final reactions = (doc.data()?['reactions'] as List?) ?? [];
      final hasReaction = reactions.any((r) => 
        r['userName'] == userData.name && r['type'] == emoji
      );

      if (hasReaction) {
        await removeReaction(groupId, messageId, emoji);
      } else {
        await addReaction(groupId, messageId, emoji);
      }
    } catch (e) {
      print('Error toggling reaction: $e');
    }
  }

  /// Stream messages for a study group
  Stream<List<StudyGroupMessage>> watchMessages(String groupId) {
    return _groups
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudyGroupMessage(
          id: doc.id,
          authorName: data['authorName'] ?? '',
          authorUid: data['authorUid'] ?? '',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
          reactions: (data['reactions'] as List?)
                  ?.map((r) => MessageReaction(
                        r['userName'] ?? '',
                        r['type'] ?? '',
                      ))
                  .toList() ??
              [],
        );
      }).toList();
    });
  }

  // ==================== SESSIONS ====================

  /// Add a study session to a group
  Future<void> addSession({
    required String groupId,
    required DateTime scheduledAt,
    required String title,
    String? notes,
  }) async {
    if (_uid == null) return;

    try {
      final sessionRef = _groups.doc(groupId).collection('sessions').doc();

      await sessionRef.set({
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'title': title,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': UserDataService().currentUser.name,
        'createdByUid': _uid,
      });
    } catch (e) {
      print('Error adding session: $e');
    }
  }

  /// Stream sessions for a study group
  Stream<List<GroupSession>> watchSessions(String groupId) {
    return _groups
        .doc(groupId)
        .collection('sessions')
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GroupSession(
          id: doc.id,
          scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          title: data['title'] ?? '',
          notes: data['notes'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  /// Update session notes
  Future<void> updateSessionNotes(String groupId, String sessionId, String notes) async {
    if (_uid == null) return;

    try {
      final sessionRef = _groups.doc(groupId).collection('sessions').doc(sessionId);
      await sessionRef.update({
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      });
    } catch (e) {
      print('Error updating session notes: $e');
    }
  }

  /// Set pinned URL for a group (admin only)
  Future<void> setPinnedUrl(String groupId, String? url) async {
    if (_uid == null) return;

    try {
      final groupRef = _groups.doc(groupId);
      final doc = await groupRef.get();
      
      if (!doc.exists) return;
      
      // Check if user is admin
      final data = doc.data() as Map<String, dynamic>?;
      final admins = List<String>.from(data?['admins'] ?? []);
      final userData = UserDataService().currentUser;
      if (!admins.contains(userData.name)) return;

      await groupRef.update({
        'pinnedUrl': (url == null || url.trim().isEmpty) ? null : url.trim(),
      });
    } catch (e) {
      print('Error setting pinned URL: $e');
    }
  }

  // ==================== UTILITIES ====================

  /// Initialize user profile on first login
  Future<void> initializeUserProfile(String name, String email) async {
    if (_uid == null) return;

    try {
      final doc = await _users.doc(_uid).get();
      if (!doc.exists) {
        // Create initial profile
        await _users.doc(_uid).set({
          'name': name,
          'email': email,
          'bio': '',
          'interests': [],
          'availability': 'open',
          'streakCount': 0,
          'lastStreakDay': null,
          'achievements': [],
          'groupLastSeenIso': {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user profile: $e');
    }
  }
}
