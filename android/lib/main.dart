import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'providers/music_provider.dart';
import 'screens/app_shell.dart';
import 'theme/cyber_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: init MUST be here, outside runZonedGuarded, before runApp
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

  FlutterError.onError = (details) => print('[FLUTTER] ${details.exception}');

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

  final _seq = [
    '[BOOT] CyberPlayer v1.0.0',
    '[INIT] Audio engine...',
    '[SCAN] Mounting storage...',
    '[OK]   Audio ready',
    '[OK]   Notifications enabled',
    '[SYS]  All systems operational',
    '> Entering CYBERPLAYER...',
  ];

  @override
  void initState() { super.initState(); _run(); }

  Future<void> _run() async {
    for (final l in _seq) {
      await Future.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;
      setState(() => _lines.add(l));
    }
    await Future.delayed(const Duration(milliseconds: 250));
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
                width: 200, height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.25), blurRadius: 40, spreadRadius: 2)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/logo.png', width: 200, height: 200, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: CyberTheme.neonCyan, size: 64)),
                ),
              ),
              const SizedBox(height: 32),
              Text('CYBERPLAYER', style: CyberTheme.headerText(size: 28)),
              const SizedBox(height: 4),
              Text('TERMINAL AUDIO SYSTEM', style: CyberTheme.labelText(color: CyberTheme.textDim)),
              const SizedBox(height: 40),
              SizedBox(width: 300, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(l, style: CyberTheme.terminalText(size: 11,
                    color: l.startsWith('[OK]') ? CyberTheme.success : CyberTheme.textTerminal)),
                )).toList(),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
