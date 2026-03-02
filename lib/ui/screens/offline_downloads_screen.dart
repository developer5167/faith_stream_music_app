import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../../services/download_service.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../widgets/gradient_background.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/song_card.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen> {
  List<DownloadedSong> _downloads = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  void _loadDownloads() {
    final ds = context.read<DownloadService>();
    setState(() {
      _downloads = ds.getDownloads();
    });
  }

  // Pull-to-refresh: check net → if online, navigate to main
  Future<void> _onRefresh() async {
    final result = await Connectivity().checkConnectivity();
    final isOnline =
        result.isNotEmpty && !result.every((r) => r == ConnectivityResult.none);
    if (!mounted) return;
    if (isOnline) {
      // Internet is back — go to main screen
      context.go('/splash');
    } else {
      // Still offline — just reload downloads list
      _loadDownloads();
    }
  }

  void _playAll(BuildContext context) {
    if (_downloads.isEmpty) return;
    final songs = _downloads.map((d) => d.toSong()).toList();
    context.read<PlayerBloc>().add(PlayerPlaySong(songs.first, queue: songs));
  }

  void _playSong(BuildContext context, DownloadedSong downloaded) {
    final songs = _downloads.map((d) => d.toSong()).toList();
    final song = downloaded.toSong();
    context.read<PlayerBloc>().add(PlayerPlaySong(song, queue: songs));
  }

  Future<void> _removeDownload(DownloadedSong downloaded) async {
    final ds = context.read<DownloadService>();
    await ds.removeDownload(downloaded.id);
    _loadDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const MiniPlayerBar(),
        body: RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.black54,
          displacement: 80,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App Bar ────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 120,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Offline Downloads',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // ── Offline banner ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'re offline. Pull down to check for internet.',
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Empty state ────────────────────────────────────────────
              if (_downloads.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          size: 64,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No downloads yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Go online to download songs for offline listening.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // ── Play All button ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _playAll(context),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text('Play All (${_downloads.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Song list ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final d = _downloads[index];
                      return Dismissible(
                        key: Key(d.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                        ),
                        onDismissed: (_) => _removeDownload(d),
                        child: SongCard(
                          song: d.toSong(),
                          onTap: () => _playSong(context, d),
                          showRemoveButton: true,
                          onRemoveTap: () => _removeDownload(d),
                        ),
                      );
                    }, childCount: _downloads.length),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}
