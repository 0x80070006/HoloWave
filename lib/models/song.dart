import 'package:on_audio_query/on_audio_query.dart';

class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final String? uri;
  final int duration;
  final String? data;
  final String folder;

  Song({
    required this.id, required this.title, required this.artist, required this.album,
    required this.albumId, this.uri, required this.duration, this.data, required this.folder,
  });

  Uri get artUri => Uri.parse('content://media/external/audio/albumart/$albumId');

  factory Song.fromSongModel(SongModel model) {
    String folder = 'Unknown';
    try {
      final pathParts = (model.data ?? '').split('/');
      if (pathParts.length > 1) { pathParts.removeLast(); folder = pathParts.isNotEmpty ? pathParts.last : 'Unknown'; }
    } catch (_) { folder = 'Unknown'; }

    return Song(
      id: model.id,
      title: model.title.isNotEmpty ? model.title : 'Unknown Title',
      artist: (model.artist != null && model.artist!.isNotEmpty) ? model.artist! : 'Unknown Artist',
      album: (model.album != null && model.album!.isNotEmpty) ? model.album! : 'Unknown Album',
      albumId: model.albumId ?? 0,
      uri: model.uri, duration: model.duration ?? 0, data: model.data, folder: folder,
    );
  }

  String get durationFormatted {
    final d = Duration(milliseconds: duration);
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}

class Playlist {
  String name;
  List<int> songIds;
  String? coverImagePath;
  DateTime createdAt;

  Playlist({required this.name, required this.songIds, this.coverImagePath, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'name': name, 'songIds': songIds, 'coverImagePath': coverImagePath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    try {
      return Playlist(
        name: json['name'] as String? ?? 'Unnamed',
        songIds: (json['songIds'] as List?)?.cast<int>() ?? [],
        coverImagePath: json['coverImagePath'] as String?,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      );
    } catch (_) { return Playlist(name: 'Unnamed', songIds: []); }
  }
}
