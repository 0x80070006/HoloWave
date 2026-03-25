import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final folders = provider.availableFolders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('SETTINGS', style: CyberTheme.headerText(size: 18)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'root@cyber:~/config\$',
            style: CyberTheme.terminalText(size: 11, color: CyberTheme.textDim),
          ),
        ),
        const CyberDivider(),

        // ── Root folder section ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '> ROOT_MUSIC_FOLDER',
            style: CyberTheme.terminalText(
              color: CyberTheme.neonYellow,
              weight: FontWeight.bold,
              size: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select the root folder containing your music. Only .mp3 files inside this folder (and its subfolders) will be shown.',
            style: CyberTheme.terminalText(color: CyberTheme.textSecondary, size: 11),
          ),
        ),
        const SizedBox(height: 8),

        // Current selection
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: CyberTheme.terminalDecoration(),
          child: Row(
            children: [
              const Icon(Icons.folder, color: CyberTheme.neonYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.rootFolder ?? 'ALL_FOLDERS (no filter)',
                  style: CyberTheme.terminalText(
                    size: 12,
                    color: provider.rootFolder != null
                        ? CyberTheme.neonCyan
                        : CyberTheme.textDim,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider.rootFolder != null)
                GestureDetector(
                  onTap: () => provider.setRootFolder(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: CyberTheme.error, width: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'CLEAR',
                      style: CyberTheme.labelText(color: CyberTheme.error),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Folder list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '> SELECT_FOLDER (${folders.length} found)',
            style: CyberTheme.terminalText(
              color: CyberTheme.textSecondary,
              size: 11,
            ),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: folders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_off, color: CyberTheme.textDim, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        provider.isLoading
                            ? '> SCANNING...'
                            : '> NO_FOLDERS_FOUND',
                        style: CyberTheme.terminalText(color: CyberTheme.textDim, size: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 140),
                  itemCount: folders.length,
                  itemBuilder: (_, i) {
                    final folder = folders[i];
                    final isSelected = provider.rootFolder == folder;
                    // Count songs in this folder
                    final songCount = provider.allSongs
                        .where((s) => (s.data ?? '').startsWith(folder))
                        .length;
                    // Get short display name
                    final parts = folder.split('/');
                    final shortName = parts.length > 1 ? parts.last : folder;
                    // Depth indicator
                    final depth = folder.split('/').length - 4;

                    return GestureDetector(
                      onTap: () => provider.setRootFolder(isSelected ? null : folder),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                        padding: EdgeInsets.only(
                          left: 12.0 + (depth.clamp(0, 6) * 12.0),
                          right: 12,
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: CyberTheme.cardDecoration(active: isSelected),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.folder : Icons.folder_outlined,
                              color: isSelected
                                  ? CyberTheme.neonCyan
                                  : CyberTheme.neonYellow.withOpacity(0.6),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shortName,
                                    style: CyberTheme.terminalText(
                                      size: 12,
                                      color: isSelected
                                          ? CyberTheme.neonCyan
                                          : CyberTheme.textPrimary,
                                      weight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    folder,
                                    style: CyberTheme.labelText(
                                      color: CyberTheme.textDim,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$songCount',
                              style: CyberTheme.labelText(
                                color: isSelected
                                    ? CyberTheme.neonCyan
                                    : CyberTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Rescan button
        Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => provider.rescan(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: CyberTheme.neonCyan, width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  '> RESCAN_FILESYSTEM',
                  style: CyberTheme.terminalText(
                    color: CyberTheme.neonCyan,
                    weight: FontWeight.bold,
                    size: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
