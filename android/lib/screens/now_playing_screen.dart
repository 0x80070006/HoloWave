import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.audio.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: CyberTheme.bg,
        body: Center(
          child: Text(
            '> NO_TRACK_LOADED',
            style: CyberTheme.terminalText(color: CyberTheme.textDim),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CyberTheme.bg,
      body: SafeArea(
        child: ScanlineOverlay(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: CyberTheme.neonCyan, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('NOW_PLAYING', style: CyberTheme.labelText(color: CyberTheme.neonCyan)),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Visualizer
              _AsciiVisualizer(provider: provider),

              const Spacer(flex: 1),

              // Track info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      song.title,
                      style: CyberTheme.headerText(size: 20),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(song.artist, style: CyberTheme.terminalText(color: CyberTheme.textSecondary, size: 13)),
                    const SizedBox(height: 4),
                    Text(song.album, style: CyberTheme.labelText(color: CyberTheme.textDim)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seek bar
              StreamBuilder<PositionData>(
                stream: provider.audio.positionDataStream,
                builder: (_, snap) {
                  final pos = snap.data?.position ?? Duration.zero;
                  final dur = snap.data?.duration ?? Duration.zero;
                  final maxVal = dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                  final curVal = pos.inMilliseconds.toDouble().clamp(0.0, maxVal);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: Theme.of(context).sliderTheme.copyWith(
                                trackShape: const RectangularSliderTrackShape(),
                              ),
                          child: Slider(
                            value: curVal,
                            max: maxVal,
                            onChanged: (v) {
                              provider.seek(Duration(milliseconds: v.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos), style: CyberTheme.labelText(color: CyberTheme.neonCyan)),
                              Text(_fmt(dur), style: CyberTheme.labelText()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: provider.audio.shuffle ? CyberTheme.neonPink : CyberTheme.textDim,
                        size: 22,
                      ),
                      onPressed: provider.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: CyberTheme.textPrimary, size: 32),
                      onPressed: provider.previous,
                    ),
                    StreamBuilder<bool>(
                      stream: provider.audio.playingStream,
                      builder: (_, snap) {
                        final playing = snap.data ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: CyberTheme.neonCyan, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.3), blurRadius: 16, spreadRadius: -2),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: CyberTheme.neonCyan,
                              size: 40,
                            ),
                            onPressed: provider.togglePlayPause,
                            padding: const EdgeInsets.all(12),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: CyberTheme.textPrimary, size: 32),
                      onPressed: provider.next,
                    ),
                    IconButton(
                      icon: Icon(
                        provider.audio.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                        color: provider.audio.loopMode != LoopMode.off ? CyberTheme.neonPurple : CyberTheme.textDim,
                        size: 22,
                      ),
                      onPressed: provider.toggleLoop,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Queue info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '[ ${provider.audio.currentIndex + 1} / ${provider.audio.queue.length} ] '
                  '${provider.audio.shuffle ? "SHUFFLE " : ""}'
                  '${provider.audio.loopMode == LoopMode.all ? "LOOP_ALL" : provider.audio.loopMode == LoopMode.one ? "LOOP_ONE" : ""}',
                  style: CyberTheme.labelText(color: CyberTheme.textDim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Animated bar visualizer ──
class _AsciiVisualizer extends StatefulWidget {
  final MusicProvider provider;
  const _AsciiVisualizer({required this.provider});

  @override
  State<_AsciiVisualizer> createState() => _AsciiVisualizerState();
}

class _AsciiVisualizerState extends State<_AsciiVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
      builder: (_, __) {
        return StreamBuilder<bool>(
          stream: widget.provider.audio.playingStream,
          builder: (_, snap) {
            final playing = snap.data ?? false;
            return Container(
              width: 240,
              height: 120,
              decoration: CyberTheme.terminalDecoration(),
              padding: const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _BarPainter(progress: _ctrl.value, playing: playing),
                size: const Size(216, 96),
              ),
            );
          },
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  final double progress;
  final bool playing;

  _BarPainter({required this.progress, required this.playing});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 24;
    final barWidth = size.width / barCount - 2;

    for (int i = 0; i < barCount; i++) {
      final phase = (progress * 2 * pi) + (i * 0.3);
      final height = playing
          ? (size.height * 0.3) +
              (size.height * 0.5) *
                  ((1 + sin(phase)) / 2) *
                  ((1 + sin(phase * 0.7 + 1.2)) / 2)
          : size.height * 0.1;

      final paint = Paint()
        ..color = CyberTheme.neonCyan.withOpacity(
          playing ? 0.4 + 0.6 * (height / size.height) : 0.2,
        )
        ..style = PaintingStyle.fill;

      final x = i * (barWidth + 2);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        paint,
      );

      if (playing) {
        final glowPaint = Paint()
          ..color = CyberTheme.neonCyan.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - height, barWidth, 2),
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      progress != old.progress || playing != old.playing;
}
