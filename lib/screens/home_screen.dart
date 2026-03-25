import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/music_provider.dart';
import '../theme/cyber_theme.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';
import '../widgets/cyber_widgets.dart';
import 'app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    return Column(children: [
      Container(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Text('HOLOWAVE', style: CyberTheme.headerText(size: 18)),
          const Spacer(),
          Text('${provider.filteredSongs.length} tracks', style: CyberTheme.labelText(color: CyberTheme.textDim)),
        ])),
      const CyberDivider(),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: TextField(controller: _searchCtrl,
          style: CyberTheme.terminalText(color: CyberTheme.textPrimary, size: 13),
          cursorColor: CyberTheme.neonCyan,
          decoration: CyberTheme.searchInputDecoration('search_wave...'),
          onChanged: (q) => provider.setSearchQuery(q))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          _Tab('FOLDERS', Icons.folder_outlined, provider.viewMode == ViewMode.folders, () => provider.setViewMode(ViewMode.folders)),
          const SizedBox(width: 6),
          _Tab('ALBUMS', Icons.album_outlined, provider.viewMode == ViewMode.albums, () => provider.setViewMode(ViewMode.albums)),
          const SizedBox(width: 6),
          _Tab('ARTISTS', Icons.person_outline, provider.viewMode == ViewMode.artists, () => provider.setViewMode(ViewMode.artists)),
        ])),
      const SizedBox(height: 8),
      Expanded(child: provider.isLoading
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 1.5, color: CyberTheme.neonCyan)),
            const SizedBox(height: 16), Text('> SCANNING...', style: CyberTheme.terminalText(size: 12))]))
        : provider.error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: CyberTheme.error, size: 40), const SizedBox(height: 16),
              Text(provider.error!, style: CyberTheme.terminalText(color: CyberTheme.error, size: 12), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(onTap: () => provider.init(), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: CyberTheme.neonCyan), borderRadius: BorderRadius.circular(2)),
                child: Text('> RETRY', style: CyberTheme.terminalText(color: CyberTheme.neonCyan, weight: FontWeight.bold, size: 13))))])))
          : _buildGrid(provider)),
    ]);
  }

  Widget _buildGrid(MusicProvider provider) {
    final Map<String, List<Song>> grouped;
    switch (provider.viewMode) {
      case ViewMode.folders: grouped = provider.songsByFolder; break;
      case ViewMode.albums: grouped = provider.songsByAlbum; break;
      case ViewMode.artists: grouped = provider.songsByArtist; break;
    }
    if (grouped.isEmpty) return Center(child: Text('> NO_RESULTS', style: CyberTheme.terminalText(color: CyberTheme.textDim)));
    final entries = grouped.entries.toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82),
      itemCount: entries.length,
      itemBuilder: (_, i) => _HoloTile(name: entries[i].key, songs: entries[i].value, viewMode: provider.viewMode, index: i),
    );
  }

  Widget _Tab(String label, IconData icon, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: active ? CyberTheme.bgCardHover : Colors.transparent,
        border: Border(bottom: BorderSide(color: active ? CyberTheme.neonCyan : CyberTheme.border, width: active ? 1.5 : 0.5))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: active ? CyberTheme.neonCyan : CyberTheme.textDim), const SizedBox(width: 6),
        Text(label, style: CyberTheme.labelText(color: active ? CyberTheme.neonCyan : CyberTheme.textDim)),
      ]))));
  }
}

// Holographic tile with 4-quadrant mosaic
class _HoloTile extends StatelessWidget {
  final String name; final List<Song> songs; final ViewMode viewMode; final int index;
  const _HoloTile({required this.name, required this.songs, required this.viewMode, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [CyberTheme.neonCyan, CyberTheme.neonYellow, CyberTheme.neonPink, CyberTheme.neonPurple, CyberTheme.neonBlue];
    final accent = colors[index % colors.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DetailShell(child: _TileDetail(name: name, songs: songs, accent: accent)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: CyberTheme.bgCard,
            border: Border.all(color: accent.withOpacity(0.4), width: 0.8), borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 16, spreadRadius: -2)]),
          child: ClipRRect(borderRadius: BorderRadius.circular(3), child: Stack(children: [
            // 4-quadrant mosaic
            _MosaicArt(songs: songs),
            // Tint
            Positioned.fill(child: Container(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [accent.withOpacity(0.1), Colors.transparent, accent.withOpacity(0.05)])))),
            // Track count
            Positioned(bottom: 6, right: 6, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7),
                border: Border.all(color: accent.withOpacity(0.5), width: 0.5), borderRadius: BorderRadius.circular(2)),
              child: Text('${songs.length}', style: CyberTheme.labelText(color: accent)))),
            // Corners
            ..._corners(accent),
          ])))),
        const SizedBox(height: 6),
        SizedBox(height: 28, child: Text(name, style: CyberTheme.terminalText(size: 11, color: accent, weight: FontWeight.bold),
          maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      ]),
    );
  }

  List<Widget> _corners(Color c) {
    const s = 10.0; final b = BorderSide(color: c.withOpacity(0.6), width: 1.2);
    return [
      Positioned(top: 3, left: 3, child: Container(width: s, height: s, decoration: BoxDecoration(border: Border(top: b, left: b)))),
      Positioned(top: 3, right: 3, child: Container(width: s, height: s, decoration: BoxDecoration(border: Border(top: b, right: b)))),
      Positioned(bottom: 3, left: 3, child: Container(width: s, height: s, decoration: BoxDecoration(border: Border(bottom: b, left: b)))),
      Positioned(bottom: 3, right: 3, child: Container(width: s, height: s, decoration: BoxDecoration(border: Border(bottom: b, right: b)))),
    ];
  }
}

// 4-quadrant artwork mosaic
class _MosaicArt extends StatelessWidget {
  final List<Song> songs;
  const _MosaicArt({required this.songs});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return Container(color: CyberTheme.bgTerminal,
      child: const Center(child: Icon(Icons.music_note, color: CyberTheme.textDim, size: 40)));

    // Take up to 4 unique songs
    final ids = <int>[];
    for (final s in songs) { if (!ids.contains(s.id)) ids.add(s.id); if (ids.length >= 4) break; }
    // Pad to 4 if needed
    while (ids.length < 4 && ids.isNotEmpty) ids.add(ids[ids.length % ids.length]);

    return Row(children: [
      Expanded(child: Column(children: [
        Expanded(child: _ArtQuad(songId: ids[0])),
        Expanded(child: _ArtQuad(songId: ids.length > 1 ? ids[1] : ids[0])),
      ])),
      Expanded(child: Column(children: [
        Expanded(child: _ArtQuad(songId: ids.length > 2 ? ids[2] : ids[0])),
        Expanded(child: _ArtQuad(songId: ids.length > 3 ? ids[3] : ids[0])),
      ])),
    ]);
  }
}

class _ArtQuad extends StatelessWidget {
  final int songId;
  const _ArtQuad({required this.songId});
  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(id: songId, type: ArtworkType.AUDIO, size: 200,
      artworkFit: BoxFit.cover, artworkWidth: double.infinity, artworkHeight: double.infinity,
      nullArtworkWidget: Container(color: CyberTheme.bgTerminal,
        child: const Icon(Icons.music_note, color: CyberTheme.textDim, size: 20)));
  }
}

// Detail screen
class _TileDetail extends StatelessWidget {
  final String name; final List<Song> songs; final Color accent;
  const _TileDetail({required this.name, required this.songs, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CyberTheme.border, width: 0.5))),
        child: Row(children: [
          IconButton(icon: Icon(Icons.arrow_back, color: accent, size: 22), onPressed: () => Navigator.pop(context)),
          Expanded(child: Text(name, style: CyberTheme.headerText(size: 14, color: accent), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${songs.length}', style: CyberTheme.labelText(color: CyberTheme.textDim)), const SizedBox(width: 8),
          GestureDetector(onTap: () { if (songs.isNotEmpty) context.read<MusicProvider>().playSong(songs.first, songs); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: accent), borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 8)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.play_arrow, color: accent, size: 16), const SizedBox(width: 4),
                Text('PLAY', style: CyberTheme.labelText(color: accent))]))),
          const SizedBox(width: 8),
        ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.only(bottom: 20),
        itemCount: songs.length, itemBuilder: (_, i) => SongTile(song: songs[i], contextSongs: songs, index: i))),
    ]);
  }
}
