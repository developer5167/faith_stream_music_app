import 'package:faith_stream_music_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';
import '../../services/api_client.dart';
import '../../services/song_service.dart';

class ManageSongsScreen extends StatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  State<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends State<ManageSongsScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      setState(() => _isLoading = true);

      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final songService = SongService(apiClient);

      final songs = await songService.getMySongs();

      if (mounted) {
        setState(() {
          _songs = songs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load songs: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ignore: unused_element
  String _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'green';
      case 'PENDING':
        return 'orange';
      case 'REJECTED':
        return 'red';
      case 'DRAFT':
        return 'blue';
      default:
        return 'grey';
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'DRAFT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Published';
      case 'PENDING':
        return 'Under Review';
      case 'REJECTED':
        return 'Rejected';
      case 'DRAFT':
        return 'Draft';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Songs'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: AppSizes.paddingMd),
                  Text(
                    'No songs found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  Text(
                    'Upload your first song to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSongs,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSizes.paddingMd),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                          image: song['cover_image_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(song['cover_image_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: song['cover_image_url'] == null
                            ? const Icon(Icons.music_note, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        song['title'] ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${song['genre']} • ${song['language']}'),
                          const SizedBox(height: 4),
                          if (song['album_title'] != null)
                            Text(
                              'Album: ${song['album_title']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBackgroundColor(
                                song['status'] ?? 'DRAFT',
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(song['status'] ?? 'DRAFT'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            song['created_at'] != null
                                ? _formatDate(song['created_at'])
                                : '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                      onTap: () {
                        _showSongDetails(song);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _showSongDetails(Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text(
                        song['title'] ?? 'Untitled',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Cover Image
                      if (song['cover_image_url'] != null) ...[
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(song['cover_image_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMd),
                      ],

                      // Details
                      _buildDetailItem('Genre', song['genre']),
                      _buildDetailItem('Language', song['language']),
                      if (song['album_title'] != null)
                        _buildDetailItem('Album', song['album_title']),
                      if (song['track_number'] != null)
                        _buildDetailItem(
                          'Track Number',
                          song['track_number'].toString(),
                        ),
                      _buildDetailItem(
                        'Status',
                        _getStatusText(song['status'] ?? 'DRAFT'),
                      ),
                      if (song['created_at'] != null)
                        _buildDetailItem(
                          'Created',
                          _formatDate(song['created_at']),
                        ),

                      // Description
                      if (song['description'] != null &&
                          song['description'].isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingMd),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        Text(song['description']),
                      ],

                      // Lyrics
                      if (song['lyrics'] != null &&
                          song['lyrics'].isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingMd),
                        Text(
                          'Lyrics',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            song['lyrics'],
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
