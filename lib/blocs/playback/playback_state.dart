import 'package:equatable/equatable.dart';

import '../../models/track.dart';

/// Named PlaybackState (not PlayerState) because just_audio already exports a
/// class called PlayerState, and the two would clash.
class PlaybackState extends Equatable {
  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? error;

  const PlaybackState({
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  Track? get currentTrack => (currentIndex >= 0 && currentIndex < queue.length)
      ? queue[currentIndex]
      : null;

  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;

  /// Unlike TrackListState, error IS carried over by default - it has to
  /// survive the position ticks that keep arriving after a failed track.
  /// Pass clearError: true to remove it.
  PlaybackState copyWith({
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? error,
    bool clearError = false,
  }) {
    return PlaybackState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    queue,
    currentIndex,
    isPlaying,
    position,
    duration,
    error,
  ];
}
