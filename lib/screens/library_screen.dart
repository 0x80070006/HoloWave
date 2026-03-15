import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/track_model.dart';
import '../services/playlist_service.dart';
import 'youtube_screen.dart';
import 'playlist_add_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PlaylistService>();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 8),
              child: Row(children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [kPrimary, kSecondary]).createShader(b),
                  child: const Text('Ma Biblio',
                      style: TextStyle(fontFamily: 'SuperWonder',
                          color: Colors.white, fontSize: 26)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _newPlaylist(context, ps),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kPrimary, kAccent]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Nouvelle', style: TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          if (ps.playlists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.library_music_outlined,
                      color: Colors.white.withOpacity(0.1), size: 72),
                  const SizedBox(height: 16),
                  Text('Aucune playlist',
                      style: TextStyle(color: Colors.white.withOpacity(0.4),
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Créez votre première playlist',
                      style: TextStyle(color: Colors.white.withOpacity(0.25),
                          fontSize: 13)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PlaylistTile(
                    playlist: ps.playlists[i],
                    onTap: () => _openPlaylist(context, ps.playlists[i]),
                    onDelete: () => ps.deletePlaylist(ps.playlists[i].id),
                  ),
                  childCount: ps.playlists.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _newPlaylist(BuildContext ctx, PlaylistService ps) async {
    final name = await _inputDialog(ctx, 'Nouvelle playlist', 'Nom de la playlist');
    if (name != null && name.isNotEmpty) {
      ps.createPlaylist(name);
    }
  }

  void _openPlaylist(BuildContext ctx, PlaylistModel pl) {
    Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => _PlaylistDetail(playlist: pl)));
  }

  Future<String?> _inputDialog(BuildContext ctx, String title, String hint) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: kBgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kPrimary.withOpacity(0.4))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kPrimary)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Créer', style: TextStyle(
                  color: kPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PlaylistTile({required this.playlist, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: playlist.thumbnailUrl != null
                ? CachedNetworkImage(imageUrl: playlist.thumbnailUrl!,
                    width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [kPrimary.withOpacity(0.6), kAccent.withOpacity(0.4)]),
                    ),
                    child: const Icon(Icons.queue_music, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(playlist.name,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 3),
              Text('${playlist.tracks.length} vidéo${playlist.tracks.length != 1 ? "s" : ""}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          )),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: kBgSurface,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                  onTap: () { Navigator.pop(context); onDelete(); },
                ),
                const SizedBox(height: 16),
              ]),
            ),
            child: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.3)),
          ),
        ]),
      ),
    );
  }
}

// ── Détail playlist ──────────────────────────────────────────────
class _PlaylistDetail extends StatelessWidget {
  final PlaylistModel playlist;
  const _PlaylistDetail({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(playlist.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: playlist.tracks.isEmpty
          ? Center(child: Text('Playlist vide',
              style: TextStyle(color: Colors.white.withOpacity(0.4))))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: playlist.tracks.length,
              itemBuilder: (ctx, i) {
                final t = playlist.tracks[i];
                return GestureDetector(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => YouTubeScreen(
                          initialUrl: 'https://m.youtube.com/watch?v=${t.id}'))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: kBgCard, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: t.thumbnailUrl != null
                            ? CachedNetworkImage(imageUrl: t.thumbnailUrl!,
                                width: 60, height: 40, fit: BoxFit.cover)
                            : Container(width: 60, height: 40, color: kBgSurface,
                                child: Icon(Icons.play_arrow, color: kPrimary, size: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(t.artist, style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                        ],
                      )),
                      const Icon(Icons.play_circle_outline, color: kPrimary, size: 24),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
