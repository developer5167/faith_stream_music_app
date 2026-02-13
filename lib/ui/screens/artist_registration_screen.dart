import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../utils/constants.dart';
import '../../utils/image_upload_helper.dart';
import '../../utils/video_recording_helper.dart';
import '../../services/upload_service.dart';
import '../../repositories/user_repository.dart';

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
  final _govtIdUrlController = TextEditingController();
  final _addressProofUrlController = TextEditingController();
  final _selfieVideoUrlController = TextEditingController();
  final List<TextEditingController> _supportingLinkControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    _artistNameController.dispose();
    _bioController.dispose();
    _govtIdUrlController.dispose();
    _addressProofUrlController.dispose();
    _selfieVideoUrlController.dispose();
    for (final c in _supportingLinkControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      // Check if selfie video is uploaded
      if (_selfieVideoUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please record your selfie video'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<ProfileBloc>().add(
        ProfileRequestArtist(
          artistName: _artistNameController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          govtIdUrl: _govtIdUrlController.text.trim().isEmpty
              ? null
              : _govtIdUrlController.text.trim(),
          addressProofUrl: _addressProofUrlController.text.trim().isEmpty
              ? null
              : _addressProofUrlController.text.trim(),
          selfieVideoUrl: _selfieVideoUrlController.text.trim().isEmpty
              ? null
              : _selfieVideoUrlController.text.trim(),
          supportingLinks: _supportingLinkControllers
              .map((c) => c.text.trim())
              .where((link) => link.isNotEmpty)
              .toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
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
                  color: AppColors.primaryGold.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColors.primaryGold,
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
                  'Upload documents for identity verification. This helps us maintain platform security.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),

                // Government ID
                TextFormField(
                  controller: _govtIdUrlController,
                  readOnly: _govtIdUrlController.text.isNotEmpty,
                  decoration: InputDecoration(
                    labelText: 'Government ID (URL)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.badge,
                      color: _govtIdUrlController.text.isNotEmpty
                          ? Colors.green
                          : null,
                    ),
                    hintText: _govtIdUrlController.text.isEmpty
                        ? 'https://example.com/govt-id.jpg'
                        : null,
                    suffixIcon: _govtIdUrlController.text.isNotEmpty
                        ? const Icon(Icons.lock, color: Colors.green)
                        : null,
                    filled: _govtIdUrlController.text.isNotEmpty,
                    fillColor: _govtIdUrlController.text.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : null,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                if (_govtIdUrlController.text.isEmpty)
                  _buildDocumentUploadCard(
                    context,
                    icon: Icons.upload_file,
                    title: 'Upload Government ID',
                    description: 'Passport, Driver\'s License, or National ID',
                    onTap: () async {
                      final publicUrl =
                          await ImageUploadHelper.pickAndUploadImage(
                            context: context,
                            uploadType: UploadService.artistProfile,
                          );

                      if (publicUrl != null) {
                        setState(() {
                          _govtIdUrlController.text = publicUrl;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Government ID uploaded!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                const SizedBox(height: AppSizes.paddingMd),

                // Address Proof
                TextFormField(
                  controller: _addressProofUrlController,
                  readOnly: _addressProofUrlController.text.isNotEmpty,
                  decoration: InputDecoration(
                    labelText: 'Address Proof (URL)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.home,
                      color: _addressProofUrlController.text.isNotEmpty
                          ? Colors.green
                          : null,
                    ),
                    hintText: _addressProofUrlController.text.isEmpty
                        ? 'https://example.com/address-proof.jpg'
                        : null,
                    suffixIcon: _addressProofUrlController.text.isNotEmpty
                        ? const Icon(Icons.lock, color: Colors.green)
                        : null,
                    filled: _addressProofUrlController.text.isNotEmpty,
                    fillColor: _addressProofUrlController.text.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : null,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                if (_addressProofUrlController.text.isEmpty)
                  _buildDocumentUploadCard(
                    context,
                    icon: Icons.upload_file,
                    title: 'Upload Address Proof',
                    description:
                        'Utility bill, Bank statement, or Lease agreement',
                    onTap: () async {
                      final publicUrl =
                          await ImageUploadHelper.pickAndUploadImage(
                            context: context,
                            uploadType: UploadService.artistProfile,
                          );

                      if (publicUrl != null) {
                        setState(() {
                          _addressProofUrlController.text = publicUrl;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address proof uploaded!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
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

                // Selfie Video URL (hidden from user)
                if (_selfieVideoUrlController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: AppSizes.paddingMd),
                        Expanded(
                          child: Text(
                            'Selfie video uploaded successfully!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_selfieVideoUrlController.text.isEmpty) ...[
                  _buildDocumentUploadCard(
                    context,
                    icon: Icons.videocam,
                    title: 'Record Selfie Video',
                    description:
                        'Tap to start recording your introduction video',
                    onTap: () async {
                      try {
                        // ✅ Request Camera + Microphone Permission
                        final cameraStatus = await Permission.camera.request();
                        final micStatus = await Permission.microphone.request();

                        // ✅ Handle denial
                        if (!cameraStatus.isGranted || !micStatus.isGranted) {
                          if (cameraStatus.isPermanentlyDenied ||
                              micStatus.isPermanentlyDenied) {
                            await openAppSettings();
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Camera and Microphone permissions are required",
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        // ✅ Continue only if granted
                        final userRepository = context.read<UserRepository>();
                        final uploadService = UploadService(
                          userRepository.apiClient,
                        );

                        final videoUrl =
                            await VideoRecordingHelper.recordAndUploadSelfieVideo(
                              context: context,
                              uploadService: uploadService,
                            );

                        if (videoUrl != null) {
                          setState(() {
                            _selfieVideoUrlController.text = videoUrl;
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                  ),
                ],
                const SizedBox(height: AppSizes.paddingXl),

                // Info Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
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
                const SizedBox(height: AppSizes.paddingXl),

                // Supporting Links Section
                Text(
                  'Supporting Links',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),

                // Note card for supporting links
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: AppSizes.paddingSm),
                        Expanded(
                          child: Text(
                            'Providing links to your public social media profiles '
                            '(Facebook, Instagram, X, YouTube, Spotify, Google, etc.) '
                            'helps us verify your identity as a real artist and speeds up '
                            'the approval process significantly.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),

                // Dynamic supporting link fields
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
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _supportingLinkControllers
                                    .removeAt(index)
                                    .dispose();
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),

                // Add more link button
                if (_supportingLinkControllers.length < 6)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _supportingLinkControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add another link'),
                  ),
                const SizedBox(height: AppSizes.paddingLg),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Submit Application',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBrown),
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
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
