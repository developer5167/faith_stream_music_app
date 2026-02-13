import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/album_service.dart';
import '../../services/upload_service.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import 'package:image_picker/image_picker.dart';

class CreateAlbumScreen extends StatefulWidget {
  const CreateAlbumScreen({super.key});

  @override
  State<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends State<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedLanguage = 'English';
  String _selectedReleaseType = 'ALBUM';
  File? _selectedCoverImage;
  bool _isSubmitting = false;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Kannada',
    'Bengali',
    'Marathi',
  ];

  final List<String> _releaseTypes = ['ALBUM', 'EP', 'SINGLE'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedCoverImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _submitAlbum() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get dependencies from context
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final albumService = AlbumService(apiClient);
      final uploadService = UploadService(apiClient);

      // STEP 1: Create album record first (without cover)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating album...'),
            ],
          ),
        ),
      );

      final album = await albumService.createAlbum(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        language: _selectedLanguage,
        releaseType: _selectedReleaseType,
      );

      final albumId = album['id'].toString();

      // STEP 2: Upload cover if selected
      if (_selectedCoverImage != null && mounted) {
        // Update dialog message
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Uploading cover...'),
              ],
            ),
          ),
        );

        final coverUrl = await uploadService.uploadFile(
          filePath: _selectedCoverImage!.path,
          uploadType: UploadService.albumCover,
          resourceId: albumId,
        );

        // STEP 3: Update album with cover URL
        await albumService.updateAlbumCover(
          albumId: albumId,
          coverImageUrl: coverUrl,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Album created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to dashboard
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close any dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create album: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Album'),
        backgroundColor: AppColors.primaryBrown,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          children: [
            // Cover Image Section
            Center(
              child: GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusMd,
                    ),
                    border: Border.all(color: AppColors.primaryBrown, width: 2),
                  ),
                  child: _selectedCoverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusMd,
                          ),
                          child: Image.file(
                            _selectedCoverImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: AppColors.primaryBrown,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Cover',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryBrown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(Optional)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Album Title *',
                hintText: 'Enter album title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                prefixIcon: const Icon(Icons.album),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter album title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingMd),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter album description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingMd),

            // Language Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Language *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                prefixIcon: const Icon(Icons.language),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppSizes.paddingMd),

            // Release Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedReleaseType,
              decoration: InputDecoration(
                labelText: 'Release Type *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _releaseTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedReleaseType = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppSizes.paddingXl),

            // Info Card
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cover photo will be uploaded after album is created',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAlbum,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Album',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
