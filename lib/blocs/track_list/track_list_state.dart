import 'package:equatable/equatable.dart';

import '../../models/track.dart';

enum TrackListStatus { initial, loading, loaded, error }

/// An immutable snapshot of the home list. The bloc never changes a field in
/// place - it builds a new TrackListState and emits it, and the UI redraws.
class TrackListState extends Equatable {
  final TrackListStatus status;
  final List<Track> tracks;
  final String query;
  final bool hasMore;
  final bool isFetching;
  final bool pausedAfterError;
  final String? errorMessage;
  final String? paginationError;

  const TrackListState({
    this.status = TrackListStatus.initial,
    this.tracks = const [],
    this.query = '',
    this.hasMore = true,
    this.isFetching = false,
    this.pausedAfterError = false,
    this.errorMessage,
    this.paginationError,
  });

  bool get isSearching => query.isNotEmpty;

  /// The next page starts after everything already loaded, so the offset is
  /// just the list length - no separate counter to keep in sync.
  int get offset => tracks.length;

  /// errorMessage and paginationError are deliberately NOT carried over: every
  /// new state clears them unless they're passed in again. That makes the
  /// pagination SnackBar one-shot for free - it exists in exactly one emitted
  /// state, so there's no clearPaginationError() like the Provider version has.
  TrackListState copyWith({
    TrackListStatus? status,
    List<Track>? tracks,
    bool? hasMore,
    bool? isFetching,
    bool? pausedAfterError,
    String? errorMessage,
    String? paginationError,
  }) {
    return TrackListState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      query: query,
      hasMore: hasMore ?? this.hasMore,
      isFetching: isFetching ?? this.isFetching,
      pausedAfterError: pausedAfterError ?? this.pausedAfterError,
      errorMessage: errorMessage,
      paginationError: paginationError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tracks,
    query,
    hasMore,
    isFetching,
    pausedAfterError,
    errorMessage,
    paginationError,
  ];
}
