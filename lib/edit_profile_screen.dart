import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'user_data_service.dart';
import 'firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  // ✅ Add fields to accept the current profile data
  final String currentName;
  final String currentBio;
  final Uint8List? currentImageData;

  const EditProfileScreen({
    super.key,
    // ✅ Make them required in the constructor
    required this.currentName,
    required this.currentBio,
    this.currentImageData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _interestController;
  Uint8List? _selectedImageData;
  final UserDataService _userDataService = UserDataService();
  final FirestoreService _firestoreService = FirestoreService();
  late Set<String> _interests;
  bool _isSaving = false;

  // ✅ Define your app's color theme for easy reuse
  static const Color _darkBlue = Color.fromARGB(255, 19, 35, 63);
  static const Color _neonPurple = Color(0xFF986AF0);
  static const Color _lightBlue = Color.fromARGB(255, 129, 167, 238);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _bioController = TextEditingController(text: widget.currentBio);
    _interestController = TextEditingController();
    _selectedImageData = widget.currentImageData;
    // Initialize interests from the central service
    _interests = {..._userDataService.currentUser.interests};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageData = bytes;
      });
    }
  }

  String _normalizeTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final cleaned = t.startsWith('#') ? t.substring(1) : t;
    return cleaned.toLowerCase();
  }

  void _addInterest([String? value]) {
    final tag = _normalizeTag(value ?? _interestController.text);
    if (tag.isEmpty) return;
    setState(() {
      _interests.add(tag);
      _interestController.clear();
    });
  }

  void _removeInterest(String tag) {
    setState(() {
      _interests.remove(tag);
    });
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      // ✅ Upload profile image FIRST if changed (this saves imageUrl to Firestore)
      if (_selectedImageData != null) {
        final bool imageChanged = widget.currentImageData == null || 
            !_bytesEqual(_selectedImageData!, widget.currentImageData!);
        
        if (imageChanged) {
          await _firestoreService.uploadProfileImage(_selectedImageData!);
        }
      }

      // ✅ Update the data in the central service
      _userDataService.updateUserData(
        name: _nameController.text,
        bio: _bioController.text,
        image: _selectedImageData,
        interests: _interests,
      );

      // ✅ Save to Firestore for multi-user sync
      await _firestoreService.saveUserProfile(_userDataService.currentUser);

      if (mounted) {
        // Just pop the screen, no need to return data
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Changed to solid black
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: _lightBlue)),
        backgroundColor: _darkBlue, // ✅ Use theme color
        iconTheme: const IconThemeData(color: _lightBlue), // Make back button match
      ),
      // Use a LayoutBuilder to get screen constraints
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20), // Add some top spacing
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              // ✅ Increased radius for a larger profile picture
                              radius: 80,
                              backgroundColor: Colors.grey.shade900,
                              backgroundImage: _selectedImageData != null
                                  ? MemoryImage(_selectedImageData!)
                                  : null,
                              child: _selectedImageData == null
                                  ? const Icon(Icons.person, size: 80, color: Colors.white30)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: _darkBlue,
                                radius: 22,
                                child: IconButton(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.camera_alt),
                                  color: _neonPurple, // ✅ Use theme color
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: _neonPurple.withOpacity(0.8)),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: _neonPurple, width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _bioController,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                        maxLines: 5, // Made bio taller
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          labelStyle: TextStyle(color: _neonPurple.withOpacity(0.8)),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: _neonPurple, width: 2.0),
                          ),
                        ),
                      ),
                      // Interests section
                      const Text(
                        'Interests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interests.map((tag) {
                          return InputChip(
                            label: Text('#$tag', style: const TextStyle(color: Colors.white)),
                            backgroundColor: _darkBlue,
                            selectedColor: _neonPurple.withOpacity(0.25),
                            side: const BorderSide(color: _neonPurple),
                            onDeleted: () => _removeInterest(tag),
                            deleteIconColor: _lightBlue,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _interestController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add interest, e.g. #flutter',
                                hintStyle: const TextStyle(color: Colors.white54),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: _neonPurple, width: 2.0),
                                ),
                              ),
                              onSubmitted: _addInterest,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addInterest,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _neonPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ✅ Spacer pushes the button to the bottom
                      const Spacer(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _neonPurple, // ✅ Use theme color
                          foregroundColor: Colors.white, // Text color
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
