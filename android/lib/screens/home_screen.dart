import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../widgets/song_tile.dart';
import '../models/song.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return Column(
      children: [
        // Terminal header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('CYBERPLAYER', style: CyberTheme.headerText(size: 18)),
                  const Spacer(),
                  Text(
                    '${provider.allSongs.length} tracks',
                    style: CyberTheme.labelText(color: CyberTheme.textDim),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'root@cyber:~/music\$',
                style: CyberTheme.terminalText(size: 11, color: CyberTheme.textDim),
              ),
            ],
          ),
        ),

        const CyberDivider(),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            controller: _searchController,
            style: CyberTheme.terminalText(color: CyberTheme.textPrimary, size: 13),
            cursorColor: CyberTheme.neonCyan,
            decoration: CyberTheme.searchInputDecoration('grep -i "track"'),
            onChanged: (q) => provider.setSearchQuery(q),
          ),
        ),

        // View mode tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _ViewModeTab(
                label: 'FOLDERS',
                icon: Icons.folder_outlined,
                active: provider.viewMode == ViewMode.folders,
                onTap: () => provider.setViewMode(ViewMode.folders),
              ),
              const SizedBox(width: 6),
              _ViewModeTab(
                label: 'ALBUMS',
                icon: Icons.album_outlined,
                active: provider.viewMode == ViewMode.albums,
                onTap: () => provider.setViewMode(ViewMode.albums),
              ),
              const SizedBox(width: 6),
              _ViewModeTab(
                label: 'ARTISTS',
                icon: Icons.person_outline,
                active: provider.viewMode == ViewMode.artists,
                onTap: () => provider.setViewMode(ViewMode.artists),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Song list
        Expanded(
          child: provider.isLoading
              ? _buildLoading()
              : provider.error != null
                  ? _buildError(provider.error!)
                  : _buildSongList(provider),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: CyberTheme.neonCyan),
          ),
          const SizedBox(height: 16),
          Text('> SCANNING_FILESYSTEM...', style: CyberTheme.terminalText(size: 12)),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: CyberTheme.error, size: 40),
            const SizedBox(height: 16),
            Text(
              error,
              style: CyberTheme.terminalText(color: CyberTheme.error, size: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.read<MusicProvider>().init(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: CyberTheme.neonCyan, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '> RETRY',
                  style: CyberTheme.terminalText(
                    color: CyberTheme.neonCyan,
                    weight: FontWeight.bold,
                    size: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(MusicProvider provider) {
    final Map<String, List<Song>> grouped;

    switch (provider.viewMode) {
      case ViewMode.folders:
        grouped = provider.songsByFolder;
        break;
      case ViewMode.albums:
        grouped = provider.songsByAlbum;
        break;
      case ViewMode.artists:
        grouped = provider.songsByArtist;
        break;
    }

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('> NO_RESULTS_FOUND', style: CyberTheme.terminalText(color: CyberTheme.textDim)),
            if (provider.allSongs.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'No music files detected on device.',
                style: CyberTheme.labelText(),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: entries.length,
      itemBuilder: (context, groupIndex) {
        final entry = entries[groupIndex];
        return _FolderGroup(
          name: entry.key,
          songs: entry.value,
          viewMode: provider.viewMode,
        );
      },
    );
  }
}

class _ViewModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ViewModeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? CyberTheme.bgCardHover : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: active ? CyberTheme.neonCyan : CyberTheme.border,
                width: active ? 1.5 : 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? CyberTheme.neonCyan : CyberTheme.textDim),
              const SizedBox(width: 6),
              Text(label, style: CyberTheme.labelText(color: active ? CyberTheme.neonCyan : CyberTheme.textDim)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderGroup extends StatefulWidget {
  final String name;
  final List<Song> songs;
  final ViewMode viewMode;

  const _FolderGroup({required this.name, required this.songs, required this.viewMode});

  @override
  State<_FolderGroup> createState() => _FolderGroupState();
}

class _FolderGroupState extends State<_FolderGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.viewMode) {
      ViewMode.folders => CyberTheme.neonYellow,
      ViewMode.albums => CyberTheme.neonBlue,
      ViewMode.artists => CyberTheme.neonPurple,
    };

    final icon = switch (widget.viewMode) {
      ViewMode.folders => Icons.folder_outlined,
      ViewMode.albums => Icons.album_outlined,
      ViewMode.artists => Icons.person_outline,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.name,
                    style: CyberTheme.terminalText(color: color, size: 12, weight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('(${widget.songs.length})', style: CyberTheme.labelText(color: CyberTheme.textDim)),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...List.generate(widget.songs.length, (i) {
            return SongTile(
              song: widget.songs[i],
              contextSongs: widget.songs,
              index: i,
            );
          }),
      ],
    );
  }
}
