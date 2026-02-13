import 'dart:io';
import 'package:faith_stream_music_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imageUrl) onImageUploaded;
  final String uploadType;
  final String? resourceId;
  final double size;
  final bool circular;

  const ImageUploadWidget({
    super.key,
    this.currentImageUrl,
    required this.onImageUploaded,
    required this.uploadType,
    this.resourceId,
    this.size = 120,
    this.circular = true,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _uploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });

      // Auto-upload after selection
      await _uploadImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get upload service from context (you'll need to provide it via Provider/Bloc)
      // For now, we'll throw an error if not implemented
      throw UnimplementedError(
        'Upload service needs to be provided via dependency injection',
      );

      // This is what the implementation should look like:
      // final uploadService = context.read<UploadService>();
      // final publicUrl = await uploadService.uploadFile(
      //   filePath: _selectedImage!.path,
      //   uploadType: widget.uploadType,
      //   resourceId: widget.resourceId,
      //   onProgress: (progress) {
      //     setState(() {
      //       _uploadProgress = progress;
      //     });
      //   },
      // );
      //
      // widget.onImageUploaded(publicUrl);
      //
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Image uploaded successfully!')),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (widget.currentImageUrl != null &&
        widget.currentImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.currentImageUrl!);
    }

    Widget imageWidget;
    if (imageProvider != null) {
      imageWidget = Image(
        image: imageProvider,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    } else {
      imageWidget = Container(
        width: widget.size,
        height: widget.size,
        color: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: widget.size * 0.5,
          color: Colors.grey[600],
        ),
      );
    }

    if (widget.circular) {
      return ClipOval(child: imageWidget);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildImagePreview(),
        if (_uploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.circular
                    ? null
                    : BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: _uploadProgress,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: AppColors.primaryBrown,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 20),
              color: Colors.white,
              onPressed: _uploading ? null : _pickImage,
            ),
          ),
        ),
      ],
    );
  }
}
