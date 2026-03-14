import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../utils/constants.dart';
import '../../utils/image_upload_helper.dart';
import '../../utils/video_recording_helper.dart';
import '../../services/upload_service.dart';
import '../../repositories/user_repository.dart';
import '../../config/app_theme.dart';

class ArtistRegistrationScreen extends StatefulWidget {
  const ArtistRegistrationScreen({super.key});

  @override
  State<ArtistRegistrationScreen> createState() =>
      _ArtistRegistrationScreenState();
}

class _ArtistRegistrationScreenState extends State<ArtistRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Local file references
  XFile? _govtIdFile;
  String? _selfieVideoPath;
  
  bool _isUploading = false;
  String _uploadStatus = '';

  final List<TextEditingController> _supportingLinkControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    _artistNameController.dispose();
    _bioController.dispose();
    for (final c in _supportingLinkControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation
    if (_govtIdFile == null) {
      _showError('Please upload Government ID');
      return;
    }
    if (_selfieVideoPath == null) {
      _showError('Please record your selfie video');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Starting application...';
    });

    try {
      final userRepository = context.read<UserRepository>();
      final uploadService = UploadService(userRepository.apiClient);

      // 1. Upload Govt ID
      setState(() => _uploadStatus = 'Uploading Government ID...');
      final govtIdUrl = await uploadService.uploadFile(
        filePath: _govtIdFile!.path,
        uploadType: UploadService.artistProfile,
      );

      // 2. Upload Selfie Video
      setState(() => _uploadStatus = 'Uploading Selfie Video...');
      final selfieVideoUrl = await uploadService.uploadArtistSelfieVideo(
        filePath: _selfieVideoPath!,
      );

      // 3. Submit to DB
      if (mounted) {
        setState(() => _uploadStatus = 'Submitting application...');
        context.read<ProfileBloc>().add(
          ProfileRequestArtist(
            artistName: _artistNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            govtIdUrl: govtIdUrl,
            selfieVideoUrl: selfieVideoUrl,
            supportingLinks: _supportingLinkControllers
                .map((c) => c.text.trim())
                .where((link) => link.isNotEmpty)
                .toList(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Upload failed: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileOperationSuccess) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileError) {
          setState(() => _isUploading = false);
          _showError(state.message);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: const Text('Become an Artist')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Card(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: theme.colorScheme.secondary,
                              size: 40,
                            ),
                            const SizedBox(width: AppSizes.paddingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share Your Music',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Join our platform as an artist and reach thousands of listeners',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXl),

                    // Instructions
                    Text(
                      'Required Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      'Please provide the following details to complete your artist registration. All fields marked with * are mandatory.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLg),

                    // Artist Name
                    TextFormField(
                      controller: _artistNameController,
                      enabled: !_isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Artist Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Your stage/artist name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Artist name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      enabled: !_isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Artist Bio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                        hintText: 'Tell us about your music and style...',
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Documents Section
                    Text(
                      'Verification Documents',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      'Provide identity verification documents. Files will be uploaded when you submit the application.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Government ID
                    _buildFileSelectionCard(
                      context,
                      icon: Icons.badge,
                      title: 'Government ID *',
                      description: _govtIdFile == null 
                          ? 'Upload Passport, Driver\'s License, or National ID'
                          : 'File selected: ${File(_govtIdFile!.path).uri.pathSegments.last}',
                      isSelected: _govtIdFile != null,
                      onTap: _isUploading ? null : () async {
                        final File? file = await ImageUploadHelper.pickImage();
                        if (file != null) {
                          setState(() {
                            _govtIdFile = XFile(file.path);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingXl),

                    // Selfie Video Section
                    Text(
                      'Selfie Video *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      'Record a short video (3-30 seconds) introducing yourself. Say "Hi" and your name clearly.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    _buildFileSelectionCard(
                      context,
                      icon: Icons.videocam,
                      title: 'Selfie Video *',
                      description: _selfieVideoPath == null
                          ? 'Record your introduction video'
                          : 'Video recorded and ready for upload',
                      isSelected: _selfieVideoPath != null,
                      onTap: _isUploading ? null : () async {
                        try {
                          final cameraStatus = await Permission.camera.request();
                          final micStatus = await Permission.microphone.request();

                          if (!cameraStatus.isGranted || !micStatus.isGranted) {
                            if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
                              await openAppSettings();
                            }
                            _showError("Camera and Microphone permissions are required");
                            return;
                          }

                          final cameras = await availableCameras();
                          if (cameras.isEmpty) throw Exception('No cameras available');
                          
                          final frontCamera = cameras.firstWhere(
                            (c) => c.lensDirection == CameraLensDirection.front,
                            orElse: () => cameras.first,
                          );

                          if (context.mounted) {
                            final path = await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (context) => SelfieVideoRecordingScreen(camera: frontCamera),
                                fullscreenDialog: true,
                              ),
                            );

                            if (path != null) {
                              setState(() {
                                _selfieVideoPath = path;
                              });
                            }
                          }
                        } catch (e) {
                          _showError('Failed to record video: $e');
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingXl),

                    // Info Card
                    Card(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSizes.paddingMd),
                            Expanded(
                              child: Text(
                                'Your application will be reviewed within 24-48 hours. You\'ll be notified once approved.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
                      child: Text(
                        'Note: If your application is rejected, you will need to wait 30 days before you can submit a new request.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade400,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXl),

                    // Supporting Links
                    Text(
                      'Supporting Links',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    ..._supportingLinkControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                enabled: !_isUploading,
                                decoration: InputDecoration(
                                  labelText: 'Profile Link ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.link),
                                  hintText: 'https://instagram.com/yourprofile',
                                ),
                                keyboardType: TextInputType.url,
                              ),
                            ),
                            if (_supportingLinkControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: _isUploading ? null : () {
                                  setState(() {
                                    _supportingLinkControllers.removeAt(index).dispose();
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),

                    if (_supportingLinkControllers.length < 6)
                      TextButton.icon(
                        onPressed: _isUploading ? null : () {
                          setState(() {
                            _supportingLinkControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add another link'),
                      ),
                    const SizedBox(height: AppSizes.paddingXl),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.brightness == Brightness.dark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary,
                          foregroundColor: theme.brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isUploading ? 'Submitting...' : 'Submit Application',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          _uploadStatus,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please do not close the app while we process your request.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : icon,
                  color: isSelected ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
