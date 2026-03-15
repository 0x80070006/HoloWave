import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/music_scanner.dart';
import '../services/playlist_service.dart';

enum ViewMode { folders, albums, artists }

class MusicProvider extends ChangeNotifier {
  final AudioPlayerService audio = AudioPlayerService();
  final MusicScanner scanner = MusicScanner();
  final PlaylistService playlistService = PlaylistService();

  StreamSubscription? _indexSub;
  StreamSubscription? _stateSub;

  List<Song> _allSongs = [];
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.folders;
  bool _isLoading = true;
  String? _error;
  String? _rootFolder;

  List<Song> get allSongs => _allSongs;
  String get searchQuery => _searchQuery;
  ViewMode get viewMode => _viewMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get rootFolder => _rootFolder;

  List<Song> get filteredSongs {
    var songs = _allSongs;
    if (_rootFolder != null && _rootFolder!.isNotEmpty) {
      songs = songs.where((s) => (s.data ?? '').startsWith(_rootFolder!)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      songs = songs.where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q)).toList();
    }
    return songs;
  }

  Map<String, List<Song>> get songsByFolder => _groupBy((s) => s.folder);
  Map<String, List<Song>> get songsByAlbum => _groupBy((s) => s.album);
  Map<String, List<Song>> get songsByArtist => _groupBy((s) => s.artist);

  Map<String, List<Song>> _groupBy(String Function(Song) keyFn) {
    final map = <String, List<Song>>{};
    for (final s in filteredSongs) { map.putIfAbsent(keyFn(s), () => []).add(s); }
    final sorted = map.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Map.fromEntries(sorted);
  }

  List<String> get availableFolders {
    final folders = <String>{};
    for (final s in _allSongs) {
      final path = s.data;
      if (path == null || path.isEmpty) continue;
      final parts = path.split('/');
      if (parts.length > 2) {
        parts.removeLast();
        String building = '';
        for (final p in parts) {
          if (p.isEmpty) continue;
          building += '/$p';
          if (building.split('/').length > 4) folders.add(building);
        }
      }
    }
    return folders.toList()..sort();
  }

  Future<void> init() async {
    _isLoading = true; _error = null;
    notifyListeners();

    // Listen to track index changes (from notification prev/next)
    _indexSub = audio.currentIndexStream.listen((_) => notifyListeners());
    _stateSub = audio.playerStateStream.listen((_) => notifyListeners());

    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        _rootFolder = prefs.getString('cyberplayer_root_folder');
      } catch (_) {}

      bool hasPerm = false;
      try { hasPerm = await scanner.requestPermission(); } catch (e) { print('Perm: $e'); }
      if (!hasPerm) {
        _error = 'PERMISSION_DENIED: Storage access required.\nTap RETRY after granting permission.';
        _isLoading = false; notifyListeners(); return;
      }

      await Future.delayed(const Duration(milliseconds: 800));
      _allSongs = await scanner.scanAllSongs();
      await playlistService.load();
      _isLoading = false; notifyListeners();
    } catch (e, stack) {
      print('Init: $e\n$stack');
      _error = 'INIT_ERROR: $e'; _isLoading = false; notifyListeners();
    }
  }

  Future<void> setRootFolder(String? path) async {
    _rootFolder = path;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path != null && path.isNotEmpty) await prefs.setString('cyberplayer_root_folder', path);
      else await prefs.remove('cyberplayer_root_folder');
    } catch (_) {}
    notifyListeners();
  }

  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }
  void setViewMode(ViewMode mode) { _viewMode = mode; notifyListeners(); }

  Future<void> playSong(Song song, List<Song> ctx) async {
    try {
      final idx = ctx.indexOf(song);
      await audio.playQueue(ctx, idx >= 0 ? idx : 0);
      notifyListeners();
    } catch (e) { print('Play: $e'); }
  }

  Future<void> togglePlayPause() async { await audio.togglePlayPause(); notifyListeners(); }
  Future<void> next() async { await audio.next(); notifyListeners(); }
  Future<void> previous() async { await audio.previous(); notifyListeners(); }
  void toggleShuffle() { audio.toggleShuffle(); notifyListeners(); }
  void toggleLoop() { audio.toggleLoopMode(); notifyListeners(); }
  Future<void> seek(Duration pos) async { await audio.seek(pos); }

  Future<void> rescan() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _allSongs = await scanner.scanAllSongs();
      _isLoading = false; notifyListeners();
    } catch (e) { _error = 'SCAN: $e'; _isLoading = false; notifyListeners(); }
  }

  Future<void> createPlaylist(String name) async { await playlistService.create(name); notifyListeners(); }
  Future<void> deletePlaylist(int index) async { await playlistService.delete(index); notifyListeners(); }
  Future<void> addToPlaylist(int pi, int sid) async { await playlistService.addSong(pi, sid); notifyListeners(); }
  Future<void> removeFromPlaylist(int pi, int sid) async { await playlistService.removeSong(pi, sid); notifyListeners(); }

  List<Song> getPlaylistSongs(int pi) {
    if (pi < 0 || pi >= playlistService.playlists.length) return [];
    final ids = playlistService.playlists[pi].songIds;
    return _allSongs.where((s) => ids.contains(s.id)).toList();
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _stateSub?.cancel();
    audio.dispose();
    super.dispose();
  }
}
