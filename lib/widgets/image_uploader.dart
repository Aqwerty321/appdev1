import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  // This will hold the image data in memory
  Uint8List? _imageData;
  bool _isLoading = false;
  String? _uploadedImageUrl;
  String _status = 'No image selected.';

  /// Picks an image from the user's device and reads it into memory.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // This will open the file picker on web
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Read the image data as bytes
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = bytes;
        _status = 'Image selected. Ready to upload.';
        _uploadedImageUrl = null; // Clear previous upload
      });
    } else {
      setState(() {
        _status = 'No image selected.';
      });
    }
  }

  /// Uploads the selected image data to Firebase Storage.
  Future<void> _uploadImage() async {
    if (_imageData == null) {
      setState(() {
        _status = 'Please select an image first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Uploading...';
    });

    try {
      // NOTE: In a real app, you'd get the user's ID from Firebase Auth
      // final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      // For this example, we'll use a fixed path.
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref('uploads/$fileName');

      // Create metadata for the file. This is important for the browser to
      // correctly display the image.
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload the data using putData. This is the web-friendly way.
      final UploadTask uploadTask = ref.putData(_imageData!, metadata);

      // Await the upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isLoading = false;
        _status = 'Upload successful!';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      color: Colors.deepPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display the picked image preview or the uploaded image
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : _uploadedImageUrl != null
                        ? Image.network(_uploadedImageUrl!) // Use standard Image widget
                        : _imageData != null
                            ? Image.memory(_imageData!) // Display picked image from memory
                            : const Icon(Icons.photo_camera, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(_status, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Image'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  // Disable the button if no image is picked or if it's loading
                  onPressed: (_imageData == null || _isLoading) ? null : _uploadImage,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}