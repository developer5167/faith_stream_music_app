import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick and upload an image
  static Future<String?> pickAndUploadImage({
    required BuildContext context,
    required String uploadType,
    String? resourceId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Validate aspect ratio for profile and cover pictures (1:1 only)
      if (uploadType == UploadService.userProfile ||
          uploadType == UploadService.artistProfile ||
          uploadType == UploadService.albumCover ||
          uploadType == UploadService.songCover) {
        final isSquare = await isSquareImage(File(image.path));
        if (!isSquare) {
          if (context.mounted) {
            String typeName = 'profile picture';
            if (uploadType == UploadService.albumCover || uploadType == UploadService.songCover) {
              typeName = 'cover image';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select a square (1:1) image for your $typeName.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return null;
        }
      }

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Upload
      final storageService = StorageService(
        FlutterSecureStorage(),
        await SharedPreferences.getInstance(),
      );
      final apiClient = ApiClient(storageService);
      final uploadService = UploadService(apiClient);

      final publicUrl = await uploadService.uploadFile(
        filePath: image.path,
        uploadType: uploadType,
        resourceId: resourceId,
        onProgress: onProgress,
      );

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return publicUrl;
    } catch (e) {
      // Close loading if open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  /// Pick image from gallery
  static Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Take photo with camera
  static Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickImage();
                if (context.mounted && file != null) {
                  Navigator.pop(context, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final file = await takePhoto();
                if (context.mounted && file != null) {
                  Navigator.pop(context, file);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Check if an image is square (1:1 aspect ratio)
  static Future<bool> isSquareImage(File file, {double tolerance = 0.05}) async {
    try {
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final ratio = image.width / image.height;
      return (ratio - 1.0).abs() < tolerance;
    } catch (e) {
      debugPrint('Error validating image aspect ratio: $e');
      return false;
    }
  }
}
