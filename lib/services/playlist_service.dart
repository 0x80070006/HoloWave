import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class PlaylistService {
  static const _key = 'cyberplayer_playlists';
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _playlists = list
            .map((e) {
              try {
                return Playlist.fromJson(e as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<Playlist>()
            .toList();
      }
    } catch (e) {
      print('Error loading playlists: $e');
      _playlists = [];
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_playlists.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      print('Error saving playlists: $e');
    }
  }

  Future<Playlist> create(String name) async {
    final pl = Playlist(name: name, songIds: []);
    _playlists.add(pl);
    await _save();
    return pl;
  }

  Future<void> delete(int index) async {
    if (index < 0 || index >= _playlists.length) return;
    _playlists.removeAt(index);
    await _save();
  }

  Future<void> addSong(int playlistIndex, int songId) async {
    if (playlistIndex < 0 || playlistIndex >= _playlists.length) return;
    if (!_playlists[playlistIndex].songIds.contains(songId)) {
      _playlists[playlistIndex].songIds.add(songId);
      await _save();
    }
  }

  Future<void> removeSong(int playlistIndex, int songId) async {
    if (playlistIndex < 0 || playlistIndex >= _playlists.length) return;
    _playlists[playlistIndex].songIds.remove(songId);
    await _save();
  }

  Future<void> rename(int index, String newName) async {
    if (index < 0 || index >= _playlists.length) return;
    _playlists[index].name = newName;
    await _save();
  }

  Future<void> setCoverImage(int index, String? path) async {
    if (index < 0 || index >= _playlists.length) return;
    _playlists[index].coverImagePath = path;
    await _save();
  }
}
