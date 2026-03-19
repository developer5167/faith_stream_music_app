import 'package:faith_stream_music_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';
import '../../services/api_client.dart';
import '../../services/song_service.dart';
import '../../services/album_service.dart';

class ManageSongsScreen extends StatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  State<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends State<ManageSongsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _songs = [];
  List<dynamic> _albums = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadSongs(), _loadAlbums()]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
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
      debugPrint('Failed to load songs: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load songs: $e')));
      }
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final albumService = AlbumService(apiClient);

      final albums = await albumService.getMyAlbums();

      if (mounted) {
        setState(() {
          _albums = albums;
        });
      }
    } catch (e) {
      debugPrint('Failed to load albums: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load albums: $e')));
      }
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
        title: const Text('Manage Library'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSongsList(theme), _buildAlbumsList(theme)],
      ),
    );
  }

  Widget _buildSongsList(ThemeData theme) {
    if (_isLoading && _songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return _buildEmptyState(
        theme,
        'No songs found',
        'Upload your first song to get started',
      );
    }

    return RefreshIndicator(
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
              leading: _buildThumbnail(song['cover_image_url'], theme),
              title: Text(
                song['title'] ?? 'Untitled',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${song['genre']} • ${song['language']}'),
                  const SizedBox(height: 8),
                  _buildStatusBadge(song['status'] ?? 'DRAFT'),
                ],
              ),
              onTap: () => _showSongDetails(song),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsList(ThemeData theme) {
    if (_isLoading && _albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_albums.isEmpty) {
      return _buildEmptyState(
        theme,
        'No albums found',
        'Create your first album to organize songs',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlbums,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        itemCount: _albums.length + 1, // +1 for the header note
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAutoDeleteNote(theme);
          }
          final album = _albums[index - 1];
          final String status = album['status'] ?? 'DRAFT';

          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSizes.paddingMd),
              leading: _buildThumbnail(
                album['cover_image_url'],
                theme,
                isAlbum: true,
              ),
              title: Text(
                album['title'] ?? 'Untitled',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(album['release_type'] ?? 'ALBUM'),
                  const SizedBox(height: 8),
                  _buildStatusBadge(status),
                ],
              ),
              trailing: status == 'DRAFT'
                  ? ElevatedButton(
                      onPressed: () => _confirmAlbumSubmission(album),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Submit'),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => _showAlbumDetails(album),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoDeleteNote(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 24),
          const SizedBox(width: AppSizes.paddingMd),
          const Expanded(
            child: Text(
              'Draft albums older than 7 days will be automatically deleted. Please submit your albums for review in time.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String? url, ThemeData theme, {bool isAlbum = false}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? Icon(
              isAlbum ? Icons.album : Icons.music_note,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            )
          : null,
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music, size: 64, color: Colors.grey[400]),
          const SizedBox(height: AppSizes.paddingMd),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAlbumSubmission(Map<String, dynamic> album) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Album'),
        content: Text(
          'Submit "${album['title']}" for review? Once submitted, you cannot edit it until the review is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Submit Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _submitAlbum(album['id'].toString());
    }
  }

  Future<void> _submitAlbum(String albumId) async {
    setState(() => _isLoading = true);
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final albumService = AlbumService(apiClient);

      await albumService.submitAlbum(albumId: albumId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album submitted for review!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit album: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSongDetails(Map<String, dynamic> song) {
    _showDetailsSheet(
      title: song['title'] ?? 'Untitled',
      imageUrl: song['cover_image_url'],
      details: [
        _buildDetailRow('Genre', song['genre']),
        _buildDetailRow('Language', song['language']),
        if (song['album_title'] != null)
          _buildDetailRow('Album', song['album_title']),
        _buildDetailRow('Status', _getStatusText(song['status'] ?? 'DRAFT')),
      ],
      description: song['description'],
      lyrics: song['lyrics'],
    );
  }

  void _showAlbumDetails(Map<String, dynamic> album) {
    _showDetailsSheet(
      title: album['title'] ?? 'Untitled',
      imageUrl: album['cover_image_url'],
      details: [
        _buildDetailRow('Type', album['release_type']),
        _buildDetailRow('Language', album['language']),
        _buildDetailRow('Status', _getStatusText(album['status'] ?? 'DRAFT')),
      ],
      description: album['description'],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  void _showDetailsSheet({
    required String title,
    String? imageUrl,
    required List<Widget> details,
    String? description,
    String? lyrics,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Cover Image
                      if (imageUrl != null) ...[
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMd),
                      ],

                      // Details
                      ...details,

                      // Description
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingMd),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        Text(description),
                      ],

                      // Lyrics
                      if (lyrics != null && lyrics.isNotEmpty) ...[
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
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lyrics,
                            style: TextStyle(
                              height: 1.5,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
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
}
