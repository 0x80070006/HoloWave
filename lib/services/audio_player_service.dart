import 'dart:io';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio/just_audio.dart' show AudioPlayer, AudioSource, ConcatenatingAudioSource, PlayerState;
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';

enum CyberRepeatMode { off, all, one }

class PositionData {
  final Duration position;
  final Duration duration;
  final PlayerState state;
  PositionData({required this.position, required this.duration, required this.state});
}

class AudioPlayerService {
  late AudioPlayer _player;
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  CyberRepeatMode _repeatMode = CyberRepeatMode.off;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Map<int, Uri> _artCache = {};

  AudioPlayer get player => _player;
  List<Song> get queue => _queue;
  int get currentIndex => _player.currentIndex ?? _currentIndex;
  Song? get currentSong {
    final idx = currentIndex;
    return idx >= 0 && idx < _queue.length ? _queue[idx] : null;
  }
  bool get shuffle => _shuffle;
  CyberRepeatMode get repeatMode => _repeatMode;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration?, PlayerState, PositionData>(
        _player.positionStream, _player.durationStream, _player.playerStateStream,
        (p, d, s) => PositionData(position: p, duration: d ?? Duration.zero, state: s),
      ).handleError((e) => print('[AUDIO] Stream: $e'));

  AudioPlayerService() { _player = AudioPlayer(); }

  Future<Uri?> _getArt(int songId) async {
    if (_artCache.containsKey(songId)) return _artCache[songId];
    try {
      final bytes = await _audioQuery.queryArtwork(songId, ArtworkType.AUDIO, size: 300, quality: 80);
      if (bytes != null && bytes.isNotEmpty) {
        final file = File('${Directory.systemTemp.path}/cyberart_$songId.jpg');
        await file.writeAsBytes(bytes);
        _artCache[songId] = file.uri;
        return file.uri;
      }
    } catch (_) {}
    return null;
  }

  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, songs.length - 1);
    print('[AUDIO] Queue: ${songs.length} songs, start=$startIndex');

    // Fetch all artwork in parallel (typically < 1s for 40 songs)
    await Future.wait(songs.map((s) => _getArt(s.id)), eagerError: false);

    // Build playlist with artwork
    final sources = songs.map((s) => ja.AudioSource.uri(
      Uri.parse('content://media/external/audio/media/${s.id}'),
      tag: MediaItem(
        id: '${s.id}',
        title: s.title,
        artist: s.artist,
        album: s.album,
        duration: Duration(milliseconds: s.duration),
        artUri: _artCache[s.id],
      ),
    )).toList();

    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: _currentIndex,
      );
      _applyRepeat();
      await _player.setShuffleModeEnabled(_shuffle);
      await _player.play();
      print('[AUDIO] OK playing');
    } catch (e) {
      print('[AUDIO] ERROR: $e');
    }
  }

  void _applyRepeat() {
    switch (_repeatMode) {
      case CyberRepeatMode.off: _player.setLoopMode(ja.LoopMode.off); break;
      case CyberRepeatMode.all: _player.setLoopMode(ja.LoopMode.all); break;
      case CyberRepeatMode.one: _player.setLoopMode(ja.LoopMode.one); break;
    }
  }

  Future<void> play() async { try { await _player.play(); } catch (_) {} }
  Future<void> pause() async { try { await _player.pause(); } catch (_) {} }
  Future<void> togglePlayPause() async { _player.playing ? await pause() : await play(); }
  Future<void> next() async { try { await _player.seekToNext(); } catch (e) { print('[AUDIO] next: $e'); } }
  Future<void> previous() async {
    try {
      if (_player.position.inSeconds > 3) await _player.seek(Duration.zero);
      else await _player.seekToPrevious();
    } catch (e) { print('[AUDIO] prev: $e'); }
  }
  Future<void> seek(Duration p) async { try { await _player.seek(p); } catch (_) {} }
  void toggleShuffle() { _shuffle = !_shuffle; _player.setShuffleModeEnabled(_shuffle); }
  void toggleLoopMode() {
    _repeatMode = _repeatMode == CyberRepeatMode.off ? CyberRepeatMode.all
        : _repeatMode == CyberRepeatMode.all ? CyberRepeatMode.one : CyberRepeatMode.off;
    _applyRepeat();
  }
  Future<void> dispose() async { try { await _player.dispose(); } catch (_) {} }
}
