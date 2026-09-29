import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
// `show` because just_audio also exports classes named PlaybackEvent and
// PlayerState, which would clash with ours.
import 'package:just_audio/just_audio.dart'
    show AudioPlayer, PlayerState, ProcessingState;

import 'playback_event.dart';
import 'playback_state.dart';

// Internal events: just_audio reports changes through streams, and the bloc
// turns each stream update into an event it sends to itself. Private (_), so
// only this file can create them - the UI never sends these.
class _PositionChanged extends PlaybackEvent {
  final Duration position;
  const _PositionChanged(this.position);
}

class _DurationChanged extends PlaybackEvent {
  final Duration duration;
  const _DurationChanged(this.duration);
}

class _PlayingChanged extends PlaybackEvent {
  final bool isPlaying;
  const _PlayingChanged(this.isPlaying);
}

/// Bloc version of PlayerProvider. Owns the single AudioPlayer.
class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackState> {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<PlayerState> _playerStateSub;

  PlaybackBloc() : super(const PlaybackState()) {
    on<PlaybackQueueStarted>(_onQueueStarted);
    on<PlaybackToggleRequested>(_onToggle);
    on<PlaybackNextRequested>(_onNext);
    on<PlaybackPreviousRequested>(_onPrevious);
    on<PlaybackSeekRequested>((event, emit) => _player.seek(event.position));

    on<_PositionChanged>((e, emit) => emit(state.copyWith(position: e.position)));
    on<_DurationChanged>((e, emit) => emit(state.copyWith(duration: e.duration)));
    on<_PlayingChanged>((e, emit) => emit(state.copyWith(isPlaying: e.isPlaying)));

    _positionSub = _player.positionStream.listen(
      (p) => add(_PositionChanged(p)),
    );
    _durationSub = _player.durationStream.listen(
      (d) => add(_DurationChanged(d ?? Duration.zero)),
    );
    _playerStateSub = _player.playerStateStream.listen((s) {
      add(_PlayingChanged(s.playing));
      if (s.processingState == ProcessingState.completed) {
        add(const PlaybackNextRequested());
      }
    });
  }

  Future<void> _onQueueStarted(
    PlaybackQueueStarted event,
    Emitter<PlaybackState> emit,
  ) async {
    emit(state.copyWith(queue: event.queue, currentIndex: event.startIndex));
    await _playCurrent(emit);
  }

  void _onToggle(PlaybackToggleRequested event, Emitter<PlaybackState> emit) {
    if (state.currentTrack == null) return;
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> _onNext(
    PlaybackNextRequested event,
    Emitter<PlaybackState> emit,
  ) async {
    if (!state.hasNext) return;
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
    await _playCurrent(emit);
  }

  Future<void> _onPrevious(
    PlaybackPreviousRequested event,
    Emitter<PlaybackState> emit,
  ) async {
    if (!state.hasPrevious) return;
    emit(state.copyWith(currentIndex: state.currentIndex - 1));
    await _playCurrent(emit);
  }

  Future<void> _playCurrent(Emitter<PlaybackState> emit) async {
    final track = state.currentTrack;
    if (track == null) return;
    emit(
      state.copyWith(
        position: Duration.zero,
        duration: Duration.zero,
        clearError: true,
      ),
    );
    try {
      await _player.setUrl(track.audioUrl);
      // Not awaited on purpose: just_audio's play() future only completes
      // when playback stops, which would keep this handler alive all song.
      _player.play();
    } catch (_) {
      // If the user already moved to another track, this failure is stale.
      if (state.currentTrack?.id != track.id) return;
      emit(
        state.copyWith(
          error: 'Could not play "${track.name}" - the stream may be unavailable.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _positionSub.cancel();
    await _durationSub.cancel();
    await _playerStateSub.cancel();
    await _player.dispose();
    return super.close();
  }
}
