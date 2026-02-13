import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/upload_service.dart';
import './permissions_helper.dart';

class VideoRecordingHelper {
  /// Record selfie video and upload to S3
  ///
  /// Returns the public URL of the uploaded video
  static Future<String?> recordAndUploadSelfieVideo({
    required BuildContext context,
    required UploadService uploadService,
  }) async {
    try {
      // Check permissions first
      final hasPermissions =
          await PermissionsHelper.requestVideoRecordingPermissions();
      if (!hasPermissions) {
        // Check if permissions were permanently denied
        final cameraStatus = await Permission.camera.status;
        final microphoneStatus = await Permission.microphone.status;

        if (cameraStatus.isPermanentlyDenied ||
            microphoneStatus.isPermanentlyDenied) {
          // Show settings dialog only if permissions are permanently denied
          if (context.mounted) {
            PermissionsHelper.showPermissionSettingsDialog(context);
          }
        } else {
          // Permissions were denied but not permanently - user can try again
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Camera and microphone permissions are required to record selfie video',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return null;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Find front camera, fallback to first camera
      late CameraDescription camera;
      try {
        camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        camera = cameras.first;
      }

      // Navigate to video recording screen
      if (context.mounted) {
        final videoPath = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => SelfieVideoRecordingScreen(camera: camera),
            fullscreenDialog: true,
          ),
        );

        if (videoPath != null) {
          // Show loading indicator for upload
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Uploading Video',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we upload your selfie video...',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          try {
            // Upload the video
            final publicUrl = await uploadService.uploadArtistSelfieVideo(
              filePath: videoPath,
              onProgress: (progress) {
                // TODO: Show progress dialog if needed
              },
            );

            // Hide loading indicator
            if (context.mounted) {
              Navigator.of(context).pop();
            }

            // Clean up the local file
            try {
              await File(videoPath).delete();
            } catch (e) {
              // Ignore cleanup errors
            }

            return publicUrl;
          } catch (e) {
            // Hide loading indicator on error
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            throw e;
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to record selfie video: $e');
    }
  }
}

class SelfieVideoRecordingScreen extends StatefulWidget {
  final CameraDescription camera;

  const SelfieVideoRecordingScreen({super.key, required this.camera});

  @override
  State<SelfieVideoRecordingScreen> createState() =>
      _SelfieVideoRecordingScreenState();
}

class _SelfieVideoRecordingScreenState extends State<SelfieVideoRecordingScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;
  int _recordingDuration = 0;
  late AnimationController _pulseController;

  // Recording constraints
  static const int minDuration = 3; // seconds
  static const int maxDuration = 30; // seconds
  static const int maxFileSize = 15 * 1024 * 1024; // 15MB

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Start recording
      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      final videoFile = await _controller!.stopVideoRecording();

      setState(() {
        _isRecording = false;
      });

      // Check duration
      if (_recordingDuration < minDuration) {
        await File(videoFile.path).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video must be at least $minDuration seconds long'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check file size
      final fileSize = await File(videoFile.path).length();
      if (fileSize > maxFileSize) {
        await File(videoFile.path).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Video file is too large. Please record a shorter video.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Return the video path
      if (mounted) {
        Navigator.of(context).pop(videoFile.path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration++;
        });

        // Stop automatically at max duration
        if (_recordingDuration >= maxDuration) {
          await _stopRecording();
          return false;
        }
        return true;
      }
      return false;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get _instructionText {
    if (!_isRecording) {
      return 'Tap the record button to start recording your selfie video.\n\nSay "Hi" and introduce yourself with your name.';
    } else if (_recordingDuration < minDuration) {
      return 'Keep recording... Say "Hi" and your name.\n\nMinimum ${minDuration}s required.';
    } else {
      return 'Great! You can stop recording now or continue.\n\nTap stop when ready.';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Record Selfie Video'),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // To handle vertical camera preview on most phones
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen camera preview without stretch
          Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),

          // Gradient overlay for visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),

          // Custom Header
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Record Selfie Video',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),
          ),

          // Instructions overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _instructionText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Recording indicator
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 160,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(
                          0.8 + 0.2 * _pulseController.value,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Duration: ${_formatDuration(_recordingDuration)} / ${_formatDuration(maxDuration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.red : Colors.white,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        color: _isRecording ? Colors.white : Colors.red,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
