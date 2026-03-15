import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';

enum LoopMode { off, all, one }

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
  LoopMode _loopMode = LoopMode.off;
  List<int> _shuffleOrder = [];
  bool _disposed = false;

  AudioPlayer get player => _player;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  bool get shuffle => _shuffle;
  LoopMode get loopMode => _loopMode;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration?, PlayerState, PositionData>(
        _player.positionStream, _player.durationStream, _player.playerStateStream,
        (p, d, s) => PositionData(position: p, duration: d ?? Duration.zero, state: s),
      ).handleError((e) => print('[AUDIO] Stream: $e'));

  AudioPlayerService() {
    _player = AudioPlayer();
    _player.playerStateStream.listen(
      (state) { if (state.processingState == ProcessingState.completed) _onTrackComplete(); },
      onError: (e) => print('[AUDIO] State: $e'),
    );
  }

  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    print('[AUDIO] playQueue ${songs.length} songs, start=$startIndex');
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, songs.length - 1);
    if (_shuffle) _generateShuffleOrder();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_disposed) return;
    final song = currentSong;
    if (song == null) return;

    final contentUri = Uri.parse('content://media/external/audio/media/${song.id}');
    print('[AUDIO] >>> "${song.title}" => $contentUri');

    try {
      try { await _player.stop(); } catch (_) {}

      // Set audio source with MediaItem tag for notification
      // artUri uses content URI to album art via MediaStore
      final artUri = Uri.parse('content://media/external/audio/albumart/${song.id}');

      await _player.setAudioSource(
        AudioSource.uri(
          contentUri,
          tag: MediaItem(
            id: song.id.toString(),
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: Duration(milliseconds: song.duration),
            artUri: artUri,
          ),
        ),
      );
      await _player.play();
      print('[AUDIO] OK playing "${song.title}"');
    } catch (e) {
      print('[AUDIO] ERROR: $e');
      // Fallback file path
      if (song.data != null && song.data!.isNotEmpty) {
        try {
          print('[AUDIO] Fallback file: ${song.data}');
          await _player.setAudioSource(
            AudioSource.file(
              song.data!,
              tag: MediaItem(
                id: song.id.toString(),
                title: song.title,
                artist: song.artist,
                album: song.album,
                duration: Duration(milliseconds: song.duration),
              ),
            ),
          );
          await _player.play();
          print('[AUDIO] Fallback OK');
          return;
        } catch (e2) { print('[AUDIO] Fallback FAIL: $e2'); }
      }
      if (_queue.length > 1) { await Future.delayed(const Duration(milliseconds: 300)); await next(); }
    }
  }

  void _onTrackComplete() {
    switch (_loopMode) {
      case LoopMode.one:
        try { _player.seek(Duration.zero); _player.play(); } catch (_) {}
        break;
      case LoopMode.all: next(); break;
      case LoopMode.off: if (_currentIndex < _queue.length - 1) next(); break;
    }
  }

  Future<void> play() async { try { await _player.play(); } catch (_) {} }
  Future<void> pause() async { try { await _player.pause(); } catch (_) {} }
  Future<void> togglePlayPause() async { _player.playing ? await pause() : await play(); }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_shuffle && _shuffleOrder.isNotEmpty) {
      final i = _shuffleOrder.indexOf(_currentIndex);
      if (i >= 0 && i < _shuffleOrder.length - 1) _currentIndex = _shuffleOrder[i + 1];
      else if (_loopMode == LoopMode.all) { _generateShuffleOrder(); _currentIndex = _shuffleOrder.first; }
      else return;
    } else {
      if (_currentIndex < _queue.length - 1) _currentIndex++;
      else if (_loopMode == LoopMode.all) _currentIndex = 0;
      else return;
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    try { if (_player.position.inSeconds > 3) { await _player.seek(Duration.zero); return; } } catch (_) {}
    if (_shuffle && _shuffleOrder.isNotEmpty) {
      final i = _shuffleOrder.indexOf(_currentIndex);
      if (i > 0) _currentIndex = _shuffleOrder[i - 1];
    } else { if (_currentIndex > 0) _currentIndex--; }
    await _playCurrent();
  }

  Future<void> seek(Duration p) async { try { await _player.seek(p); } catch (_) {} }
  void toggleShuffle() { _shuffle = !_shuffle; if (_shuffle) _generateShuffleOrder(); }
  void toggleLoopMode() {
    _loopMode = _loopMode == LoopMode.off ? LoopMode.all : _loopMode == LoopMode.all ? LoopMode.one : LoopMode.off;
  }

  void _generateShuffleOrder() {
    _shuffleOrder = List.generate(_queue.length, (i) => i)..shuffle(Random());
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _shuffleOrder.remove(_currentIndex); _shuffleOrder.insert(0, _currentIndex);
    }
  }

  Future<void> dispose() async { _disposed = true; try { await _player.dispose(); } catch (_) {} }
}
