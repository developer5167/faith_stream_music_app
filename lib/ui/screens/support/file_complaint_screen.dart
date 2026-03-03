import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_client.dart';
import '../../../services/complaint_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class FileComplaintScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContentType;

  const FileComplaintScreen({
    super.key,
    this.initialTitle,
    this.initialContentType,
  });

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _artistNameController = TextEditingController();
  final _songNameController = TextEditingController();
  final _albumNameController = TextEditingController();
  String? _selectedContentType;
  bool _isLoading = false;
  bool _serviceReady = false;

  final List<String> _contentTypes = [
    'SONG',
    'ALBUM',
    'ARTIST',
    'PLAYLIST',
    'OTHER',
  ];

  late final ComplaintService _complaintService;

  bool get _isCopyrightMode =>
      widget.initialTitle != null &&
      widget.initialTitle!.toLowerCase().contains('copyright');

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _selectedContentType = widget.initialContentType;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storageService = StorageService(
        const FlutterSecureStorage(),
        await SharedPreferences.getInstance(),
      );
      final apiClient = ApiClient(storageService);
      _complaintService = ComplaintService(apiClient);
      if (mounted) setState(() => _serviceReady = true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _artistNameController.dispose();
    _songNameController.dispose();
    _albumNameController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _complaintService.fileComplaint(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        contentType: _selectedContentType,
        artistName: _artistNameController.text.trim(),
        songName: _songNameController.text.trim(),
        albumName: _albumNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Complaint filed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCopyrightMode ? 'Report Copyright' : 'File a Complaint'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: (_isCopyrightMode ? Colors.orange : AppColors.info)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.paddingMd),
                      border: Border.all(
                        color:
                            (_isCopyrightMode ? Colors.orange : AppColors.info)
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCopyrightMode
                              ? Icons.copyright
                              : Icons.info_outline,
                          color: _isCopyrightMode
                              ? Colors.orange
                              : AppColors.info,
                        ),
                        const SizedBox(width: AppSizes.paddingMd),
                        Expanded(
                          child: Text(
                            _isCopyrightMode
                                ? 'Report a song that you believe belongs to you or another rightful owner. Provide as many details as possible so our team can investigate.'
                                : 'Use this form to report content that violates our community guidelines or terms of service.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // Title Field
                  _buildLabel('Title'),
                  const SizedBox(height: AppSizes.paddingSm),
                  CustomTextField(
                    label: 'Title',
                    controller: _titleController,
                    hint: _isCopyrightMode
                        ? 'e.g. Copyright Dispute - My Song Name'
                        : 'Brief title for your complaint',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  // Content Type Dropdown
                  _buildLabel('Content Type'),
                  const SizedBox(height: AppSizes.paddingSm),
                  DropdownButtonFormField<String>(
                    value: _selectedContentType,
                    decoration: InputDecoration(
                      hintText: 'Select content type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.paddingMd),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    dropdownColor: const Color(0xFF1E1E1E),
                    items: _contentTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedContentType = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a content type';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  // ── Copyright-specific fields ───────────────────────
                  _buildLabel('Artist Name'),
                  const SizedBox(height: AppSizes.paddingSm),
                  CustomTextField(
                    label: 'Artist Name',
                    controller: _artistNameController,
                    hint: 'The artist who uploaded the duplicate',
                    validator: _isCopyrightMode
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide the artist name';
                            }
                            return null;
                          }
                        : null,
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  _buildLabel('Song Name'),
                  const SizedBox(height: AppSizes.paddingSm),
                  CustomTextField(
                    label: 'Song Name',
                    controller: _songNameController,
                    hint: 'Name of the song you want to report',
                    validator:
                        (_selectedContentType == 'SONG' || _isCopyrightMode)
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide the song name';
                            }
                            return null;
                          }
                        : null,
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  _buildLabel('Album Name (if applicable)'),
                  const SizedBox(height: AppSizes.paddingSm),
                  CustomTextField(
                    label: 'Album Name',
                    controller: _albumNameController,
                    hint: 'If the song is inside an album, mention it here',
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  // Description Field
                  _buildLabel('Clear Explanation'),
                  const SizedBox(height: AppSizes.paddingSm),
                  CustomTextField(
                    label: 'Clear Explanation',
                    controller: _descriptionController,
                    hint: _isCopyrightMode
                        ? 'Explain why you believe this content belongs to you. Include any proof links, release dates, or other details.'
                        : 'Detailed description of the issue',
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a detailed explanation';
                      }
                      if (value.trim().length < 20) {
                        return 'Explanation must be at least 20 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // Submit Button
                  CustomButton(
                    text: _isCopyrightMode
                        ? 'Submit Copyright Report'
                        : 'Submit Complaint',
                    onPressed: () {
                      if (_serviceReady) _submitComplaint();
                    },
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: AppSizes.paddingMd),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: LoadingIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
