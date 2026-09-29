import '../../models/track.dart';

/// Everything the UI can ask the player to do. Each maps 1:1 to a method on
/// the old PlayerProvider.
abstract class PlaybackEvent {
  const PlaybackEvent();
}

/// Provider equivalent: playQueue(queue, startIndex).
class PlaybackQueueStarted extends PlaybackEvent {
  final List<Track> queue;
  final int startIndex;
  const PlaybackQueueStarted(this.queue, this.startIndex);
}

/// Provider equivalent: togglePlayPause().
class PlaybackToggleRequested extends PlaybackEvent {
  const PlaybackToggleRequested();
}

/// Provider equivalent: next().
class PlaybackNextRequested extends PlaybackEvent {
  const PlaybackNextRequested();
}

/// Provider equivalent: previous().
class PlaybackPreviousRequested extends PlaybackEvent {
  const PlaybackPreviousRequested();
}

/// Provider equivalent: seek(position).
class PlaybackSeekRequested extends PlaybackEvent {
  final Duration position;
  const PlaybackSeekRequested(this.position);
}
