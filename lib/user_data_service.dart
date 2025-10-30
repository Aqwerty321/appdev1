import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Optional models to support searching and hashtag wall
class BuddyProfile {
  String userId;
  String name;
  String imageUrl;
  String bio;
  int matchPercentage;
  Set<String> interests;
  BuddyProfile({
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.bio,
    required this.matchPercentage,
    required this.interests,
  });
}

class UserData {
  String name;
  String bio;
  Uint8List? imageData;
  Set<String> interests;
  Map<String, String> groupLastSeenIso; // groupId -> last viewed ISO timestamp
  int streakCount;
  String? lastStreakDay; // yyyyMMdd
  Set<String> achievements;
  String availability; // 'open' | 'focus' | 'away'
  UserData({
    required this.name,
    required this.bio,
    this.imageData,
    Set<String>? interests,
    Map<String, String>? groupLastSeenIso,
    int? streakCount,
    this.lastStreakDay,
    Set<String>? achievements,
    String? availability,
  })  : interests = interests ?? <String>{},
        groupLastSeenIso = groupLastSeenIso ?? <String, String>{},
        streakCount = streakCount ?? 0,
        achievements = achievements ?? <String>{},
        availability = availability ?? 'open';
}

// This is a singleton service to hold our user data.
class UserDataService {
  // Private constructor
  UserDataService._internal();

  // The single, static instance of the service
  static final UserDataService _instance = UserDataService._internal();

  // Factory constructor to return the static instance
  factory UserDataService() {
    return _instance;
  }

  // The actual user data with initial default values
  final UserData currentUser = UserData(
    name : 'Aaditya Soni',
    bio : '''I’m Aaditya Soni — a Python and Blender dev 😎 who speaks in game loops and dreams in shader nodes. From procedural Blender landscapes to chaotic Pygame projects and HTML/CSS layouts in python apps and websites that actually center, this channel is my devlog through pixels, logic, and emotional damage 😭.

    Freshman at IIIT Naya Raipur (DSAI ‘29).

    Expect:
    • Funny tutorials where I break things and still make them work
    • Game dev in pygame/unity/unreal + unserious commentary
    • PyQt apps, GeoNodes/ShaderNodes chaos
    • Desmos art and graph dumps
    • Philosophical rambles mid-debug
    • "Rewrote the codebase at 2AM" moments

    Maybe gameplay, maybe AI shenanigans. Who knows?
    Consider Subscribing if you're into devlogs with a fancy flair✌️.'''
    ,
    interests: {
      'python', 'blender', 'gamedev', 'ai', 'music'
    },
    availability: 'open',
  );

  // Demo dataset for buddies and hashtag wall/search.
  // In a real app this would come from your backend/Firestore.
  late final List<BuddyProfile> allProfiles = [
    // Index 0 mirrors the current user; keep in sync on updates
    BuddyProfile(
      userId: 'current-user',
      name: currentUser.name,
      imageUrl: 'https://picsum.photos/seed/me/200',
      bio: currentUser.bio,
      matchPercentage: 98,
      interests: {...currentUser.interests},
    ),
    // Generate 19 more profiles with varied interest frequencies
    ...List<BuddyProfile>.generate(19, (i) {
      final idx = i + 1; // 1..19
      final name = 'Random Buddy #$idx';
      final imageUrl = 'https://picsum.photos/seed/$idx/200';
      final bio = _sampleBios[idx % _sampleBios.length];
      final match = 95 - (idx * 2);
      final interests = _generateInterests(idx);
      return BuddyProfile(
        userId: 'demo-user-$idx',
        name: name,
        imageUrl: imageUrl,
        bio: bio,
        matchPercentage: match.clamp(60, 97),
        interests: interests,
      );
    }),
  ];

  // ---------------- Study Groups ----------------
  // Simple in-memory model for study groups. In a real app this would live in backend/Firestore.
  final List<StudyGroup> _groups = [];

  List<StudyGroup> get allGroups {
    if (_groups.isEmpty) {
      // Lazy seed safeguard (in case a screen forgot to call seedDemoGroups or hot restart cleared state)
      seedDemoGroups();
    }
    return List.unmodifiable(_groups);
  }

  /// Returns groups the current user belongs to.
  List<StudyGroup> get myGroups {
    if (_groups.isEmpty) seedDemoGroups();
    return _groups.where((g) => g.memberNames.contains(currentUser.name)).toList();
  }

  /// Create a new study group. Current user auto-added as a member.
  StudyGroup createGroup({
    required String name,
    required String description,
    Set<String>? topics,
  }) {
    if (_groups.any((g) => g.name.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('A group with that name already exists');
    }
    final group = StudyGroup(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}_${_groups.length}',
      name: name.trim(),
      description: description.trim(),
      topics: topics ?? <String>{},
      memberNames: {currentUser.name},
      createdAt: DateTime.now(),
      createdBy: currentUser.name,
    );
    _groups.add(group);
    _persistGroups();
    return group;
  }

  /// Join a group by id (adds current user if not already present).
  void joinGroup(String groupId) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    g.memberNames.add(currentUser.name);
    _persistGroups();
  }

  /// Leave a group; if empty afterwards, group is removed.
  void leaveGroup(String groupId) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    g.memberNames.remove(currentUser.name);
    if (g.memberNames.isEmpty) {
      _groups.remove(g);
    }
    _persistGroups();
  }

  /// Add a chat style message to a group (must be member)
  void addGroupMessage(String groupId, String content) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    if (!g.memberNames.contains(currentUser.name)) return;
    final msg = StudyGroupMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}_${g.messages.length}',
      authorName: currentUser.name,
      content: content.trim(),
      timestamp: DateTime.now(),
    );
    if (msg.content.isEmpty) return;
    g.messages.add(msg);
    _maybeAwardAchievement('first_message');
    final totalMessages = g.messages.where((m)=> m.authorName == currentUser.name).length;
    if (totalMessages == 10) _maybeAwardAchievement('ten_messages');
    _updateStreakOnMessage();
    _persistGroups();
  }

  bool editGroupMessage(String groupId, String messageId, String newContent) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull; if (g==null) return false;
    final m = g.messages.where((e)=> e.id == messageId).firstOrNull; if (m==null) return false;
    if (m.authorName != currentUser.name) return false; // only author can edit
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) return false;
    m.content = trimmed;
    m.editedAt = DateTime.now();
    _persistGroups();
    return true;
  }

  void toggleReaction(String groupId, String messageId, String reactionType) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull; if (g==null) return;
    final m = g.messages.where((e)=> e.id == messageId).firstOrNull; if (m==null) return;
    final existing = m.reactions.where((r)=> r.userName == currentUser.name && r.type == reactionType).firstOrNull;
    if (existing != null) {
      m.reactions.remove(existing);
    } else {
      // Remove other reaction types by same user? Keep multiple for fun -> allow multiples.
      m.reactions.add(MessageReaction(currentUser.name, reactionType));
    }
    _persistGroups();
  }

  /// Schedule a session (admins only). For simplicity scheduling is near-future.
  void scheduleSession(String groupId, DateTime when, String title, {String? notes}) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    if (!g.isAdmin(currentUser.name)) return; // only admins schedule
    final session = GroupSession(
      id: 's_${DateTime.now().millisecondsSinceEpoch}_${g.sessions.length}',
      scheduledAt: when,
      title: title.trim().isEmpty ? 'Session' : title.trim(),
      notes: notes?.trim(),
      createdAt: DateTime.now(),
    );
    g.sessions.add(session);
    g.sessions.sort((a,b)=>a.scheduledAt.compareTo(b.scheduledAt));
    _maybeAwardAchievement('first_session_scheduled');
    _persistGroups();
  }

  /// Promote a member to admin (creator only)
  void promoteToAdmin(String groupId, String memberName) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    if (g.createdBy != currentUser.name) return;
    if (g.memberNames.contains(memberName)) {
      g.admins.add(memberName);
      _persistGroups();
    }
  }

  /// Demote an admin (creator only, cannot demote creator)
  void demoteAdmin(String groupId, String memberName) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    if (g.createdBy != currentUser.name) return;
    if (memberName == g.createdBy) return;
    g.admins.remove(memberName);
    _persistGroups();
  }

  /// Activity score heuristic (0-100) combining last 7d messages + upcoming sessions + member count
  double groupActivityScore(StudyGroup g) {
    final now = DateTime.now();
    final sevenAgo = now.subtract(const Duration(days: 7));
    final recentMessages = g.messages.where((m) => m.timestamp.isAfter(sevenAgo)).length;
    final upcoming = g.sessions.where((s) => s.scheduledAt.isAfter(now)).length;
    final memberFactor = g.memberNames.length;
    // Weighted sum then scaled
    final raw = recentMessages * 3 + upcoming * 5 + memberFactor * 2;
    return raw.clamp(0, 100).toDouble();
  }

  /// Suggested groups not joined ordered by topic overlap with current user interests
  List<StudyGroup> suggestedGroups({int limit = 6}) {
    final myNames = myGroups.map((g) => g.id).toSet();
    final meTags = currentUser.interests.map((e) => e.toLowerCase()).toSet();
    final candidates = _groups.where((g) => !myNames.contains(g.id));
    final scored = <({StudyGroup g, int overlap})>[];
    for (final g in candidates) {
      final overlap = g.topics.map((e)=>e.toLowerCase()).where(meTags.contains).length;
      if (overlap > 0) {
        scored.add((g: g, overlap: overlap));
      }
    }
    scored.sort((a,b)=>b.overlap.compareTo(a.overlap));
    return scored.map((e)=>e.g).take(limit).toList();
  }

  /// Potential invitees for a group (shared topics but not members)
  List<BuddyProfile> potentialInvitees(String groupId, {int limit = 8}) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return [];
    final groupTopics = g.topics.map((e) => e.toLowerCase()).toSet();
    final memberNames = g.memberNames.toSet();
    final List<({BuddyProfile p, int overlap})> scored = [];
    for (final p in allProfiles) {
      if (memberNames.contains(p.name)) continue;
      final overlap = p.interests.map((e)=>e.toLowerCase()).where(groupTopics.contains).length;
      if (overlap > 0) scored.add((p: p, overlap: overlap));
    }
    scored.sort((a,b)=>b.overlap.compareTo(a.overlap));
    return scored.map((e)=>e.p).take(limit).toList();
  }

  /// Directly invite (auto-add) a user by profile name into a group (admins only)
  void inviteMember(String groupId, String profileName) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return;
    if (!g.isAdmin(currentUser.name)) return;
    final target = allProfiles.firstWhere((p) => p.name == profileName, orElse: () => BuddyProfile(userId: '', name: '', imageUrl: '', bio: '', matchPercentage: 0, interests: {}));
    if (target.name.isEmpty) return;
    g.memberNames.add(target.name);
    _persistGroups();
  }

  /// Seed a few demo groups (idempotent) for initial UX.
  void seedDemoGroups() {
    if (_groups.isNotEmpty) return;
    // Helper to create and return group
    StudyGroup g1 = createGroup(
      name: 'Flutter Focus Sprint',
      description: 'Daily 45‑min focused sprint to build small Flutter UI components and share patterns.',
      topics: {'flutter', 'dart', 'ui'},
    );
    StudyGroup g2 = createGroup(
      name: 'AI & Creative Coding',
      description: 'Exploring intersections of generative AI, shaders, and procedural art pipelines.',
      topics: {'ai', 'shaders', 'blender'},
    );
    StudyGroup g3 = createGroup(
      name: 'Game Dev Night Owls',
      description: 'Late night session crew prototyping gameplay loops & exchanging pixel art tips.',
      topics: {'gamedev', 'python', 'design'},
    );
    // Create one extra group the current user is NOT a member of so suggestions show up
    // We'll remove the current user after creation and backfill with other members
    StudyGroup g4 = createGroup(
      name: 'Data Viz Lab',
      description: 'Experimenting with interactive charts, shader-based infographics, and storytelling with data.',
      topics: {'dataviz', 'ui', 'ai'},
    );

    final now = DateTime.now();

    // pick some buddy profile names (skip index 0 which mirrors current user)
    final otherNames = allProfiles.skip(1).map((p) => p.name).toList();
    // utility to add random members
    void populate(StudyGroup g, int targetExtra) {
      int added = 0;
      for (final n in otherNames) {
        if (added >= targetExtra) break;
        if (!g.memberNames.contains(n)) {
          g.memberNames.add(n);
          added++;
        }
      }
    }

    populate(g1, 4); // current user + 4 others
    populate(g2, 5);
    populate(g3, 3);
    populate(g4, 6);

    // Remove current user from g4 so it becomes a suggested group candidate
    g4.memberNames.remove(currentUser.name);
    g4.admins.remove(currentUser.name);
    if (g4.memberNames.isNotEmpty) {
      // Ensure at least one admin remains (promote first member)
      g4.admins.add(g4.memberNames.first);
    }

    // Sessions & richer messages
    void seedSessions(StudyGroup g) {
      g.sessions.addAll([
        GroupSession(id: '${g.id}_s1', scheduledAt: now.add(const Duration(hours: 6)), title: 'Kickoff', notes: null, createdAt: now),
        GroupSession(id: '${g.id}_s2', scheduledAt: now.add(const Duration(days: 1)), title: 'Deep Dive', notes: 'Bring questions', createdAt: now),
      ]);
    }
    seedSessions(g1); seedSessions(g2); seedSessions(g3); seedSessions(g4);

    void seedMessages(StudyGroup g) {
      final sampleAuthors = g.memberNames.take(4).toList();
      final samples = [
        'Excited to collaborate!',
        'What should we tackle first?',
        'I can prep a small demo.',
        'Let’s define a mini-goal for today.',
        'Dropping a resource link shortly.',
      ];
      for (int i = 0; i < sampleAuthors.length; i++) {
        g.messages.add(StudyGroupMessage(
          id: '${g.id}_m$i',
          authorName: sampleAuthors[i],
          content: samples[i % samples.length],
          timestamp: now.subtract(Duration(minutes: 5 * (sampleAuthors.length - i))),
        ));
      }
    }
    seedMessages(g1); seedMessages(g2); seedMessages(g3); seedMessages(g4);
  }

  // Simple sample bios for demo population
  final List<String> _sampleBios = const [
    'Trying to balance astrophysics and sitcom reruns. Calculus duo?',
    'Flutter by day, debugging by night. Help with state mgmt!',
    'History nerd + gamer. Peloponnesian War or co-op raid?',
    'Coffee artisan, writing a novel between chem labs.',
    'Playlist maker + study session architect. Surviving orgo.',
    'Psych student decoding procrastination. Accountability pal?',
    'Dog photos + finance slides. Let’s case study and chill.',
    'Hunting quiet corners. Linear algebra finally clicking.',
    'Future architect. Builds in Minecraft, studies codes IRL.',
    'Rainy days, epic fantasy, legendary notes.',
  ];

  // Pool of tags to weight some more heavily
  static const List<String> _heavyTags = [
    'flutter', 'dart', 'coffee', 'calculus', 'python', 'ai', 'gamedev', 'music'
  ];
  static const List<String> _lightTags = [
    'history', 'gaming', 'strategy', 'chemistry', 'writing', 'playlists',
    'study', 'productivity', 'reading', 'finance', 'dogs', 'case-studies',
    'linearalgebra', 'library', 'math', 'architecture', 'minecraft', 'design',
    'fantasy', 'rainy', 'notetaking', 'ui', 'shaders', 'geonodes'
  ];

  Set<String> _generateInterests(int seed) {
    // Ensure varied frequency: heavy tags appear more often based on seed
    final Set<String> tags = {};
    // always include 1-2 heavy tags
    tags.add(_heavyTags[seed % _heavyTags.length]);
    if (seed % 2 == 0) tags.add(_heavyTags[(seed + 3) % _heavyTags.length]);
    // include 1-3 light tags
    tags.add(_lightTags[(seed * 2) % _lightTags.length]);
    if (seed % 3 == 0) tags.add(_lightTags[(seed * 3 + 1) % _lightTags.length]);
    if (seed % 5 == 0) tags.add(_lightTags[(seed * 5 + 2) % _lightTags.length]);
    return tags;
  }

  // Method to update the user data
  void updateUserData({
    required String name,
    required String bio,
    Uint8List? image,
    Set<String>? interests,
    String? availability,
  }) {
    currentUser.name = name;
    currentUser.bio = bio;
    currentUser.imageData = image;
    if (interests != null) {
      currentUser.interests = interests;
    }
    if (availability != null) {
      currentUser.availability = availability;
    }

    // Keep allProfiles[0] in sync with current user for search/hashtag wall
    if (allProfiles.isNotEmpty) {
      allProfiles[0]
        ..name = currentUser.name
        ..bio = currentUser.bio
        ..interests = {...currentUser.interests};
    }
    try { profileChangedNotifier.value++; } catch (_) {}
    _persistUser();
  }

  // Notifier to allow UI screens to refresh when profile data changes
  final ValueNotifier<int> profileChangedNotifier = ValueNotifier<int>(0);

  // --- Persistence Keys ---
  static const _kUserKey = 'persist_user_v1';
  static const _kGroupsKey = 'persist_groups_v1';

  bool _loaded = false;

  // Debounced persistence flags / timer
  Timer? _persistTimer;
  bool _dirtyUser = false;
  bool _dirtyGroups = false;
  static const Duration _persistDebounce = Duration(milliseconds: 500);

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, () async {
      if (_dirtyUser) await _writeUserNow();
      if (_dirtyGroups) await _writeGroupsNow();
      _dirtyUser = false;
      _dirtyGroups = false;
    });
  }

  Future<void> flushNow() async {
    _persistTimer?.cancel();
    if (_dirtyUser) await _writeUserNow();
    if (_dirtyGroups) await _writeGroupsNow();
    _dirtyUser = false;
    _dirtyGroups = false;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRaw = prefs.getString(_kUserKey);
      if (userRaw != null) {
        final map = jsonDecode(userRaw) as Map<String, dynamic>;
        currentUser
          ..name = map['name'] as String? ?? currentUser.name
          ..bio = map['bio'] as String? ?? currentUser.bio
          ..interests = (map['interests'] as List?)?.map((e)=> e.toString()).toSet() ?? currentUser.interests;
        if (map['image'] is String) {
          try { currentUser.imageData = base64Decode(map['image']); } catch (_) {}
        }
        final gls = map['groupLastSeen'] as Map?;
        if (gls != null) {
          currentUser.groupLastSeenIso.clear();
          for (final e in gls.entries) {
            currentUser.groupLastSeenIso[e.key.toString()] = e.value.toString();
          }
        }
        currentUser.streakCount = (map['streak'] as num?)?.toInt() ?? currentUser.streakCount;
        currentUser.lastStreakDay = map['lastStreakDay'] as String? ?? currentUser.lastStreakDay;
        currentUser.achievements = (map['achievements'] as List?)?.map((e)=> e.toString()).toSet() ?? currentUser.achievements;
        currentUser.availability = map['availability'] as String? ?? currentUser.availability;
        if (allProfiles.isNotEmpty) {
          allProfiles[0]
            ..name = currentUser.name
            ..bio = currentUser.bio
            ..interests = {...currentUser.interests};
        }
      }
      final groupsRaw = prefs.getString(_kGroupsKey);
      if (groupsRaw != null) {
        final list = jsonDecode(groupsRaw) as List<dynamic>;
        _groups.clear();
        for (final g in list) {
          if (g is Map<String,dynamic>) {
            final sg = StudyGroup(
              id: g['id'] as String,
              name: g['name'] as String? ?? 'Group',
              description: g['description'] as String? ?? '',
              pinnedUrl: g['pinnedUrl'] as String?,
              topics: (g['topics'] as List?)?.map((e)=> e.toString()).toSet() ?? <String>{},
              memberNames: (g['members'] as List?)?.map((e)=> e.toString()).toSet() ?? <String>{},
              createdAt: DateTime.tryParse(g['createdAt'] as String? ?? '') ?? DateTime.now(),
              createdBy: g['createdBy'] as String? ?? currentUser.name,
            );
            final admins = (g['admins'] as List?)?.map((e)=> e.toString()).toSet() ?? <String>{};
            sg.admins..clear()..addAll(admins.isEmpty ? {sg.createdBy} : admins);
            final msgs = (g['messages'] as List?) ?? [];
            for (final m in msgs) {
              if (m is Map<String,dynamic>) {
                sg.messages.add(StudyGroupMessage(
                  id: m['id'] as String,
                  authorName: m['author'] as String? ?? 'anon',
                  content: m['content'] as String? ?? '',
                  timestamp: DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            }
            final sess = (g['sessions'] as List?) ?? [];
            for (final s in sess) {
              if (s is Map<String,dynamic>) {
                sg.sessions.add(GroupSession(
                  id: s['id'] as String,
                  scheduledAt: DateTime.tryParse(s['at'] as String? ?? '') ?? DateTime.now(),
                  title: s['title'] as String? ?? 'Session',
                  notes: s['notes'] as String?,
                  createdAt: DateTime.tryParse(s['created'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            }
            _groups.add(sg);
          }
        }
      }
      _loaded = true;
      profileChangedNotifier.value++;
    } catch (_) {}
  }

  Future<void> _writeUserNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String,dynamic>{
        'name': currentUser.name,
        'bio': currentUser.bio,
        'interests': currentUser.interests.toList(),
        if (currentUser.imageData != null) 'image': base64Encode(currentUser.imageData!),
        'groupLastSeen': currentUser.groupLastSeenIso,
        'streak': currentUser.streakCount,
        'lastStreakDay': currentUser.lastStreakDay,
        'achievements': currentUser.achievements.toList(),
        'availability': currentUser.availability,
      };
      await prefs.setString(_kUserKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _writeGroupsNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _groups.map((g) => {
        'id': g.id,
        'name': g.name,
        'description': g.description,
        'topics': g.topics.toList(),
        'members': g.memberNames.toList(),
        'createdAt': g.createdAt.toIso8601String(),
        'createdBy': g.createdBy,
        'admins': g.admins.toList(),
        'pinnedUrl': g.pinnedUrl,
        'messages': g.messages.map((m) => {
          'id': m.id,
          'author': m.authorName,
          'content': m.content,
          'ts': m.timestamp.toIso8601String(),
          if (m.editedAt != null) 'edited': m.editedAt!.toIso8601String(),
          if (m.reactions.isNotEmpty) 'reactions': m.reactions.map((r) => {'u': r.userName, 't': r.type}).toList(),
        }).toList(),
        'sessions': g.sessions.map((s) => {
          'id': s.id,
          'at': s.scheduledAt.toIso8601String(),
          'title': s.title,
          'notes': s.notes,
          'created': s.createdAt.toIso8601String(),
        }).toList(),
      }).toList();
      await prefs.setString(_kGroupsKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _persistUser() async { _dirtyUser = true; _schedulePersist(); }
  Future<void> _persistGroups() async { _dirtyGroups = true; _schedulePersist(); }

  // Helper / derived state
  void markGroupSeen(String groupId) {
    currentUser.groupLastSeenIso[groupId] = DateTime.now().toIso8601String();
    _persistUser();
  }
  int unreadCount(String groupId) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull;
    if (g == null) return 0;
    final lastIso = currentUser.groupLastSeenIso[groupId];
    if (lastIso == null) return g.messages.length; // never opened
    final last = DateTime.tryParse(lastIso);
    if (last == null) return 0;
    return g.messages.where((m) => m.timestamp.isAfter(last)).length;
  }
  bool hasUnread(String groupId) => unreadCount(groupId) > 0;
  void setPinnedUrl(String groupId, String? url) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull; if (g==null) return;
    if (!g.isAdmin(currentUser.name)) return;
    g.pinnedUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    _persistGroups();
  }
  void updateSessionNotes(String groupId, String sessionId, String notes) {
    final g = _groups.where((e) => e.id == groupId).firstOrNull; if (g==null) return;
    final s = g.sessions.where((e)=> e.id == sessionId).firstOrNull; if (s==null) return;
    s.notes = notes.trim().isEmpty ? null : notes.trim();
    _persistGroups();
  }
  void updateAvailability(String availability) {
    currentUser.availability = availability; _persistUser();
    try { profileChangedNotifier.value++; } catch(_) {}
  }
  void _updateStreakOnMessage() {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    if (currentUser.lastStreakDay == todayKey) return; // already counted
    if (currentUser.lastStreakDay != null) {
      final last = _parseDayKey(currentUser.lastStreakDay!);
      if (last != null) {
        final diff = now.difference(last).inDays;
        if (diff == 1) {
          currentUser.streakCount += 1;
        } else if (diff > 1) {
          currentUser.streakCount = 1;
        }
      } else {
        currentUser.streakCount = 1;
      }
    } else {
      currentUser.streakCount = 1;
    }
    currentUser.lastStreakDay = todayKey;
    _persistUser();
  }
  void _maybeAwardAchievement(String code) {
    if (currentUser.achievements.contains(code)) return;
    currentUser.achievements.add(code);
    _persistUser();
  }
  String _dayKey(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}${dt.month.toString().padLeft(2,'0')}${dt.day.toString().padLeft(2,'0')}';
  DateTime? _parseDayKey(String s) {
    if (s.length != 8) return null;
    final y = int.tryParse(s.substring(0,4));
    final m = int.tryParse(s.substring(4,6));
    final d = int.tryParse(s.substring(6,8));
    if (y==null||m==null||d==null) return null;
    return DateTime(y,m,d);
  }

  // --- Hashtag utilities ---
  Map<String, int> getHashtagCounts() {
    final Map<String, int> counts = {};
    for (final p in allProfiles) {
      for (final tag in p.interests) {
        final key = tag.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<BuddyProfile> searchByHashtag(String tag) {
    final t = tag.toLowerCase().replaceAll('#', '').trim();
    return allProfiles
        .where((p) => p.interests.map((e) => e.toLowerCase()).contains(t))
        .toList(growable: false);
  }
}

// -------------- Extensions / Helpers --------------
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

// -------------- Study Group Model --------------
class StudyGroup {
  final String id;
  String name;
  String description;
  Set<String> topics;
  Set<String> memberNames; // references by name for simplicity
  Set<String> memberUids; // Firebase Auth UIDs for multi-user support
  final DateTime createdAt;
  final String createdBy;
  final String createdByUid; // Firebase Auth UID of creator
  final Set<String> admins = {}; // includes creator by default (added in constructor body)
  final List<StudyGroupMessage> messages = [];
  final List<GroupSession> sessions = [];
  String? pinnedUrl; // optional resource link

  StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.topics,
    required this.memberNames,
    Set<String>? memberUids,
    required this.createdAt,
    required this.createdBy,
    String? createdByUid,
    this.pinnedUrl,
  })  : memberUids = memberUids ?? <String>{},
        createdByUid = createdByUid ?? '' {
    admins.add(createdBy);
  }

  bool isAdmin(String name) => admins.contains(name);
}

class StudyGroupMessage {
  final String id;
  final String authorName;
  final String authorUid; // Firebase Auth UID of message author
  String content;
  final DateTime timestamp;
  DateTime? editedAt;
  final List<MessageReaction> reactions;
  StudyGroupMessage({
    required this.id,
    required this.authorName,
    String? authorUid,
    required this.content,
    required this.timestamp,
    this.editedAt,
    List<MessageReaction>? reactions,
  })  : authorUid = authorUid ?? '',
        reactions = reactions ?? [];
}

class MessageReaction {
  final String userName;
  final String type; // emoji or short code
  MessageReaction(this.userName, this.type);
}

class GroupSession {
  final String id;
  final DateTime scheduledAt;
  final String title;
  String? notes;
  final DateTime createdAt;
  GroupSession({
    required this.id,
    required this.scheduledAt,
    required this.title,
    required this.notes,
    required this.createdAt,
  });
}