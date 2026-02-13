import 'dart:io';
import 'package:faith_stream_music_app/utils/constants.dart'
    show AppSizes, AppColors;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';
import '../../services/api_client.dart';
import '../../services/song_service.dart';
import '../../services/upload_service.dart';
import '../../ui/widgets/custom_text_field.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_dropdown.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lyricsController = TextEditingController();

  String _selectedLanguage = 'English';
  String _selectedGenre = 'Gospel';
  String? _selectedAlbumId;
  int? _trackNumber;

  File? _selectedCoverImage;
  File? _selectedAudioFile;

  List<dynamic> _albums = [];
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _currentUploadStep = '';

  final List<String> _languages = [
    'English',
    'Spanish',
    'Portuguese',
    'French',
    'Italian',
    'German',
    'Mandarin',
    'Arabic',
    'Hindi',
    'Swahili',
    'Other',
  ];

  final List<String> _genres = [
    'Gospel',
    'Contemporary Christian',
    'Worship',
    'Praise',
    'Hymns',
    'Christian Rock',
    'Christian Pop',
    'Christian Hip Hop',
    'Southern Gospel',
    'Traditional',
    'Instrumental',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    try {
      setState(() => _isLoading = true);

      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final songService = SongService(apiClient);

      final albums = await songService.getMyAlbums();

      if (mounted) {
        setState(() {
          _albums = albums
              .where((album) => album['status'] == 'DRAFT')
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load albums: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
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

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'm4a'], // Removed dots
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          final file = File(filePath);
          final fileSize = await file.length();

          // Check file size (max 100MB)
          if (fileSize > 100 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio file must be less than 100MB'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedAudioFile = file;
          });

          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Audio file selected: ${file.path.split('/').last}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Exception:$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick audio file: $e')),
        );
      }
    }
  }

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate audio file
    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an audio file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate lyrics (mandatory)
    if (_lyricsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter song lyrics'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentUploadStep = 'Creating song...';
    });

    try {
      // Get dependencies
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final songService = SongService(apiClient);
      final uploadService = UploadService(apiClient);

      // STEP 1: Upload audio file to S3 first (required)
      setState(() {
        _uploadProgress = 0.1;
        _currentUploadStep = 'Uploading audio file to S3...';
      });

      // Generate a temporary identifier for uploads before song creation
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      final audioUrl = await uploadService.uploadSongAudio(
        filePath: _selectedAudioFile!.path,
        songId: tempId, // Use temporary ID for S3 key
        onProgress: (progress) {
          setState(() {
            _uploadProgress = 0.1 + (progress * 0.6); // 0.1 to 0.7
            _currentUploadStep =
                'Uploading audio file to S3... ${(progress * 100).toInt()}%';
          });
        },
      );

      // Verify audio URL was obtained
      if (audioUrl.isEmpty) {
        throw Exception('Failed to upload audio file to S3');
      }

      // STEP 2: Upload cover image to S3 (optional)
      String? coverUrl;
      if (_selectedCoverImage != null) {
        setState(() {
          _uploadProgress = 0.7;
          _currentUploadStep = 'Uploading cover image to S3...';
        });

        coverUrl = await uploadService.uploadSongCover(
          filePath: _selectedCoverImage!.path,
          songId: tempId, // Use same temporary ID
          onProgress: (progress) {
            setState(() {
              _uploadProgress = 0.7 + (progress * 0.2); // 0.7 to 0.9
              _currentUploadStep =
                  'Uploading cover image to S3... ${(progress * 100).toInt()}%';
            });
          },
        );
      }

      // STEP 3: Create song record with S3 URLs
      setState(() {
        _uploadProgress = 0.9;
        _currentUploadStep = 'Creating song record...';
      });

      final song = await songService.createSong(
        title: _titleController.text.trim(),
        language: _selectedLanguage,
        genre: _selectedGenre,
        lyrics: _lyricsController.text.trim(), // Now mandatory
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        albumId: _selectedAlbumId,
        trackNumber: _trackNumber,
        audioUrl: audioUrl, // Include S3 URL
        coverImageUrl: coverUrl, // Include cover S3 URL if exists
      );

      setState(() {
        _uploadProgress = 1.0;
        _currentUploadStep = 'Complete!';
      });

      setState(() {
        _uploadProgress = 1.0;
        _currentUploadStep = 'Complete!';
      });

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Song uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _currentUploadStep = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload New Song'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Progress (if uploading)
                    if (_isUploading) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          child: Column(
                            children: [
                              Text(
                                _currentUploadStep,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSizes.paddingSm),
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryBrown,
                                ),
                              ),
                              const SizedBox(height: AppSizes.paddingSm),
                              Text(
                                '${(_uploadProgress * 100).toInt()}% Complete',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                    ],

                    // Song Details
                    Text(
                      'Song Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Title field
                    CustomTextField(
                      controller: _titleController,
                      label: 'Song Title *',
                      hint: 'Enter song title',
                      enabled: !_isUploading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a song title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Description field
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Describe your song...',
                      maxLines: 3,
                      enabled: !_isUploading,
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Language and Genre dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: CustomDropdown<String>(
                            label: 'Language *',
                            value: _selectedLanguage,
                            items: _languages
                                .map(
                                  (lang) => DropdownMenuItem(
                                    value: lang,
                                    child: Text(lang),
                                  ),
                                )
                                .toList(),
                            onChanged: _isUploading
                                ? null
                                : (value) => setState(
                                    () => _selectedLanguage = value!,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMd),
                        Expanded(
                          child: CustomDropdown<String>(
                            label: 'Genre *',
                            value: _selectedGenre,
                            items: _genres
                                .map(
                                  (genre) => DropdownMenuItem(
                                    value: genre,
                                    child: Text(genre),
                                  ),
                                )
                                .toList(),
                            onChanged: _isUploading
                                ? null
                                : (value) =>
                                      setState(() => _selectedGenre = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Album selection (optional)
                    if (_albums.isNotEmpty) ...[
                      CustomDropdown<String?>(
                        label: 'Album (Optional)',
                        hint: 'Select an album',
                        value: _selectedAlbumId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Album'),
                          ),
                          ..._albums.map(
                            (album) => DropdownMenuItem<String?>(
                              value: album['id'].toString(),
                              child: Text(album['title'] ?? 'Unnamed Album'),
                            ),
                          ),
                        ],
                        onChanged: _isUploading
                            ? null
                            : (value) =>
                                  setState(() => _selectedAlbumId = value),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                    ],

                    // Track number (if album is selected)
                    if (_selectedAlbumId != null) ...[
                      CustomTextField(
                        controller: TextEditingController(
                          text: _trackNumber?.toString() ?? '',
                        ),
                        label: 'Track Number (Optional)',
                        hint: 'e.g., 1, 2, 3...',
                        keyboardType: TextInputType.number,
                        enabled: !_isUploading,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final number = int.tryParse(value);
                            if (number == null || number < 1) {
                              return 'Please enter a valid track number';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _trackNumber = int.tryParse(value);
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                    ],

                    // Lyrics field (Mandatory)
                    CustomTextField(
                      controller: _lyricsController,
                      label: 'Lyrics *',
                      hint: 'Enter song lyrics...',
                      maxLines: 5,
                      enabled: !_isUploading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter song lyrics';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingXl),

                    // File Upload Section
                    Text(
                      'Files',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),

                    // Audio file
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _selectedAudioFile != null
                              ? Icons.music_note
                              : Icons.music_off,
                          color: _selectedAudioFile != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(
                          _selectedAudioFile != null
                              ? _selectedAudioFile!.path.split('/').last
                              : 'Select Audio File *',
                        ),
                        subtitle: _selectedAudioFile != null
                            ? const Text('Audio file selected')
                            : const Text('MP3, WAV, FLAC (max 100MB)'),
                        trailing: const Icon(Icons.folder_open),
                        onTap: _isUploading ? null : _pickAudioFile,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),

                    // Cover image
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _selectedCoverImage != null
                              ? Icons.image
                              : Icons.image_outlined,
                          color: _selectedCoverImage != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(
                          _selectedCoverImage != null
                              ? _selectedCoverImage!.path.split('/').last
                              : 'Cover Image (Optional)',
                        ),
                        subtitle: _selectedCoverImage != null
                            ? const Text('Cover image selected')
                            : const Text('JPG, PNG, WebP'),
                        trailing: const Icon(Icons.folder_open),
                        onTap: _isUploading ? null : _pickCoverImage,
                      ),
                    ),

                    if (_selectedCoverImage != null) ...[
                      const SizedBox(height: AppSizes.paddingMd),
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_selectedCoverImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSizes.paddingXl),

                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isUploading ? 'Uploading...' : 'Upload Song',
                        onPressed: _isUploading ? () {} : _uploadSong,
                        backgroundColor: AppColors.primaryBrown,
                      ),
                    ),

                    const SizedBox(height: AppSizes.paddingMd),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upload Process:',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Files will be uploaded to S3 only when you submit\n• Lyrics are mandatory for all songs\n• Your song will be reviewed before being published\n• You\'ll be notified once it\'s approved',
                            style: TextStyle(color: Colors.blue.shade600),
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
}
