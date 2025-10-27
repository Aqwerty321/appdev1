import 'package:flutter/material.dart';
import 'user_data_service.dart';
import 'firestore_service.dart';
import 'widgets/interest_chip.dart';
import 'study_group_detail_screen.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  final UserDataService _service = UserDataService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();
  bool _showCreate = false;
  bool _showSuggestions = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Groups loaded from Firestore via StreamBuilder
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final topics = _topicsController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (name.isEmpty || desc.isEmpty) return;
    
    setState(() => _isCreating = true);

    try {
      // Create in Firestore
      await _firestoreService.createGroup(
        name: name,
        description: desc,
        topics: topics,
      );

      _nameController.clear();
      _descController.clear();
      _topicsController.clear();
      setState(() => _showCreate = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study group created!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myInterestTags = _service.currentUser.interests.map((e)=> e.toLowerCase()).toSet();
    
    return StreamBuilder<List<StudyGroup>>(
      stream: _firestoreService.watchMyGroups(),
      builder: (context, myGroupsSnapshot) {
        final myGroups = myGroupsSnapshot.data ?? [];
        final myGroupIds = myGroups.map((g) => g.id).toSet();
        
        return StreamBuilder<List<StudyGroup>>(
          stream: _firestoreService.watchAllGroups(),
          builder: (context, allGroupsSnapshot) {
            final allGroups = allGroupsSnapshot.data ?? [];
            
            // Calculate suggestions: groups user is NOT in, ordered by topic overlap
            final suggestions = allGroups
                .where((g) => !myGroupIds.contains(g.id))
                .map((g) {
                  final overlap = g.topics.map((e) => e.toLowerCase()).where(myInterestTags.contains).length;
                  return MapEntry(g, overlap);
                })
                .where((entry) => entry.value > 0)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            
            final suggestedGroups = suggestions.map((e) => e.key).take(5).toList();

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Study Groups', style: TextStyle(color: Color(0xFF81A7EE))),
            backgroundColor: const Color(0xFF13233F),
            iconTheme: const IconThemeData(color: Color(0xFF81A7EE)),
            actions: [
              IconButton(
                icon: Icon(_showCreate ? Icons.close : Icons.add, color: const Color(0xFF81A7EE)),
                onPressed: () => setState(() => _showCreate = !_showCreate),
                tooltip: 'Create Group',
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showCreate)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF101B2D), Color(0xFF15253C)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1F3557), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF81A7EE).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF81A7EE).withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.group_add, color: Color(0xFF81A7EE), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Create Study Group', 
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF0B1626),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1F3557)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1F3557)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF81A7EE), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF0B1626),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1F3557)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1F3557)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF81A7EE), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _topicsController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Topics (comma separated)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          hintText: 'e.g., Flutter, Firebase, Web Development',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF0B1626),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1F3557)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1F3557)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF81A7EE), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _createGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF81A7EE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text('Create Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
          // Suggested groups section
          if (myGroups.isNotEmpty || suggestedGroups.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF101B2D), Color(0xFF15253C)],
                ),
                border: Border.all(color: const Color(0xFF2A4A7A), width: 1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81A7EE).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.recommend, color: Color(0xFF81A7EE), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Suggested Groups', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_showSuggestions ? Icons.expand_less : Icons.expand_more, color: Colors.white54),
                        onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    crossFadeState: _showSuggestions ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 250),
                    firstChild: suggestedGroups.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text('No suggestions right now.', style: TextStyle(color: Colors.white54, fontSize: 15)),
                            ),
                          )
                        : Column(
                            children: suggestedGroups.map((g) {
                              final overlap = g.topics.map((e)=> e.toLowerCase()).where(myInterestTags.contains).length;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudyGroupDetailScreen(groupId: g.id),
                                    ),
                                  ).then((_) => setState(() {})),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B1626),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF2A4A7A), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                            ),
                                            if (g.pinnedUrl != null) Padding(
                                              padding: const EdgeInsets.only(right: 6.0),
                                              child: Tooltip(
                                                message: 'Pinned resource',
                                                child: Icon(Icons.push_pin, size: 16, color: Colors.amber.shade300),
                                              ),
                                            ),
                                            if (overlap > 0) Container(
                                              margin: const EdgeInsets.only(right: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF243955),
                                                border: Border.all(color: const Color(0xFF3E5D88)),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text('+$overlap', style: const TextStyle(color: Color(0xFF9AD1FF), fontSize: 11, fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(g.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: g.topics
                                              .take(6)
                                              .map((t) => InterestChip(t, compact: true, clickable: false))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          if (myGroups.isNotEmpty || suggestedGroups.isNotEmpty) const SizedBox(height: 18),
          if (myGroups.isEmpty)
            const Center(
              child: Text('No groups yet. Create one!', style: TextStyle(color: Colors.white54)),
            )
          else ..._buildGroupTiles(myGroups)
        ],
      ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildGroupTiles(List<StudyGroup> groups) {
    final List<Widget> out = [];
    for (final g in groups) {
      try {
        final hasUnread = _service.hasUnread(g.id);
        final tileChild = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (hasUnread) Container(
                width: 12, height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Color(0xFFFF4D6D), blurRadius: 8, spreadRadius: 1)],
                ),
              ),
              Expanded(child: Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
              if (g.pinnedUrl != null) Tooltip(
                message: 'Pinned resource',
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Icon(Icons.push_pin, size: 18, color: Colors.amber.shade300),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(g.description, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: g.topics.map((t) => InterestChip(t, compact: true, clickable: false)).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${g.memberNames.length} members', style: const TextStyle(color: Colors.white54)),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38)
              ],
            )
          ],
        );

  out.add(Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyGroupDetailScreen(groupId: g.id),
                ),
              ).then((_) => setState(() {}));
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF101B2D), Color(0xFF15253C)],
                ),
                border: Border.all(color: const Color(0xFF2A4A7A), width: 1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: tileChild,
            ),
          ),
        ));
      } catch (e) {
        // Skip rendering errors silently
      }
    }
    if (out.isEmpty) {
      out.add(const Center(child: Text('No groups to show (debug state)', style: TextStyle(color: Colors.white38))));
    }
    return out;
  }
}
