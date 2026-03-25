import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/cyber_theme.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});
  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _volume = 1.0;
  bool _showVolume = false;
  OverlayEntry? _plOverlay;

  void _togglePlaylistPanel(BuildContext context) {
    if (!context.mounted) return;
    try {
      if (_plOverlay != null) { _plOverlay!.remove(); _plOverlay = null; return; }
      final provider = context.read<MusicProvider>();
      final song = provider.audio.currentSong;
      if (song == null) return;
      _plOverlay = OverlayEntry(builder: (_) => _PlOverlay(songId: song.id, onClose: () { _plOverlay?.remove(); _plOverlay = null; }));
      Overlay.of(context).insert(_plOverlay!);
    } catch (e) {
      print('[PLAYER] Overlay error: $e');
      _plOverlay = null;
    }
  }

  @override
  void dispose() { _plOverlay?.remove(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.audio.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Container(
      height: 110,
      decoration: BoxDecoration(color: CyberTheme.bgCard,
        border: const Border(top: BorderSide(color: CyberTheme.neonCyan, width: 0.5)),
        boxShadow: [BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Progress line
        StreamBuilder<PositionData>(stream: provider.audio.positionDataStream, builder: (_, snap) {
          final pos = snap.data?.position ?? Duration.zero;
          final dur = snap.data?.duration ?? Duration.zero;
          final p = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;
          return LinearProgressIndicator(value: p, backgroundColor: CyberTheme.border,
            valueColor: const AlwaysStoppedAnimation(CyberTheme.neonCyan), minHeight: 2);
        }),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            // Row 1: Art + title + controls + volume/playlist
            Row(children: [
              // Art + title (tap to open now playing)
              GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const NowPlayingScreen(),
                    transitionsBuilder: (_, a, __, c) => SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
                    transitionDuration: const Duration(milliseconds: 300))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, size: 100,
                      artworkWidth: 42, artworkHeight: 42, artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(width: 42, height: 42, color: CyberTheme.bgTerminal,
                        child: const Icon(Icons.music_note, color: CyberTheme.neonCyan, size: 18)))),
                  const SizedBox(width: 8),
                  SizedBox(width: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(song.title, style: CyberTheme.terminalText(size: 11, color: CyberTheme.neonCyan, weight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist, style: CyberTheme.labelText(color: CyberTheme.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
              const Spacer(),
              // Transport
              _B(Icons.skip_previous, CyberTheme.textPrimary, () => provider.previous()),
              StreamBuilder<bool>(stream: provider.audio.playingStream, builder: (_, s) {
                final p = s.data ?? false;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(border: Border.all(color: CyberTheme.neonCyan, width: 1),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.2), blurRadius: 8)]),
                  child: InkWell(onTap: () => provider.togglePlayPause(),
                    child: Padding(padding: const EdgeInsets.all(5),
                      child: Icon(p ? Icons.pause : Icons.play_arrow, color: CyberTheme.neonCyan, size: 20))));
              }),
              _B(Icons.skip_next, CyberTheme.textPrimary, () => provider.next()),
              const SizedBox(width: 4),
              // Volume toggle
              GestureDetector(onTap: () => setState(() => _showVolume = !_showVolume),
                child: Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: _showVolume ? CyberTheme.neonCyan : CyberTheme.textDim, size: 18)),
              const SizedBox(width: 6),
              // Playlist add
              GestureDetector(onTap: () => _togglePlaylistPanel(context),
                child: Icon(Icons.playlist_add,
                  color: _plOverlay != null ? CyberTheme.neonPurple : CyberTheme.textDim, size: 18)),
            ]),
            const SizedBox(height: 4),
            // Row 2: Seekbar centered
            StreamBuilder<PositionData>(stream: provider.audio.positionDataStream, builder: (_, snap) {
              final pos = snap.data?.position ?? Duration.zero;
              final dur = snap.data?.duration ?? Duration.zero;
              final mx = dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
              final cv = pos.inMilliseconds.toDouble().clamp(0.0, mx);
              return Row(children: [
                Text(_f(pos), style: CyberTheme.labelText(color: CyberTheme.textDim)),
                Expanded(child: SliderTheme(
                  data: SliderThemeData(trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: CyberTheme.neonCyan, inactiveTrackColor: CyberTheme.border,
                    thumbColor: CyberTheme.neonCyan, overlayColor: CyberTheme.neonCyan.withOpacity(0.1)),
                  child: Slider(value: cv, max: mx,
                    onChanged: (v) => provider.seek(Duration(milliseconds: v.toInt()))))),
                Text(_f(dur), style: CyberTheme.labelText(color: CyberTheme.textDim)),
              ]);
            }),
            // Row 3: Volume slider (if shown)
            if (_showVolume)
              Row(children: [
                const Icon(Icons.volume_down, color: CyberTheme.textDim, size: 14),
                Expanded(child: SliderTheme(
                  data: SliderThemeData(trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: CyberTheme.neonCyan, inactiveTrackColor: CyberTheme.border,
                    thumbColor: CyberTheme.neonCyan, overlayColor: CyberTheme.neonCyan.withOpacity(0.1)),
                  child: Slider(value: _volume, min: 0, max: 1,
                    onChanged: (v) { setState(() => _volume = v); provider.audio.player.setVolume(v); }))),
                const Icon(Icons.volume_up, color: CyberTheme.textDim, size: 14),
              ]),
          ]))),
      ]),
    );
  }

  String _f(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  Widget _B(IconData icon, Color c, VoidCallback onTap) =>
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, color: c, size: 22)));
}

// Playlist overlay
class _PlOverlay extends StatefulWidget {
  final int songId; final VoidCallback onClose;
  const _PlOverlay({required this.songId, required this.onClose});
  @override
  State<_PlOverlay> createState() => _PlOverlayState();
}
class _PlOverlayState extends State<_PlOverlay> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlists = provider.playlistService.playlists;
    return Stack(children: [
      Positioned.fill(child: GestureDetector(onTap: widget.onClose, child: Container(color: Colors.black26))),
      Positioned(right: 12, bottom: 120, child: Material(color: Colors.transparent,
        child: Container(width: 220, constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(color: CyberTheme.bgCard,
            border: Border.all(color: CyberTheme.neonPurple.withOpacity(0.6), width: 0.8),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: CyberTheme.neonPurple.withOpacity(0.12), blurRadius: 20)]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CyberTheme.border, width: 0.5))),
              child: Row(children: [
                const Icon(Icons.playlist_add, color: CyberTheme.neonPurple, size: 16), const SizedBox(width: 8),
                Text('ADD_TO_STACK', style: CyberTheme.terminalText(size: 11, color: CyberTheme.neonPurple, weight: FontWeight.bold)),
                const Spacer(),
                InkWell(onTap: widget.onClose, child: const Icon(Icons.close, color: CyberTheme.textDim, size: 16)),
              ])),
            if (playlists.isEmpty)
              Padding(padding: const EdgeInsets.all(16),
                child: Text('> NO_STACKS', style: CyberTheme.terminalText(size: 11, color: CyberTheme.textDim)))
            else
              Flexible(child: ListView.builder(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: playlists.length, itemBuilder: (_, i) {
                  final pl = playlists[i]; final inPl = pl.songIds.contains(widget.songId);
                  return InkWell(onTap: () {
                    if (inPl) provider.removeFromPlaylist(i, widget.songId);
                    else provider.addToPlaylist(i, widget.songId);
                    setState(() {});
                  }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(children: [
                      Icon(inPl ? Icons.check_box : Icons.check_box_outline_blank,
                        color: inPl ? CyberTheme.neonPurple : CyberTheme.textDim, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(pl.name, style: CyberTheme.terminalText(size: 12,
                        color: inPl ? CyberTheme.neonPurple : CyberTheme.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ])));
                })),
          ])))),
    ]);
  }
}
