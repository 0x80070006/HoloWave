import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/cyber_theme.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.audio.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const NowPlayingScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: CyberTheme.bgCard,
          border: const Border(top: BorderSide(color: CyberTheme.neonCyan, width: 0.5)),
          boxShadow: [
            BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<PositionData>(
              stream: provider.audio.positionDataStream,
              builder: (_, snap) {
                final pos = snap.data?.position ?? Duration.zero;
                final dur = snap.data?.duration ?? Duration.zero;
                final progress = dur.inMilliseconds > 0
                    ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: CyberTheme.border,
                  valueColor: const AlwaysStoppedAnimation(CyberTheme.neonCyan),
                  minHeight: 2,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: CyberTheme.terminalText(size: 12, color: CyberTheme.neonCyan, weight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: CyberTheme.labelText(color: CyberTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Shuffle
                  _MiniButton(
                    icon: Icons.shuffle,
                    color: provider.audio.shuffle ? CyberTheme.neonPink : CyberTheme.textDim,
                    onTap: () { provider.toggleShuffle(); },
                    size: 18,
                  ),
                  // Previous
                  _MiniButton(
                    icon: Icons.skip_previous,
                    color: CyberTheme.textPrimary,
                    onTap: () { provider.previous(); },
                  ),
                  // Play/Pause - main button
                  StreamBuilder<bool>(
                    stream: provider.audio.playingStream,
                    builder: (_, snap) {
                      final playing = snap.data ?? false;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: CyberTheme.neonCyan, width: 1),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.2), blurRadius: 8),
                          ],
                        ),
                        child: InkWell(
                          onTap: () { provider.togglePlayPause(); },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: CyberTheme.neonCyan,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Next
                  _MiniButton(
                    icon: Icons.skip_next,
                    color: CyberTheme.textPrimary,
                    onTap: () { provider.next(); },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _MiniButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
