import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import 'app_shell.dart';
import '../widgets/song_tile.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlists = provider.playlistService.playlists;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Text('STACKS', style: CyberTheme.headerText(size: 18, color: CyberTheme.neonPurple)),
          const Spacer(),
          GestureDetector(onTap: () => _showCreate(context, provider),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: CyberTheme.neonPurple), borderRadius: BorderRadius.circular(2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: CyberTheme.neonPurple, size: 14), const SizedBox(width: 4),
                Text('NEW', style: CyberTheme.labelText(color: CyberTheme.neonPurple)),
              ]))),
        ])),
      const CyberDivider(),
      Expanded(child: playlists.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.queue_music, color: CyberTheme.textDim, size: 48), const SizedBox(height: 16),
            Text('> NO_STACKS', style: CyberTheme.terminalText(color: CyberTheme.textDim)),
            const SizedBox(height: 8),
            Text('Tap NEW to create a stack', style: CyberTheme.labelText()),
          ]))
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82),
            itemCount: playlists.length,
            itemBuilder: (_, i) {
              final pl = playlists[i];
              final songs = provider.getPlaylistSongs(i);
              return _PlaylistTile(index: i, playlist: pl, songs: songs);
            })),
    ]);
  }

  void _showCreate(BuildContext context, MusicProvider provider) {
    if (!context.mounted) return;
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: CyberTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: CyberTheme.neonPurple, width: 0.5)),
      title: Text('> NEW_STACK', style: CyberTheme.terminalText(color: CyberTheme.neonPurple, weight: FontWeight.bold)),
      content: TextField(controller: ctrl, autofocus: true,
        style: CyberTheme.terminalText(color: CyberTheme.textPrimary, size: 14),
        cursorColor: CyberTheme.neonPurple,
        decoration: InputDecoration(hintText: 'stack_name', hintStyle: CyberTheme.terminalText(color: CyberTheme.textDim),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.border)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.neonPurple)))),
      actions: [
        TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text('CANCEL', style: CyberTheme.labelText(color: CyberTheme.textDim))),
        TextButton(onPressed: () {
          if (ctrl.text.trim().isNotEmpty) { provider.createPlaylist(ctrl.text.trim()); Navigator.of(context, rootNavigator: true).pop(); }
        }, child: Text('CREATE', style: CyberTheme.labelText(color: CyberTheme.neonPurple))),
      ],
    ));
  }
}

class _PlaylistTile extends StatelessWidget {
  final int index; final Playlist playlist; final List<Song> songs;
  const _PlaylistTile({required this.index, required this.playlist, required this.songs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DetailShell(child: _PlaylistDetail(index: index, playlist: playlist, songs: songs)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Expanded(child: Stack(children: [
          // Cover: custom image or 4-quad mosaic
          Container(
            decoration: BoxDecoration(color: CyberTheme.bgCard,
              border: Border.all(color: CyberTheme.neonPurple.withOpacity(0.4), width: 0.8),
              borderRadius: BorderRadius.circular(4)),
            child: ClipRRect(borderRadius: BorderRadius.circular(3),
              child: playlist.coverImagePath != null && File(playlist.coverImagePath!).existsSync()
                ? Image.file(File(playlist.coverImagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : _PlaylistMosaic(songs: songs))),
          // 3-dot menu
          Positioned(top: 4, right: 4, child: GestureDetector(
            onTap: () => _showOptions(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.more_vert, color: CyberTheme.neonPurple, size: 16)))),
          // Count
          Positioned(bottom: 6, right: 6, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7),
              border: Border.all(color: CyberTheme.neonPurple.withOpacity(0.5), width: 0.5), borderRadius: BorderRadius.circular(2)),
            child: Text('${playlist.songIds.length}', style: CyberTheme.labelText(color: CyberTheme.neonPurple)))),
        ])),
        const SizedBox(height: 6),
        SizedBox(height: 28, child: Text(playlist.name,
          style: CyberTheme.terminalText(size: 11, color: CyberTheme.neonPurple, weight: FontWeight.bold),
          maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      ]),
    );
  }

  void _showOptions(BuildContext context) {
    if (!context.mounted) return;
    final provider = context.read<MusicProvider>();
    showModalBottomSheet(context: context, backgroundColor: CyberTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: CyberTheme.neonPurple, width: 0.5)),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Text(playlist.name, style: CyberTheme.terminalText(color: CyberTheme.neonPurple, weight: FontWeight.bold))),
        const Divider(color: CyberTheme.border, height: 1),
        ListTile(
          leading: const Icon(Icons.image, color: CyberTheme.neonCyan),
          title: Text('CHANGE_COVER', style: CyberTheme.terminalText(size: 13)),
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
            try {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500);
              if (img != null) {
                await provider.setPlaylistCover(index, img.path);
              }
            } catch (e) {
              print('[PLAYLIST] Image picker error: $e');
            }
          }),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: CyberTheme.error),
          title: Text('DELETE_STACK', style: CyberTheme.terminalText(size: 13, color: CyberTheme.error)),
          onTap: () { Navigator.of(context, rootNavigator: true).pop(); provider.deletePlaylist(index); }),
        const SizedBox(height: 8),
      ])));
  }
}

class _PlaylistMosaic extends StatelessWidget {
  final List<Song> songs;
  const _PlaylistMosaic({required this.songs});
  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return Container(color: CyberTheme.bgTerminal,
      child: const Center(child: Icon(Icons.queue_music, color: CyberTheme.neonPurple, size: 40)));
    final ids = <int>[];
    for (final s in songs) { if (!ids.contains(s.id)) ids.add(s.id); if (ids.length >= 4) break; }
    while (ids.length < 4 && ids.isNotEmpty) ids.add(ids[ids.length % ids.length]);
    return Row(children: [
      Expanded(child: Column(children: [
        Expanded(child: _AQ(ids[0])), Expanded(child: _AQ(ids.length > 1 ? ids[1] : ids[0])),
      ])),
      Expanded(child: Column(children: [
        Expanded(child: _AQ(ids.length > 2 ? ids[2] : ids[0])), Expanded(child: _AQ(ids.length > 3 ? ids[3] : ids[0])),
      ])),
    ]);
  }
}

class _AQ extends StatelessWidget {
  final int songId;
  const _AQ(this.songId);
  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(id: songId, type: ArtworkType.AUDIO, size: 200,
      artworkFit: BoxFit.cover, artworkWidth: double.infinity, artworkHeight: double.infinity,
      nullArtworkWidget: Container(color: CyberTheme.bgTerminal,
        child: const Icon(Icons.music_note, color: CyberTheme.textDim, size: 16)));
  }
}

class _PlaylistDetail extends StatelessWidget {
  final int index; final Playlist playlist; final List<Song> songs;
  const _PlaylistDetail({required this.index, required this.playlist, required this.songs});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CyberTheme.border, width: 0.5))),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: CyberTheme.neonPurple, size: 22),
            onPressed: () => Navigator.pop(context)),
          Expanded(child: Text(playlist.name, style: CyberTheme.headerText(size: 14, color: CyberTheme.neonPurple),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${songs.length}', style: CyberTheme.labelText(color: CyberTheme.textDim)), const SizedBox(width: 8),
          if (songs.isNotEmpty)
            GestureDetector(onTap: () => context.read<MusicProvider>().playSong(songs.first, songs),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: CyberTheme.neonPurple), borderRadius: BorderRadius.circular(2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.play_arrow, color: CyberTheme.neonPurple, size: 16), const SizedBox(width: 4),
                  Text('PLAY', style: CyberTheme.labelText(color: CyberTheme.neonPurple))]))),
          const SizedBox(width: 8),
        ])),
      Expanded(child: songs.isEmpty
        ? Center(child: Text('> EMPTY_STACK', style: CyberTheme.terminalText(color: CyberTheme.textDim)))
        : ListView.builder(padding: const EdgeInsets.only(bottom: 20),
            itemCount: songs.length, itemBuilder: (_, i) => SongTile(song: songs[i], contextSongs: songs, index: i))),
    ]);
  }
}
