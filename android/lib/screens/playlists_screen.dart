import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../widgets/song_tile.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final lists = provider.playlistService.playlists;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text('PLAYLISTS', style: CyberTheme.headerText(size: 18)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showCreateDialog(context, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: CyberTheme.neonPurple, width: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: CyberTheme.neonPurple, size: 14),
                      const SizedBox(width: 4),
                      Text('NEW', style: CyberTheme.labelText(color: CyberTheme.neonPurple)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'root@cyber:~/playlists\$',
            style: CyberTheme.terminalText(size: 11, color: CyberTheme.textDim),
          ),
        ),
        const CyberDivider(),
        Expanded(
          child: lists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.queue_music, color: CyberTheme.textDim, size: 48),
                      const SizedBox(height: 16),
                      Text('> NO_PLAYLISTS_FOUND', style: CyberTheme.terminalText(color: CyberTheme.textDim)),
                      const SizedBox(height: 8),
                      Text('Tap [+NEW] to create one', style: CyberTheme.labelText()),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 140),
                  itemCount: lists.length,
                  itemBuilder: (_, i) => _PlaylistTile(index: i, provider: provider),
                ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, MusicProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CyberTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: CyberTheme.neonPurple, width: 0.5),
        ),
        title: Text('> CREATE_PLAYLIST', style: CyberTheme.terminalText(color: CyberTheme.neonPurple, weight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: CyberTheme.terminalText(color: CyberTheme.textPrimary, size: 14),
          cursorColor: CyberTheme.neonPurple,
          decoration: InputDecoration(
            hintText: 'playlist_name',
            hintStyle: CyberTheme.terminalText(color: CyberTheme.textDim),
            prefixText: '> ',
            prefixStyle: CyberTheme.terminalText(color: CyberTheme.neonPurple),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.neonPurple)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: CyberTheme.labelText(color: CyberTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: Text('CREATE', style: CyberTheme.labelText(color: CyberTheme.neonPurple)),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatefulWidget {
  final int index;
  final MusicProvider provider;
  const _PlaylistTile({required this.index, required this.provider});

  @override
  State<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<_PlaylistTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final playlists = widget.provider.playlistService.playlists;
    if (widget.index >= playlists.length) return const SizedBox.shrink();

    final pl = playlists[widget.index];
    final songs = widget.provider.getPlaylistSongs(widget.index);

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          onLongPress: () => _showPlaylistMenu(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.all(12),
            decoration: CyberTheme.cardDecoration(active: _expanded),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: CyberTheme.neonPurple,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.queue_music, color: CyberTheme.neonPurple, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pl.name, style: CyberTheme.terminalText(color: CyberTheme.neonPurple, weight: FontWeight.bold, size: 14)),
                      Text('${pl.songIds.length} tracks', style: CyberTheme.labelText()),
                    ],
                  ),
                ),
                if (songs.isNotEmpty)
                  GestureDetector(
                    onTap: () => widget.provider.playSong(songs.first, songs),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: CyberTheme.neonPurple, width: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(Icons.play_arrow, color: CyberTheme.neonPurple, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && songs.isNotEmpty)
          ...List.generate(songs.length, (i) {
            return Dismissible(
              key: ValueKey('${widget.index}-${songs[i].id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: CyberTheme.error.withOpacity(0.2),
                child: Text('REMOVE', style: CyberTheme.labelText(color: CyberTheme.error)),
              ),
              onDismissed: (_) {
                widget.provider.removeFromPlaylist(widget.index, songs[i].id);
              },
              child: SongTile(song: songs[i], contextSongs: songs, index: i),
            );
          }),
        if (_expanded && songs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '> EMPTY: long-press a track to add it here',
              style: CyberTheme.terminalText(color: CyberTheme.textDim, size: 11),
            ),
          ),
      ],
    );
  }

  void _showPlaylistMenu(BuildContext context) {
    final playlists = widget.provider.playlistService.playlists;
    if (widget.index >= playlists.length) return;
    final pl = playlists[widget.index];

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
              child: Text('> ${pl.name}', style: CyberTheme.terminalText(color: CyberTheme.neonPurple, weight: FontWeight.bold)),
            ),
            const Divider(color: CyberTheme.border, height: 1),
            ListTile(
              leading: const Icon(Icons.delete, color: CyberTheme.error),
              title: Text('DELETE', style: CyberTheme.terminalText(size: 13, color: CyberTheme.error)),
              onTap: () {
                widget.provider.deletePlaylist(widget.index);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
