import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/track_repository.dart';
import 'track_list_event.dart';
import 'track_list_state.dart';

/// Bloc version of TrackListProvider. Same three pagination rules:
/// - isFetching guards against duplicate requests while one is in flight.
/// - hasMore flips to false when a page comes back short.
/// - A new search or browse starts from a brand-new state, so offset,
///   hasMore and the track list always reset together.
class TrackListBloc extends Bloc<TrackListEvent, TrackListState> {
  static const _pageSize = 20;

  final TrackRepository _repository;

  TrackListBloc({TrackRepository? repository})
    : _repository = repository ?? TrackRepository(),
      super(const TrackListState()) {
    on<TrackListLoadInitialRequested>((event, emit) => _reset('', emit));
    on<TrackListSearchRequested>(
      (event, emit) => _reset(event.query.trim(), emit),
    );
    on<TrackListLoadMoreRequested>(_onLoadMore);
    on<TrackListRetryRequested>(_onRetry);
  }

  Future<void> _reset(String query, Emitter<TrackListState> emit) async {
    emit(TrackListState(status: TrackListStatus.loading, query: query));
    await _fetchPage(emit);
  }

  Future<void> _onLoadMore(
    TrackListLoadMoreRequested event,
    Emitter<TrackListState> emit,
  ) async {
    if (state.isFetching || !state.hasMore || state.pausedAfterError) return;
    await _fetchPage(emit);
  }

  void _onRetry(TrackListRetryRequested event, Emitter<TrackListState> emit) {
    emit(state.copyWith(pausedAfterError: false));
    add(const TrackListLoadMoreRequested());
  }

  Future<void> _fetchPage(Emitter<TrackListState> emit) async {
    final query = state.query;
    final offset = state.offset;
    emit(state.copyWith(isFetching: true));

    try {
      final page = query.isEmpty
          ? await _repository.getTracks(limit: _pageSize, offset: offset)
          : await _repository.searchTracks(
              query: query,
              limit: _pageSize,
              offset: offset,
            );

      // A new search/refresh started while this request was in flight, so
      // this page belongs to a list that no longer exists - drop it.
      if (state.query != query || state.offset != offset) return;

      emit(
        state.copyWith(
          status: TrackListStatus.loaded,
          tracks: [...state.tracks, ...page],
          hasMore: page.length == _pageSize,
          isFetching: false,
        ),
      );
    } catch (e) {
      if (state.query != query || state.offset != offset) return;

      if (state.tracks.isEmpty) {
        emit(
          state.copyWith(
            status: TrackListStatus.error,
            errorMessage: e.toString(),
            isFetching: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: TrackListStatus.loaded,
            paginationError: 'Failed to load more songs. Please try again.',
            pausedAfterError: true,
            isFetching: false,
          ),
        );
      }
    }
  }
}
