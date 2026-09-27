import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';

/// Wraps a single [AudioPlayer] and exposes playback as plain state, so
/// widgets just read fields instead of subscribing to streams themselves.
class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<Track> _queue = [];
  int _currentIndex = -1;
  String? _error;

  PlayerProvider() {
    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  bool get hasTrack => currentTrack != null;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  String? get error => _error;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  /// Starts playing [queue] from [startIndex]. Next/previous walk this same
  /// queue, so playing from a search result list and playing from the home
  /// list behave the same way.
  Future<void> playQueue(List<Track> queue, int startIndex) async {
    _queue = queue;
    _currentIndex = startIndex;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final track = currentTrack;
    if (track == null) return;
    _error = null;
    notifyListeners();
    try {
      await _player.setUrl(track.audioUrl);
      await _player.play();
    } catch (_) {
      _error = 'Could not play "${track.name}" - the stream may be unavailable.';
      notifyListeners();
    }
  }

  void togglePlayPause() {
    if (currentTrack == null) return;
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> next() async {
    if (!hasNext) return;
    _currentIndex++;
    await _playCurrent();
  }

  Future<void> previous() async {
    if (!hasPrevious) return;
    _currentIndex--;
    await _playCurrent();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
