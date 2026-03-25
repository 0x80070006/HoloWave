import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/cyber_theme.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> contextSongs;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    required this.contextSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final isPlaying = provider.audio.currentSong?.id == song.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('[UI] Tapped song: "${song.title}" id=${song.id}');
            provider.playSong(song, contextSongs);
          },
          onLongPress: () => _showSongMenu(context, song),
          splashColor: CyberTheme.neonCyan.withOpacity(0.1),
          highlightColor: CyberTheme.neonCyan.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: CyberTheme.cardDecoration(active: isPlaying),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: isPlaying
                      ? _PlayingIndicator()
                      : Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: CyberTheme.labelText(color: CyberTheme.textDim),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: CyberTheme.terminalText(
                          size: 13,
                          color: isPlaying ? CyberTheme.neonCyan : CyberTheme.textPrimary,
                          weight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        style: CyberTheme.labelText(
                          color: isPlaying ? CyberTheme.neonCyan.withOpacity(0.6) : CyberTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play icon indicator
                Icon(
                  isPlaying ? Icons.volume_up : Icons.play_circle_outline,
                  color: isPlaying ? CyberTheme.neonCyan : CyberTheme.textDim,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  song.durationFormatted,
                  style: CyberTheme.labelText(color: CyberTheme.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSongMenu(BuildContext context, Song song) {
    if (!context.mounted) return;
    final provider = context.read<MusicProvider>();
    final playlists = provider.playlistService.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: CyberTheme.border, width: 0.5),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('> ', style: CyberTheme.terminalText(color: CyberTheme.neonCyan)),
                  Expanded(
                    child: Text(
                      song.title,
                      style: CyberTheme.terminalText(
                        color: CyberTheme.neonCyan,
                        weight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: CyberTheme.border, height: 1),
            if (playlists.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.playlist_add, color: CyberTheme.neonPurple),
                title: Text('ADD_TO_PLAYLIST', style: CyberTheme.terminalText(size: 13)),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _showPlaylistPicker(context, song, provider);
                },
              ),
            ListTile(
              leading: const Icon(Icons.album, color: CyberTheme.neonBlue),
              title: Text(
                'ALBUM: ${song.album}',
                style: CyberTheme.terminalText(size: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: CyberTheme.neonYellow),
              title: Text(
                'PATH: ${song.folder}/',
                style: CyberTheme.terminalText(size: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, Song song, MusicProvider provider) {
    if (!context.mounted) return;
    final playlists = provider.playlistService.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: CyberTheme.border, width: 0.5),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '> SELECT_PLAYLIST',
                style: CyberTheme.terminalText(
                  color: CyberTheme.neonPurple,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: CyberTheme.border, height: 1),
            ...List.generate(playlists.length, (i) {
              final pl = playlists[i];
              return ListTile(
                leading: const Icon(Icons.queue_music, color: CyberTheme.neonPurple, size: 18),
                title: Text(pl.name, style: CyberTheme.terminalText(size: 13)),
                trailing: Text('${pl.songIds.length} tracks', style: CyberTheme.labelText()),
                onTap: () {
                  provider.addToPlaylist(i, song.id);
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '> ADDED to "${pl.name}"',
                        style: CyberTheme.terminalText(size: 12),
                      ),
                      backgroundColor: CyberTheme.bgCard,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PlayingIndicator extends StatefulWidget {
  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final val = ((_ctrl.value + i * 0.2) % 1.0);
          return Container(
            width: 3,
            height: 6 + val * 10,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: CyberTheme.neonCyan,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: CyberTheme.neonCyan.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
