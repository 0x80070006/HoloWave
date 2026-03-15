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

    // Entire tile is tappable — no separate play button
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: isPlaying ? CyberTheme.bgCardHover : CyberTheme.bgCard,
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          onTap: () {
            print('[TAP] "${song.title}" id=${song.id}');
            provider.playSong(song, contextSongs);
          },
          onLongPress: () => _showSongMenu(context, song),
          splashColor: CyberTheme.neonCyan.withOpacity(0.15),
          highlightColor: CyberTheme.neonCyan.withOpacity(0.05),
          borderRadius: BorderRadius.circular(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isPlaying ? CyberTheme.borderActive : CyberTheme.border,
                width: isPlaying ? 1.0 : 0.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                // Track number or playing indicator
                SizedBox(
                  width: 28,
                  child: isPlaying
                      ? _PlayingIndicator()
                      : Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: CyberTheme.labelText(color: CyberTheme.textDim),
                        ),
                ),
                const SizedBox(width: 10),
                // Song info - takes all available space
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
                const SizedBox(width: 8),
                // Duration
                Text(
                  song.durationFormatted,
                  style: CyberTheme.labelText(color: isPlaying ? CyberTheme.neonCyan : CyberTheme.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSongMenu(BuildContext context, Song song) {
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
                  Expanded(child: Text(song.title,
                    style: CyberTheme.terminalText(color: CyberTheme.neonCyan, weight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const Divider(color: CyberTheme.border, height: 1),
            if (playlists.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.playlist_add, color: CyberTheme.neonPurple),
                title: Text('ADD_TO_PLAYLIST', style: CyberTheme.terminalText(size: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaylistPicker(context, song, provider);
                },
              ),
            ListTile(
              leading: const Icon(Icons.album, color: CyberTheme.neonBlue),
              title: Text('ALBUM: ${song.album}', style: CyberTheme.terminalText(size: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: CyberTheme.neonYellow),
              title: Text('PATH: ${song.folder}/', style: CyberTheme.terminalText(size: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, Song song, MusicProvider provider) {
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
            Padding(padding: const EdgeInsets.all(16),
              child: Text('> SELECT_PLAYLIST', style: CyberTheme.terminalText(color: CyberTheme.neonPurple, weight: FontWeight.bold))),
            const Divider(color: CyberTheme.border, height: 1),
            ...List.generate(playlists.length, (i) {
              final pl = playlists[i];
              return ListTile(
                leading: const Icon(Icons.queue_music, color: CyberTheme.neonPurple, size: 18),
                title: Text(pl.name, style: CyberTheme.terminalText(size: 13)),
                trailing: Text('${pl.songIds.length}', style: CyberTheme.labelText()),
                onTap: () { provider.addToPlaylist(i, song.id); Navigator.pop(context); },
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

class _PlayingIndicatorState extends State<_PlayingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = ((_c.value + i * 0.2) % 1.0);
          return Container(
            width: 3, height: 6 + v * 10,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: CyberTheme.neonCyan, borderRadius: BorderRadius.circular(1),
              boxShadow: [BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.4), blurRadius: 4)],
            ),
          );
        }),
      ),
    );
  }
}
