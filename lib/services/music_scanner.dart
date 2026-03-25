import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart';

class MusicScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermission() async {
    try {
      final status = await _audioQuery.permissionsStatus();
      if (status) return true;
      return await _audioQuery.permissionsRequest();
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  Future<List<Song>> scanAllSongs() async {
    try {
      final models = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      return models
          .where((m) => (m.duration ?? 0) > 5000)
          .map((m) {
            try {
              return Song.fromSongModel(m);
            } catch (e) {
              print('Error parsing song ${m.title}: $e');
              return null;
            }
          })
          .whereType<Song>()
          .toList();
    } catch (e) {
      print('Error scanning songs: $e');
      return [];
    }
  }

  OnAudioQuery get audioQuery => _audioQuery;
}
