import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'providers/music_provider.dart';
import 'screens/app_shell.dart';
import 'theme/cyber_theme.dart';

Future<void> main() async {
  // MUST be outside any zone guard
  WidgetsFlutterBinding.ensureInitialized();

  // MUST be top-level, before runApp, outside runZonedGuarded
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.cyberplayer.audio',
    androidNotificationChannelName: 'CyberPlayer',
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: true,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: CyberTheme.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CyberPlayerApp());
}

class CyberPlayerApp extends StatelessWidget {
  const CyberPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicProvider()..init(),
      child: MaterialApp(
        title: 'CyberPlayer',
        theme: CyberTheme.themeData,
        debugShowCheckedModeBanner: false,
        home: const _BootScreen(),
      ),
    );
  }
}

class _BootScreen extends StatefulWidget {
  const _BootScreen();
  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  final List<String> _lines = [];
  bool _done = false;

  final _bootSequence = [
    '[BOOT] CyberPlayer v1.0.0',
    '[INIT] Loading audio subsystem...',
    '[INIT] Connecting audio_service...',
    '[SCAN] Mounting /storage/emulated/0...',
    '[SCAN] Indexing audio files...',
    '[OK]   Audio engine ready',
    '[OK]   Background playback enabled',
    '[SYS]  All systems operational',
    '',
    '> Entering CYBERPLAYER...',
  ];

  @override
  void initState() {
    super.initState();
    _runBootSequence();
  }

  Future<void> _runBootSequence() async {
    for (final line in _bootSequence) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _lines.add(line));
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const AppShell();

    return Scaffold(
      backgroundColor: CyberTheme.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.25), blurRadius: 40, spreadRadius: 2),
                    BoxShadow(color: CyberTheme.neonPurple.withOpacity(0.1), blurRadius: 60, spreadRadius: 5),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 200,
                      color: CyberTheme.bgCard,
                      child: const Icon(Icons.music_note, color: CyberTheme.neonCyan, size: 64),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('CYBERPLAYER', style: CyberTheme.headerText(size: 28)),
              const SizedBox(height: 4),
              Text('TERMINAL AUDIO SYSTEM', style: CyberTheme.labelText(color: CyberTheme.textDim)),
              const SizedBox(height: 40),
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _lines
                      .map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              line,
                              style: CyberTheme.terminalText(
                                size: 11,
                                color: line.startsWith('[OK]')
                                    ? CyberTheme.success
                                    : line.startsWith('[ERR]')
                                        ? CyberTheme.error
                                        : CyberTheme.textTerminal,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
