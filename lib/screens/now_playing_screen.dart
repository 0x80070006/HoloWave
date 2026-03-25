import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/cyber_theme.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.audio.currentSong;
    if (song == null) {
      return Scaffold(backgroundColor: CyberTheme.bg,
        body: Center(child: Text('> NO_TRACK', style: CyberTheme.terminalText(color: CyberTheme.textDim))));
    }

    return Scaffold(
      backgroundColor: CyberTheme.bg,
      body: Stack(children: [
        // ── Blurred album art background ──
        Positioned.fill(child: _BlurredBg(albumId: song.id)),
        // ── Dark gradient ──
        Positioned.fill(child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.25), Colors.black.withOpacity(0.65), Colors.black.withOpacity(0.88)],
          )),
        )),
        // ── Content ──
        SafeArea(child: Column(children: [
          // Header
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
                onPressed: () { if (context.mounted) Navigator.pop(context); }),
              Expanded(child: Center(child: Text('NOW_PLAYING', style: CyberTheme.labelText(color: Colors.white70)))),
              const SizedBox(width: 48),
            ])),
          const Spacer(flex: 1),

          // ── Album art + visualizer ──
          Container(
            width: 260, height: 260,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.15), blurRadius: 30)]),
            child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                QueryArtworkWidget(
                  id: song.id, type: ArtworkType.AUDIO, size: 500,
                  artworkFit: BoxFit.cover, artworkWidth: 260, artworkHeight: 260,
                  nullArtworkWidget: Container(width: 260, height: 260,
                    decoration: CyberTheme.terminalDecoration(),
                    child: const Icon(Icons.music_note, color: CyberTheme.neonCyan, size: 64)),
                ),
                Positioned.fill(child: _Viz(provider: provider)),
              ])),
          ),

          const Spacer(flex: 1),

          // ── Track info ──
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              Text(song.title, style: CyberTheme.headerText(size: 20),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(song.artist, style: CyberTheme.terminalText(color: Colors.white70, size: 14)),
              const SizedBox(height: 4),
              Text(song.album, style: CyberTheme.labelText(color: Colors.white38)),
            ])),

          const SizedBox(height: 24),

          // ── Seek bar ──
          StreamBuilder<PositionData>(
            stream: provider.audio.positionDataStream,
            builder: (_, snap) {
              final pos = snap.data?.position ?? Duration.zero;
              final dur = snap.data?.duration ?? Duration.zero;
              final mx = dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
              final cv = pos.inMilliseconds.toDouble().clamp(0.0, mx);
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  SliderTheme(
                    data: Theme.of(context).sliderTheme.copyWith(trackShape: const RectangularSliderTrackShape()),
                    child: Slider(value: cv, max: mx,
                      onChanged: (v) => provider.seek(Duration(milliseconds: v.toInt())))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_f(pos), style: CyberTheme.labelText(color: CyberTheme.neonCyan)),
                      Text(_f(dur), style: CyberTheme.labelText(color: Colors.white38)),
                    ])),
                ]));
            },
          ),

          const SizedBox(height: 12),

          // ── Controls: shuffle | prev | play/pause | next | loop ──
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(icon: Icon(Icons.shuffle,
                color: provider.audio.shuffle ? CyberTheme.neonPink : Colors.white30, size: 22),
                onPressed: provider.toggleShuffle),
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                onPressed: provider.previous),
              StreamBuilder<bool>(stream: provider.audio.playingStream,
                builder: (_, s) {
                  final p = s.data ?? false;
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: CyberTheme.neonCyan, width: 2),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.3), blurRadius: 20)]),
                    child: IconButton(icon: Icon(p ? Icons.pause : Icons.play_arrow,
                      color: CyberTheme.neonCyan, size: 44),
                      onPressed: provider.togglePlayPause, padding: const EdgeInsets.all(12)));
                }),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                onPressed: provider.next),
              IconButton(icon: Icon(provider.audio.repeatMode == CyberRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                color: provider.audio.repeatMode != CyberRepeatMode.off ? CyberTheme.neonPurple : Colors.white30, size: 22),
                onPressed: provider.toggleLoop),
            ])),

          const Spacer(flex: 2),

          Padding(padding: const EdgeInsets.all(16),
            child: Text('[ ${provider.audio.currentIndex + 1} / ${provider.audio.queue.length} ]'
              '${provider.audio.shuffle ? " SHUFFLE" : ""}'
              '${provider.audio.repeatMode == CyberRepeatMode.all ? " LOOP_ALL" : provider.audio.repeatMode == CyberRepeatMode.one ? " LOOP_ONE" : ""}',
              style: CyberTheme.labelText(color: Colors.white24))),
        ])),
      ]),
    );
  }

  String _f(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

/// Loads album art bytes then shows blurred
class _BlurredBg extends StatefulWidget {
  final int albumId;
  const _BlurredBg({required this.albumId});
  @override
  State<_BlurredBg> createState() => _BlurredBgState();
}

class _BlurredBgState extends State<_BlurredBg> {
  Uint8List? _bytes;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(_BlurredBg old) {
    super.didUpdateWidget(old);
    if (old.albumId != widget.albumId) _load();
  }

  Future<void> _load() async {
    try {
      final b = await OnAudioQuery().queryArtwork(widget.albumId, ArtworkType.AUDIO, size: 300, quality: 40);
      if (mounted && b != null && b.isNotEmpty) setState(() => _bytes = b);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) return Container(color: CyberTheme.bg);
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
        child: Image.memory(_bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      ),
    );
  }
}

/// Animated bar visualizer overlay
class _Viz extends StatefulWidget {
  final MusicProvider provider;
  const _Viz({required this.provider});
  @override
  State<_Viz> createState() => _VizState();
}

class _VizState extends State<_Viz> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _c, builder: (_, __) => StreamBuilder<bool>(
      stream: widget.provider.audio.playingStream,
      builder: (_, s) => CustomPaint(painter: _BP(p: _c.value, on: s.data ?? false), size: Size.infinite),
    ));
  }
}

class _BP extends CustomPainter {
  final double p; final bool on;
  _BP({required this.p, required this.on});
  @override
  void paint(Canvas c, Size s) {
    if (!on) return;
    const n = 32; final bw = s.width / n - 1.5;
    for (int i = 0; i < n; i++) {
      final ph = (p * 2 * pi) + (i * 0.25);
      final h = (s.height * 0.12) + (s.height * 0.35) * ((1 + sin(ph)) / 2) * ((1 + sin(ph * 0.7 + 1.2)) / 2);
      c.drawRect(Rect.fromLTWH(i * (bw + 1.5), s.height - h, bw, h),
        Paint()..color = CyberTheme.neonCyan.withOpacity(0.2 + 0.3 * (h / s.height)));
    }
  }
  @override
  bool shouldRepaint(covariant _BP o) => p != o.p || on != o.on;
}
