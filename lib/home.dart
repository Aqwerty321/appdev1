import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'widgets/neon_border_tile.dart';
import 'globals.dart';
import 'config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui show ImageFilter; // alias to avoid any shadowing
import 'buddy_profile_screen.dart';
import 'hashtag_wall_screen.dart';
import 'user_data_service.dart';
import 'firestore_service.dart';
import 'study_groups_screen.dart';
import 'study_group_detail_screen.dart';
import 'widgets/neon_home_icon_painter.dart';
import 'widgets/interest_chip.dart';
import 'auth_service.dart';
import 'ai_matchmaking_screen.dart';
import 'ai_matchmaking_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// All the logic lives in the State class.
class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _cardScrollController;
  static const Color _neonPurple = Color(0xFF986AF0);
  final UserDataService _service = UserDataService();
  final FirestoreService _firestoreService = FirestoreService();
  final AiMatchmakingService _aiService = AiMatchmakingService();
  final Set<String> _selectedTags = {};
  
  // Cache AI match scores to avoid excessive API calls
  Map<String, int> _matchScores = {};
  bool _matchScoresLoading = false;
  DateTime? _matchScoresCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);
  // Removed per-screen heat cache; InterestChip manages color derivation globally.

  void _toggleTag(String tag, bool selected) {
    setState(() {
      if (selected) {
        _selectedTags.add(tag.toLowerCase());
      } else {
        _selectedTags.remove(tag.toLowerCase());
      }
    });
    // Fetch fresh match scores when filters change
    _fetchMatchScores();
  }

  /// Fetch AI match scores for all users (cached for 30 minutes)
  Future<void> _fetchMatchScores() async {
    // Check if cache is still valid
    if (_matchScoresCacheTime != null && 
        DateTime.now().difference(_matchScoresCacheTime!) < _cacheExpiry) {
      return; // Use cached data
    }

    if (_matchScoresLoading) return; // Prevent duplicate requests

    setState(() => _matchScoresLoading = true);

    try {
      final currentUser = _service.currentUser;
      print('🔍 Current user interests: ${currentUser.interests}');
      print('🔍 Current user bio: ${currentUser.bio}');
      
      if (currentUser.interests.isEmpty) {
        // Skip if user has no interests set
        print('⚠️ User has no interests set - skipping AI matching');
        setState(() => _matchScoresLoading = false);
        return;
      }

      print('🚀 Fetching AI match scores...');
      final matches = await _aiService.findMatches(
        interests: currentUser.interests,
        bio: currentUser.bio,
      );
      
      print('✅ Received ${matches.length} matches from AI service');
      
      final newScores = <String, int>{};
      for (var match in matches) {
        // Use userId for matching (more reliable than name)
        newScores[match.userId] = match.matchScore;
        print('📊 AI Match: ${match.name} (userId: ${match.userId}) = ${match.matchScore}%');
      }
      
      print('💾 Total AI match scores cached: ${newScores.length}');
      print('💾 Cache keys: ${newScores.keys.toList()}');
      
      setState(() {
        _matchScores = newScores;
        _matchScoresCacheTime = DateTime.now();
        _matchScoresLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error fetching match scores: $e');
      print('Stack trace: $stackTrace');
      setState(() => _matchScoresLoading = false);
    }
  }

  // Per-tag color logic handled by unified InterestChip widget now.

  // Reuse color scale but chips remain transparent; provide border color derived from text color.
  // _chipBorderColor removed (handled inside InterestChip)

  // ✅ FIX 1: Move randomBios to be a class-level variable.
  // This makes it accessible throughout the entire _HomeScreenState.
  final List<String> randomBios = [
    "Trying to balance my love for astrophysics with my need to re-watch every season of The Office. Let's conquer calculus together!",
    "My plants are probably dying, but my Flutter code is thriving. Looking for someone to debug life with, or at least this pesky state management issue.",
    "History major by day, professional gamer by night. I can tell you about the Peloponnesian War or we can just grind for loot after studying.",
    "Certified coffee addict and aspiring novelist. I'll trade you expertly brewed espresso shots for help with my chemistry homework. It's a fair deal.",
    "I believe any problem can be solved with a good playlist and a solid study session. Currently trying to survive organic chemistry, send help (or snacks).",
    "Just a psychology student trying to understand the human mind, starting with why I procrastinate. Looking for an accountability partner!",
    "My camera roll is 90% pictures of my dog and 10% lecture slides. If you can handle dog spam, let's tackle these finance case studies.",
    "On a mission to find the quietest spot in the library and finally understand linear algebra. I make great flashcards and even better bad jokes.",
    "Future architect who spends too much time building things in Minecraft instead of studying building codes. Let's build a better GPA together.",
    "Lover of rainy days, epic fantasy novels, and neatly organized notes. Let's make our study guides as legendary as the stories we read.",
  ];

  @override
  void initState() {
    super.initState();
    _cardScrollController = ScrollController();
    // Fetch AI match scores on initial load
    _fetchMatchScores();
    // The randomBios list is now initialized above, so it's removed from here.
  }

  @override
  void dispose() {
    _cardScrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => globalMousePosition.value = event.position,
      child: Scaffold(
        backgroundColor: AppConfig.darkBlue,
        appBar: AppBar(
          title: Text(AppConfig.appName,
              style: TextStyle(color: AppConfig.lightBlue)),
          backgroundColor: AppConfig.darkBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: NavigationDrawer(
          backgroundColor: const Color(0xFF1B263B),
          children: <Widget>[
            ListTile(
              leading: CustomPaint(
                painter: NeonHomeIconPainter(color: const Color(0xFF00D9FF)), // Bright cyan
                size: const Size(24, 24),
              ),
              title: const Text('Home',
                  style: TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 24)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFB366FF)), // Vibrant purple
              title: const Text('Profile',
                  style: TextStyle(color: Color(0xFF00D9FF))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Color(0xFFFFB800)), // AI icon with amber
              title: const Text('AI Matchmaking',
                  style: TextStyle(color: Color(0xFF00D9FF))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiMatchmakingScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag, color: Color(0xFFFF2E97)), // Electric pink
              title: const Text('Hashtag Wall',
                  style: TextStyle(color: Color(0xFF00D9FF))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HashtagWallScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Color(0xFF00FF94)), // Success green
              title: const Text('Study Groups',
                  style: TextStyle(color: Color(0xFF00D9FF))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudyGroupsScreen()),
                );
              },
            ),
            const Divider(color: Colors.white24, height: 32),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out',
                  style: TextStyle(color: Color.fromARGB(255, 129, 167, 238))),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
                // Navigation handled by AuthWrapper stream
              },
            ),
          ],
        ),
        body: ValueListenableBuilder<bool>(
          valueListenable: globalVerticalScrollLock,
          builder: (context, locked, _) => ListView(
            physics: locked ? const _LockedScrollPhysics() : const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppConfig.showTimeBasedGreeting ? _getGreeting() : AppConfig.staticGreeting,
                style: TextStyle(
                  color: AppConfig.secondaryTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: SvgPicture.asset(
                          'assets/icons/compass_icon1.svg', // Ensure this path is correct
                          width: 80,
                          height: 80,
                          colorFilter: const ColorFilter.mode(
                            Colors.cyanAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/compass_icon1.svg', // Ensure this path is correct
                        width: 76,
                        height: 76,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF00BFFF),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppConfig.discoverBuddiesTitle,
                    style: TextStyle(
                      color: AppConfig.primaryTextColor,
                      fontSize: AppConfig.headingFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_matchScoresLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFB800),
                        strokeWidth: 2,
                      ),
                    )
                  else if (_matchScores.isNotEmpty)
                    Tooltip(
                      message: 'AI match scores loaded (${_matchScores.length} users)',
                      child: const Icon(
                        Icons.psychology,
                        color: Color(0xFFFFB800),
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            // Hint quote under the heading
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 6.0),
              child: Text(
                AppConfig.discoverBuddiesQuote,
                style: TextStyle(
                  color: AppConfig.secondaryTextColor,
                  fontStyle: FontStyle.italic,
                  fontSize: AppConfig.smallFontSize,
                ),
              ),
            ),
            const SizedBox(height: 20),
            MouseRegion(
              onEnter: (_) => globalVerticalScrollLock.value = true,
              onExit: (_) => globalVerticalScrollLock.value = false,
              child: SizedBox(
              // Height must accommodate 480 card height + vertical padding (approx 16*2 + internal padding)
              // Give a little extra breathing room to avoid any clipping glow.
              height: 520,
              child: RawScrollbar(
                controller: _cardScrollController,
                thumbVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(4.0),
                thumbColor: _neonPurple.withOpacity(0.8),
                trackVisibility: false,
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      // Translate vertical wheel to horizontal scroll with 2x acceleration
                      final delta = pointerSignal.scrollDelta.dy * 2;
                      final target = (_cardScrollController.offset + delta)
                          .clamp(0.0, _cardScrollController.position.maxScrollExtent);
                      _cardScrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.decelerate,
                      );
                    }
                  },
                  child: StreamBuilder<List<BuddyProfile>>(
                    stream: _firestoreService.watchAllUsers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF81A7EE)),
                        );
                      }

                      final allUsers = snapshot.data!;

                      if (allUsers.isEmpty) {
                        return const Center(
                          child: Text(
                            'No buddies found yet. Invite friends to join!',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        controller: _cardScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          final p = allUsers[index];
                          final buddyName = p.name;
                          final buddyImageUrl = p.imageUrl;
                          final buddyBio = p.bio;
                          // Use AI-calculated match score from cache
                          final buddyMatch = _matchScores[p.userId] ?? 0;
                          final interests = p.interests;
                          
                          if (index == 0) {
                            print('🎴 Top carousel card - Name: $buddyName, UserId: ${p.userId}, Match: $buddyMatch%');
                          }

                          return Container(
                            width: 300,
                            margin: const EdgeInsets.only(right: 16.0),
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuddyProfileScreen(
                                      name: buddyName,
                                      imageUrl: buddyImageUrl,
                                      bio: buddyBio,
                                      matchPercentage: buddyMatch,
                                      interests: interests,
                                    ),
                                  ),
                                );
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: BuddyProfileCard(
                                  name: buddyName,
                                  imageUrl: buddyImageUrl,
                                  bio: buddyBio,
                                  matchPercentage: buddyMatch,
                                  interests: interests,
                                  tileHeight: 480,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            )),
            const SizedBox(height: 28),
            // ----- My Study Groups Section -----
            _buildMyGroupsSection(context),
            const SizedBox(height: 28),
            // Find by Interest section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      AppConfig.findByInterestTitle,
                      style: TextStyle(
                        color: AppConfig.primaryTextColor,
                        fontSize: AppConfig.headingFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppConfig.findByInterestQuote,
                      style: TextStyle(
                        color: AppConfig.secondaryTextColor,
                        fontStyle: FontStyle.italic,
                        fontSize: AppConfig.smallFontSize,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Text(
                        'Popular tags',
                        style: TextStyle(
                          color: Color.fromARGB(255, 129, 167, 238),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<BuddyProfile>>(
                    stream: _firestoreService.watchAllUsers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF81A7EE)),
                          ),
                        );
                      }

                      // Calculate tag counts from real users
                      final Map<String, int> counts = {};
                      for (final user in snapshot.data!) {
                        for (final tag in user.interests) {
                          counts[tag] = (counts[tag] ?? 0) + 1;
                        }
                      }

                      final popular = counts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      final top = popular.take(12).map((e) => e.key).toList(growable: false);

                      if (top.isEmpty) {
                        return const Text(
                          'No tags available yet.',
                          style: TextStyle(color: Colors.white54),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final tag in top)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InterestChip(
                                  tag,
                                  selected: _selectedTags.contains(tag.toLowerCase()),
                                  onSelected: (sel) => _toggleTag(tag, sel),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // All Tags row (moved above results), horizontally scrollable - using real Firestore data
                  StreamBuilder<List<BuddyProfile>>(
                    stream: _firestoreService.watchAllUsers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF81A7EE)),
                          ),
                        );
                      }

                      // Calculate tag counts from real users
                      final Map<String, int> counts = {};
                      for (final user in snapshot.data!) {
                        for (final tag in user.interests) {
                          counts[tag] = (counts[tag] ?? 0) + 1;
                        }
                      }

                      final sorted = counts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                        if (sorted.isEmpty) {
                          return Text(
                            AppConfig.noTagsAvailableMessage,
                            style: TextStyle(color: AppConfig.secondaryTextColor),
                          );
                        }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Tags',
                            style: TextStyle(
                              color: Color.fromARGB(255, 129, 167, 238),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _WheelAccelerator(
                            multiplier: 2.0,
                            onHoverChange: (h) => globalVerticalScrollLock.value = h,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final e in sorted)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: InterestChip(
                                        e.key,
                                        selected: _selectedTags.contains(e.key.toLowerCase()),
                                        onSelected: (sel) => _toggleTag(e.key, sel),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_selectedTags.isNotEmpty) ...[
                    Wrap(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () => setState(() { _selectedTags.clear(); }),
                              child: InterestChip('Clear Filters (${_selectedTags.length})', compact: true, clickable: true, prefixHash: false, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                            ),
                        )
                      ],
                    ),
                  ],
                  // Horizontal scrolling row of filtered buddy profile cards (using real Firestore data)
                  StreamBuilder<List<BuddyProfile>>(
                    stream: _firestoreService.watchAllUsers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF81A7EE)),
                        );
                      }

                      final allUsers = snapshot.data!;

                      if (_selectedTags.isEmpty) {
                        return const Text(
                          'Select one or more tags to see matching buddies.',
                          style: TextStyle(color: Colors.white54),
                        );
                      }

                      final filtered = allUsers
                          .where((p) {
                            final pTags = p.interests.map((e) => e.toLowerCase()).toSet();
                            return _selectedTags.every(pTags.contains);
                          })
                          .toList();

                      if (filtered.isEmpty) {
                        return const Text(
                          'No profiles match the selected tags yet. Try other tags!',
                          style: TextStyle(color: Colors.white54),
                        );
                      }

                      const double cardHeight = 480; // maintain enlarged size
                      return SizedBox(
                        height: cardHeight + 32, // include padding/margins
                        child: _WheelAccelerator(
                          multiplier: 2.0,
                          onHoverChange: (h) => globalVerticalScrollLock.value = h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            itemCount: filtered.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            itemBuilder: (context, idx) {
                              final p = filtered[idx];
                              // Get AI-calculated match score from cache using userId
                              final aiMatchScore = _matchScores[p.userId] ?? 0;
                              
                              if (idx == 0) {
                                print('🃏 First buddy card - Name: ${p.name}, UserId: ${p.userId}, Match: $aiMatchScore%');
                                print('🃏 Available match scores: ${_matchScores.length} entries');
                                print('🃏 Looking for userId "${p.userId}" in cache...');
                                print('🃏 Cache contains: ${_matchScores.keys.take(3).join(", ")}...');
                              }
                              
                              return Container(
                                width: 300,
                                margin: const EdgeInsets.only(right: 16),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BuddyProfileScreen(
                                          name: p.name,
                                          imageUrl: p.imageUrl,
                                          bio: p.bio,
                                          matchPercentage: aiMatchScore,
                                          interests: p.interests,
                                        ),
                                      ),
                                    );
                                  },
                                  child: BuddyProfileCard(
                                    name: p.name,
                                    imageUrl: p.imageUrl,
                                    bio: p.bio,
                                    matchPercentage: aiMatchScore,
                                    interests: p.interests,
                                    tileHeight: cardHeight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyGroupsSection(BuildContext context) {
    return StreamBuilder<List<StudyGroup>>(
      stream: _firestoreService.watchMyGroups(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];
        
        return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My Study Groups',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Browse / Create',
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF81A7EE)),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudyGroupsScreen()),
                  );
                  setState(() {});
                },
              )
            ],
          ),
          const SizedBox(height: 6),
            const Text(
              '“Collaboration compounds comprehension.”',
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudyGroupsScreen()),
                );
                setState(() {});
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF13233F),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF81A7EE).withOpacity(0.5)),
                ),
                child: const Center(
                  child: Text(
                    'You are not in any groups yet. Tap to explore or create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) {
                  final g = groups[i];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StudyGroupDetailScreen(groupId: g.id)),
                      );
                      setState(() {});
                    },
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13233F),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF81A7EE).withOpacity(0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF81A7EE).withOpacity(0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              g.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: g.topics.take(4).map((t) => InterestChip(t, compact: true, clickable: false)).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            if (_service.hasUnread(g.id)) Container(
                              width: 10, height: 10,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D6D),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [BoxShadow(color: Color(0xFFFF4D6D), blurRadius: 6)],
                              ),
                            ),
                            Text('${g.memberNames.length} members', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
      },
    );
  }
}

// The reusable widget for displaying a user's profile card
class BuddyProfileCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String bio;
  final int matchPercentage;
  final double? tileHeight;
  final Set<String>? interests;

  const BuddyProfileCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.bio,
    required this.matchPercentage,
    this.tileHeight,
    this.interests,
  });

  @override
  State<BuddyProfileCard> createState() => _BuddyProfileCardState();
}

// Create its State class and add the magic mixin
class _BuddyProfileCardState extends State<BuddyProfileCard>
    with AutomaticKeepAliveClientMixin { // ✅ 1. Add the mixin

  // --- Theme definitions with improved colors ---
  static const TextStyle _neonTextStyle = TextStyle(
    color: Color(0xFFB366FF), // Vibrant purple
    fontSize: 16,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(blurRadius: 6.0, color: Color(0xFF6B00B3), offset: Offset(0, 2.0)), // Purple glow shadow
      Shadow(blurRadius: 12.0, color: Color(0xFFB366FF), offset: Offset(0, 0)), // Outer glow
    ],
  );
  
  // ✅ 2. Override wantKeepAlive and return true
  // This tells the ListView to keep this widget's state loaded.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // ✅ 3. Call super.build(context) for the mixin to work
    super.build(context); 
    
    // The rest of the build logic is the same, but uses 'widget.' to access properties
    return RepaintBoundary(
      child: NeonBorderGradientTile(
        width: double.infinity,
        height: widget.tileHeight,
        padding: const EdgeInsets.all(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0E3E), Color(0xFF0D1B3A)], // Updated to match config
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade900,
                  backgroundImage: widget.imageUrl.isNotEmpty 
                      ? NetworkImage(widget.imageUrl) 
                      : null,
                  child: widget.imageUrl.isEmpty 
                      ? const Icon(Icons.person, size: 35, color: Colors.white30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, style: _neonTextStyle.copyWith(fontSize: 22)), // Use widget.name
                      const SizedBox(height: 4),
                      Text(
                        '${widget.matchPercentage}% Match', // Use widget.matchPercentage
                        style: _neonTextStyle.copyWith(
                          color: const Color.fromARGB(255, 181, 141, 255).withOpacity(0.8),
                          fontSize: 14,
                          shadows: [],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1A2E).withOpacity(0.4),
                      const Color(0xFF16213E).withOpacity(0.4),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          widget.bio,
                          style: _neonTextStyle.copyWith(
                            fontWeight: FontWeight.normal,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if ((widget.interests ?? {}).isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.interests!
                            .take(6)
                            .map((t) => InterestChip(t, compact: true, clickable: false))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to amplify mouse wheel scroll delta for its horizontal child
class _WheelAccelerator extends StatefulWidget {
  final Widget child;
  final double multiplier;
  final ValueChanged<bool>? onHoverChange;
  const _WheelAccelerator({required this.child, this.multiplier = 2.0, this.onHoverChange});

  @override
  State<_WheelAccelerator> createState() => _WheelAcceleratorState();
}

class _WheelAcceleratorState extends State<_WheelAccelerator> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { setState(() => _hovering = true); widget.onHoverChange?.call(true); },
      onExit: (_) { setState(() => _hovering = false); widget.onHoverChange?.call(false); },
      child: Listener(
        onPointerSignal: (ps) {
          if (ps is PointerScrollEvent) {
            final scrollableState = Scrollable.of(context);
            final controller = scrollableState.position;
            if (controller.axis == Axis.horizontal) {
              // Convert vertical wheel to horizontal scroll and prevent parent scroll by stopping propagation.
              final dy = ps.scrollDelta.dy;
              final dx = ps.scrollDelta.dx;
              final primaryDelta = (dy.abs() > dx.abs() ? dy : dx);
              final target = controller.pixels + primaryDelta * widget.multiplier;
              controller.jumpTo(target.clamp(0, controller.maxScrollExtent));
            }
          }
        },
        behavior: HitTestBehavior.opaque,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (_hovering && n.metrics.axis == Axis.vertical) {
              return true; // block vertical notifications entirely while hovering
            }
            return false;
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _LockedScrollPhysics extends ClampingScrollPhysics {
  const _LockedScrollPhysics({super.parent});
  @override
  _LockedScrollPhysics applyTo(ScrollPhysics? ancestor) => _LockedScrollPhysics(parent: buildParent(ancestor));
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) => 0.0;
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;
}