import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/cyber_widgets.dart';
import 'home_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.bg,
      body: SafeArea(
        child: ScanlineOverlay(
          child: Column(children: [
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: const [HomeScreen(), PlaylistsScreen(), SettingsScreen()],
              ),
            ),
            const MiniPlayer(),
          ]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: CyberTheme.border, width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.terminal, size: 20), label: 'WAVES'),
            BottomNavigationBarItem(icon: Icon(Icons.queue_music, size: 20), label: 'STACKS'),
            BottomNavigationBarItem(icon: Icon(Icons.settings, size: 20), label: 'CONFIG'),
          ],
        ),
      ),
    );
  }
}

/// Wrap detail screens so MiniPlayer stays visible
class DetailShell extends StatelessWidget {
  final Widget child;
  const DetailShell({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.bg,
      body: SafeArea(child: Column(children: [
        Expanded(child: child),
        const MiniPlayer(),
      ])),
    );
  }
}
