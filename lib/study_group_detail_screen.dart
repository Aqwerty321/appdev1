import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_data_service.dart';
import 'firestore_service.dart';
import 'widgets/interest_chip.dart';

class StudyGroupDetailScreen extends StatefulWidget {
  final String groupId;
  const StudyGroupDetailScreen({super.key, required this.groupId});

  @override
  State<StudyGroupDetailScreen> createState() => _StudyGroupDetailScreenState();
}

class _StudyGroupDetailScreenState extends State<StudyGroupDetailScreen> {
  final UserDataService _service = UserDataService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _ticker;
  String _searchTerm = '';
  bool _showMembers = true;
  bool _showSessions = true;
  bool _isSending = false;

  static const List<String> _reactionPalette = ['👍', '🔥', '🎯'];
  static const Color _panelColor = Color(0xFF101B2D);
  static const Color _panelBorder = Color(0xFF1F3557);
  static const Color _panelOverlay = Color(0xFF15253C);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {}); // refresh countdowns / timestamps
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.markGroupSeen(widget.groupId);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(StudyGroup group) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSending = true);
    
    try {
      // Send to Firestore
      await _firestoreService.sendMessage(group.id, text);
      _messageController.clear();
      _service.markGroupSeen(group.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _editMessage(StudyGroupMessage message, StudyGroup group) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101726),
          title: const Text('Edit message', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Update your message',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (result == null || result.isEmpty) return;
    final success = await _firestoreService.editMessage(group.id, message.id, result);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update message.')), 
      );
    }
  }

  Future<void> _toggleReaction(StudyGroupMessage message, String emoji, StudyGroup group) async {
    await _firestoreService.toggleReaction(group.id, message.id, emoji);
  }

  void _activateHashtag(String tag) {
    final clean = tag.replaceAll('#', '');
    _searchController.text = clean;
    setState(() {
      _searchTerm = clean.toLowerCase();
    });
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    if (now.difference(ts).inDays == 0) {
      final tod = TimeOfDay.fromDateTime(ts);
      return tod.format(context);
    }
    final sameYear = now.year == ts.year;
    final date = '${ts.month.toString().padLeft(2, '0')}/${ts.day.toString().padLeft(2, '0')}';
    final tod = TimeOfDay.fromDateTime(ts).format(context);
    return sameYear ? '$date • $tod' : '${ts.year}/$date • $tod';
  }

  String _formatCountdown(Duration diff) {
    final past = diff.isNegative;
    final span = diff.abs();
    final days = span.inDays;
    final hours = span.inHours % 24;
    final mins = span.inMinutes % 60;
    String core;
    if (days > 0) {
      core = '${days}d${hours > 0 ? ' ${hours}h' : ''}';
    } else if (hours > 0) {
      core = '${hours}h${mins > 0 ? ' ${mins}m' : ''}';
    } else if (mins > 0) {
      core = '${mins}m';
    } else {
      core = 'moments';
    }
    return past ? '$core ago' : 'in $core';
  }

  Future<void> _editSessionNotes(GroupSession session, StudyGroup group) async {
    final controller = TextEditingController(text: session.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101726),
        title: const Text('Session notes', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Add reminders, agenda, links…',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return;
    if (result == null) return;
    await _firestoreService.updateSessionNotes(group.id, session.id, result);
  }

  Future<void> _editTopics(StudyGroup group) async {
    final selectedTopics = Set<String>.from(group.topics);
    final allTopics = ['Math', 'Science', 'History', 'English', 'Art', 'Music', 'Computer Science', 'Physics', 'Chemistry', 'Biology'];
    
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF101726),
            title: const Text('Edit Group Topics', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 400,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTopics.map((topic) {
                  final isSelected = selectedTopics.contains(topic);
                  return FilterChip(
                    label: Text(topic),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedTopics.add(topic);
                        } else {
                          selectedTopics.remove(topic);
                        }
                      });
                    },
                    backgroundColor: const Color(0xFF1A2F4D),
                    selectedColor: const Color(0xFF81A7EE),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF81A7EE),
                    ),
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: selectedTopics.isEmpty 
                  ? null 
                  : () => Navigator.pop(context, selectedTopics),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    
    if (result == null || result.isEmpty) return;
    
    final success = await _firestoreService.updateGroupTopics(group.id, result);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Topics updated' : 'Failed to update topics')),
    );
  }

  Future<void> _addMember(StudyGroup group) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101726),
        title: const Text('Add Member', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter member name or email',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF81A7EE)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF81A7EE)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Try to find user by name or email in Firestore
    final success = await _firestoreService.addMemberByNameOrEmail(group.id, result);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Member added successfully' : 'User not found or could not be added'),
      ),
    );
  }

  Future<void> _scheduleSession(StudyGroup group) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))));
    if (!mounted) return;
    if (time == null) return;
    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final titleController = TextEditingController(text: 'Sprint Session');
    final noteController = TextEditingController();
    final result = await showDialog<({String title, String notes})>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101726),
        title: const Text('New session', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, (title: titleController.text.trim(), notes: noteController.text.trim())),
            child: const Text('Schedule'),
          )
        ],
      ),
    );
    if (!mounted) return;
    if (result == null) return;
    
    await _firestoreService.addSession(
      groupId: group.id,
      scheduledAt: scheduled,
      title: result.title,
      notes: result.notes.isEmpty ? null : result.notes,
    );
  }

  Future<void> _copySnapshot(StudyGroup group, List<GroupSession> sessions) async {
    final buffer = StringBuffer()
      ..writeln('Study Group: ${group.name}')
      ..writeln('Topics: ${group.topics.join(', ')}')
      ..writeln('Members (${group.memberNames.length}): ${group.memberNames.join(', ')}');
    if (sessions.isNotEmpty) {
      final next = sessions.where((s) => s.scheduledAt.isAfter(DateTime.now())).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      if (next.isNotEmpty) {
        final upcoming = next.first;
        buffer.writeln('Next session: ${upcoming.title} ${upcoming.scheduledAt}');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group snapshot copied to clipboard')), 
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudyGroup?>(
      stream: _firestoreService.watchGroup(widget.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Study Group'),
              backgroundColor: const Color(0xFF13233F),
              iconTheme: const IconThemeData(color: Color(0xFF81A7EE)),
            ),
            backgroundColor: Colors.black,
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF81A7EE)),
            ),
          );
        }
        
        if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Group'),
          backgroundColor: const Color(0xFF13233F),
          iconTheme: const IconThemeData(color: Color(0xFF81A7EE)),
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text('This group could not be found.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final isMember = group.memberNames.contains(_service.currentUser.name);
    final isAdmin = group.isAdmin(_service.currentUser.name);
    final memberNames = group.memberNames.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Now stream messages and sessions from Firestore
    return StreamBuilder<List<StudyGroupMessage>>(
      stream: _firestoreService.watchMessages(widget.groupId),
      builder: (context, messagesSnapshot) {
        final messages = messagesSnapshot.data ?? [];
        final filteredMessages = messages.where((m) {
          if (_searchTerm.isEmpty) return true;
          final haystack = '${m.authorName} ${m.content}'.toLowerCase();
          return haystack.contains(_searchTerm);
        }).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return StreamBuilder<List<GroupSession>>(
          stream: _firestoreService.watchSessions(widget.groupId),
          builder: (context, sessionsSnapshot) {
            final sessions = sessionsSnapshot.data ?? [];
            final sortedSessions = sessions.toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF13233F),
        iconTheme: const IconThemeData(color: Color(0xFF81A7EE)), // Light blue back button
        title: Text(group.name, style: const TextStyle(color: Color(0xFF81A7EE))),
        actions: [
          IconButton(
            tooltip: 'Copy snapshot',
            icon: const Icon(Icons.camera_outlined, color: Color(0xFF81A7EE)),
            onPressed: () => _copySnapshot(group, sortedSessions),
          ),
          if (isMember)
            IconButton(
              tooltip: 'Leave group',
              icon: const Icon(Icons.logout, color: Color(0xFFFF7F7F)),
              onPressed: () async {
                await _firestoreService.leaveGroup(group.id);
              },
            )
          else
            IconButton(
              tooltip: 'Join group',
              icon: const Icon(Icons.login, color: Color(0xFF81A7EE)),
              onPressed: () async {
                await _firestoreService.joinGroup(group.id);
              },
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _panelBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(group.description, style: const TextStyle(color: Colors.white70, height: 1.4)),
                if (group.pinnedUrl != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: group.pinnedUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pinned link copied to clipboard.')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16243A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2D4A72)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: Color(0xFF9AD1FF), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(group.pinnedUrl!, style: const TextStyle(color: Color(0xFF9AD1FF), decoration: TextDecoration.underline))),
                          const SizedBox(width: 8),
                          const Text('Copy', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.topics
                            .map((t) => InterestChip(t, compact: true, clickable: false))
                            .toList(),
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF81A7EE), size: 20),
                        tooltip: 'Edit topics',
                        onPressed: () => _editTopics(group),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.circle, color: group.memberNames.length > 6 ? const Color(0xFF21D07A) : const Color(0xFFFB9B5A), size: 12),
                    const SizedBox(width: 6),
                    Text('${group.memberNames.length} members', style: const TextStyle(color: Colors.white70)),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _addMember(group),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2F4D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF81A7EE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add, color: Color(0xFF81A7EE), size: 16),
                              SizedBox(width: 4),
                              Text('Add Member', style: TextStyle(color: Color(0xFF81A7EE), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isAdmin)
                      TextButton.icon(
                        onPressed: () => _scheduleSession(group),
                        icon: const Icon(Icons.event, color: Color(0xFF81A7EE)),
                        label: const Text('Schedule', style: TextStyle(color: Color(0xFF81A7EE))),
                      ),
                    const SizedBox(width: 4),
                    if (isAdmin)
                      TextButton.icon(
                        onPressed: () async {
                          final controller = TextEditingController(text: group.pinnedUrl ?? '');
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF101726),
                              title: const Text('Pinned resource', style: TextStyle(color: Colors.white)),
                              content: TextField(
                                controller: controller,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'https://link…',
                                  hintStyle: TextStyle(color: Colors.white38),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                              ],
                            ),
                          );
                          if (result == null) return;
                          await _firestoreService.setPinnedUrl(group.id, result.isEmpty ? null : result);
                        },
                        icon: const Icon(Icons.push_pin, color: Color(0xFF81A7EE)),
                        label: const Text('Pin link', style: TextStyle(color: Color(0xFF81A7EE))),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _panelBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Row(
                    children: [
                      const Text('Members', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF233A5E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(memberNames.length.toString(), style: const TextStyle(color: Color(0xFF9AD1FF), fontSize: 11)),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Color(0xFF81A7EE), size: 20),
                        tooltip: 'Add Member',
                        onPressed: isAdmin ? () => _addMember(group) : null,
                      ),
                      IconButton(
                        icon: Icon(_showMembers ? Icons.expand_less : Icons.expand_more, color: Colors.white54),
                        onPressed: () => setState(() => _showMembers = !_showMembers),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  crossFadeState: _showMembers ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 220),
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: memberNames.map((name) {
                        final isMemberAdmin = group.isAdmin(name);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1625),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1F3557)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: isMemberAdmin ? const Color(0xFFFFD700) : const Color(0xFF81A7EE),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMemberAdmin ? const Color(0xFF3D2A00) : const Color(0xFF1A2F4D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isMemberAdmin ? const Color(0xFFFFD700) : const Color(0xFF81A7EE),
                                  ),
                                ),
                                child: Text(
                                  isMemberAdmin ? 'ADMIN' : 'MEMBER',
                                  style: TextStyle(
                                    color: isMemberAdmin ? const Color(0xFFFFD700) : const Color(0xFF81A7EE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isAdmin && name != _service.currentUser.name) ...[
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                                  color: const Color(0xFF101726),
                                  onSelected: (value) async {
                                    if (value == 'promote' && !isMemberAdmin) {
                                      final success = await _firestoreService.promoteToAdmin(group.id, name);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(success ? '$name promoted to admin' : 'Failed to promote member')),
                                        );
                                      }
                                    } else if (value == 'remove' && !isMemberAdmin) {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(0xFF101726),
                                          title: const Text('Remove member?', style: TextStyle(color: Colors.white)),
                                          content: Text('Remove $name from this group?', style: const TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        // Find member UID - we need to track this
                                        final memberUids = group.memberUids.toList();
                                        final memberNamesList = group.memberNames.toList();
                                        final index = memberNamesList.indexOf(name);
                                        final memberUid = index >= 0 && index < memberUids.length ? memberUids[index] : '';
                                        
                                        final success = await _firestoreService.removeMember(group.id, name, memberUid);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(success ? '$name removed from group' : 'Failed to remove member')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isMemberAdmin)
                                      const PopupMenuItem(
                                        value: 'promote',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_upward, color: Color(0xFFFFD700), size: 18),
                                            SizedBox(width: 8),
                                            Text('Promote to Admin', style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    if (!isMemberAdmin)
                                      const PopupMenuItem(
                                        value: 'remove',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_remove, color: Colors.redAccent, size: 18),
                                            SizedBox(width: 8),
                                            Text('Remove Member', style: TextStyle(color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  secondChild: const SizedBox(height: 0),
                ),
              ],
            ),
          ),
          if (sortedSessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _panelBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Sessions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: Icon(_showSessions ? Icons.expand_less : Icons.expand_more, color: Colors.white54),
                      onPressed: () => setState(() => _showSessions = !_showSessions),
                    ),
                  ),
                  AnimatedCrossFade(
                    crossFadeState: _showSessions ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 220),
                    firstChild: Column(
                      children: sortedSessions.map((session) {
                        final diff = session.scheduledAt.difference(DateTime.now());
                        final countdown = _formatCountdown(diff);
                        final upcoming = !diff.isNegative;
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _panelOverlay,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF28466B)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(session.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: upcoming ? const Color(0xFF1E834E) : const Color(0xFF4B2D5E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(countdown, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_formatTimestamp(session.scheduledAt), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              if ((session.notes ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(session.notes!, style: const TextStyle(color: Colors.white70)),
                              ],
                              if (isAdmin) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _editSessionNotes(session, group),
                                    icon: const Icon(Icons.edit_note, color: Color(0xFF9AD1FF)),
                                    label: const Text('Edit notes', style: TextStyle(color: Color(0xFF9AD1FF))),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    secondChild: const SizedBox(height: 0),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Message board', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0B1626),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          suffixIcon: _searchTerm.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchTerm = '');
                                  },
                                )
                              : null,
                          hintText: 'Search messages or #hashtags',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E2E45)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E2E45)),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchTerm = value.trim().toLowerCase();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (filteredMessages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No messages yet. Start the conversation!', style: TextStyle(color: Colors.white54)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: filteredMessages.map((m) {
                        final mine = m.authorName == _service.currentUser.name;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: _MessageBubble(
                              message: m,
                              isMine: mine,
                              highlight: _searchTerm.isNotEmpty && m.content.toLowerCase().contains(_searchTerm),
                              timestampBuilder: _formatTimestamp,
                              onHashtagTap: _activateHashtag,
                              onReactionTap: (emoji) => _toggleReaction(m, emoji, group),
                              onEdit: mine ? () => _editMessage(m, group) : null,
                              reactionPalette: _reactionPalette,
                              currentUser: _service.currentUser.name,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                Divider(color: Colors.white10, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _messageController,
                        maxLines: null,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: isMember ? 'Share an update, link, or ask a question…' : 'Join the group to send messages',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF0B1626),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E2E45)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E2E45)),
                          ),
                        ),
                        enabled: isMember,
                        onSubmitted: (_) => _sendMessage(group),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: (isMember && !_isSending) ? () => _sendMessage(group) : null,
                          icon: _isSending 
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text('Post'),
                        ),
                      )
                    ],
                  ),
                ),
                ],
              ),
            ),
          ],
        ),
      );
          }, // Close sessions StreamBuilder
        );
      }, // Close messages StreamBuilder
    );
    },
  );
  }
}

class _MessageBubble extends StatelessWidget {
  final StudyGroupMessage message;
  final bool isMine;
  final bool highlight;
  final String Function(DateTime) timestampBuilder;
  final void Function(String hashtag) onHashtagTap;
  final void Function(String emoji) onReactionTap;
  final VoidCallback? onEdit;
  final List<String> reactionPalette;
  final String currentUser;

  static final RegExp _hashRegex = RegExp(r'(#[A-Za-z0-9_]+)');

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.highlight,
    required this.timestampBuilder,
    required this.onHashtagTap,
    required this.onReactionTap,
    required this.reactionPalette,
    required this.currentUser,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final reactionsByType = <String, List<MessageReaction>>{};
    for (final reaction in message.reactions) {
      reactionsByType.putIfAbsent(reaction.type, () => []).add(reaction);
    }
    final Color bubbleColor = isMine ? const Color(0xFF0F6F54) : const Color(0xFF17263A);
    final Color appliedColor = highlight ? const Color(0xFF234B73) : bubbleColor;
    final BorderRadius radius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          );
    final Color borderColor = highlight ? const Color(0xFF56C6FF) : const Color(0x26000000);

    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: appliedColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: highlight ? 1.4 : 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.authorName,
                      style: TextStyle(
                        color: isMine ? const Color(0xFF9AD1FF) : const Color(0xFFE1CCFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timestampBuilder(message.timestamp),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    _BubbleIconButton(
                      icon: Icons.edit,
                      tooltip: 'Edit message',
                      onTap: onEdit!,
                    ),
                  _ReactionTrigger(
                    palette: reactionPalette,
                    onSelected: onReactionTap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRichContent(context, message.content),
          if (message.editedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text('Edited ${timestampBuilder(message.editedAt!)}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ),
          if (reactionsByType.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: reactionsByType.entries.map((entry) {
                final emoji = entry.key;
                final users = entry.value;
                final selected = users.any((r) => r.userName == currentUser);
                return GestureDetector(
                  onTap: () => onReactionTap(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0x33FFC107) : const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? const Color(0xFFFFC107) : Colors.white10, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(users.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichContent(BuildContext context, String content) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }
    final spans = <TextSpan>[];
    int currentIndex = 0;
    final matches = _hashRegex.allMatches(content);
    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: content.substring(currentIndex, match.start)));
      }
      final tag = match.group(0)!;
      spans.add(TextSpan(
        text: tag,
        style: const TextStyle(color: Color(0xFF8BE9FF), fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()..onTap = () => onHashtagTap(tag),
      ));
      currentIndex = match.end;
    }
    if (currentIndex < content.length) {
      spans.add(TextSpan(text: content.substring(currentIndex)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 14.5),
        children: spans,
      ),
    );
  }
}

class _BubbleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BubbleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
      ),
    );
  }
}

class _ReactionTrigger extends StatelessWidget {
  final List<String> palette;
  final ValueChanged<String> onSelected;

  const _ReactionTrigger({
    required this.palette,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'React',
      onSelected: onSelected,
      color: const Color(0xFF101B2D),
      surfaceTintColor: Colors.transparent,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F3557)),
      ),
      itemBuilder: (context) => palette
          .map(
            (emoji) => PopupMenuItem<String>(
              value: emoji,
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
          )
          .toList(),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.emoji_emotions_outlined, color: Colors.white70, size: 18),
      ),
    );
  }
}
