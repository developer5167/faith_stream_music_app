import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class UploadService {
  final ApiClient _apiClient;

  UploadService(this._apiClient);

  /// Upload types for different resources
  static const String albumCover = 'album_cover';
  static const String songCover = 'song_cover';
  static const String songAudio = 'song_audio';
  static const String artistProfile = 'artist_profile';
  static const String userProfile = 'user_profile';
  static const String adminUpload = 'admin_upload';
  static const String artistSelfieVideo = 'artist_selfie_video';

  /// Generate presigned URL for file upload
  ///
  /// [filePath] - Local file path to upload
  /// [uploadType] - Type of upload (use static constants above)
  /// [resourceId] - ID of resource (album_id, song_id, etc.) - required for certain types
  ///
  /// Returns a map with:
  /// - uploadUrl: URL to upload file to
  /// - publicUrl: Public URL of the uploaded file
  /// - s3Key: S3 key of the file
  Future<Map<String, dynamic>> getPresignedUploadUrl({
    required String fileName,
    required String contentType,
    required String uploadType,
    String? resourceId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/upload/presigned-url',
        data: {
          'fileName': fileName,
          'contentType': contentType,
          'uploadType': uploadType,
          if (resourceId != null) 'resourceId': resourceId,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get presigned URL');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file to S3 using presigned URL
  ///
  /// [filePath] - Local file path to upload
  /// [uploadType] - Type of upload (use static constants above)
  /// [resourceId] - ID of resource (album_id, song_id, etc.)
  /// [onProgress] - Callback for upload progress (0.0 to 1.0)
  ///
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String filePath,
    required String uploadType,
    String? resourceId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Extract file name and determine content type
      final fileName = filePath.split('/').last;
      final contentType = _getContentType(fileName);

      // Get presigned URL
      final urlData = await getPresignedUploadUrl(
        fileName: fileName,
        contentType: contentType,
        uploadType: uploadType,
        resourceId: resourceId,
      );

      final uploadUrl = urlData['uploadUrl'] as String;
      final publicUrl = urlData['publicUrl'] as String;

      // Upload file to S3
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileLength = fileBytes.length;

      final dio = Dio();
      await dio.put(
        uploadUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileLength.toString(),
          },
          // Don't follow redirects for S3 presigned URLs
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total != -1) {
            onProgress(sent / total);
          }
        },
      );

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Determine content type from file name
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    // Image types
    if (extension == 'jpg' || extension == 'jpeg') {
      return 'image/jpeg';
    } else if (extension == 'png') {
      return 'image/png';
    } else if (extension == 'webp') {
      return 'image/webp';
    }
    // Audio types
    else if (extension == 'mp3') {
      return 'audio/mpeg';
    } else if (extension == 'wav') {
      return 'audio/wav';
    } else if (extension == 'flac') {
      return 'audio/flac';
    }
    // Video types
    else if (extension == 'mp4') {
      return 'video/mp4';
    } else if (extension == 'mov') {
      return 'video/quicktime';
    } else if (extension == 'avi') {
      return 'video/x-msvideo';
    }
    // Default
    else {
      return 'application/octet-stream';
    }
  }

  /// Upload album cover image
  Future<String> uploadAlbumCover({
    required String filePath,
    required String albumId,
    Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      filePath: filePath,
      uploadType: albumCover,
      resourceId: albumId,
      onProgress: onProgress,
    );
  }

  /// Upload song cover image
  Future<String> uploadSongCover({
    required String filePath,
    required String songId,
    Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      filePath: filePath,
      uploadType: songCover,
      resourceId: songId,
      onProgress: onProgress,
    );
  }

  /// Upload song audio file
  Future<String> uploadSongAudio({
    required String filePath,
    required String songId,
    Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      filePath: filePath,
      uploadType: songAudio,
      resourceId: songId,
      onProgress: onProgress,
    );
  }

  /// Upload user profile picture
  Future<String> uploadUserProfile({
    required String filePath,
    Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      filePath: filePath,
      uploadType: userProfile,
      onProgress: onProgress,
    );
  }

  /// Upload artist profile picture
  Future<String> uploadArtistProfile({
    required String filePath,
    Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      filePath: filePath,
      uploadType: artistProfile,
      onProgress: onProgress,
    );
  }

  /// Upload artist selfie video
  Future<String> uploadArtistSelfieVideo({
    required String filePath,
    Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      filePath: filePath,
      uploadType: artistSelfieVideo,
      onProgress: onProgress,
    );
  }
}
