/// Everything the UI can ask the track list to do. Each one maps 1:1 to a
/// method on the old TrackListProvider, so the two versions are easy to compare.
abstract class TrackListEvent {
  const TrackListEvent();
}

/// Provider equivalent: loadInitial() / clearSearch().
class TrackListLoadInitialRequested extends TrackListEvent {
  const TrackListLoadInitialRequested();
}

/// Provider equivalent: search(query).
class TrackListSearchRequested extends TrackListEvent {
  final String query;
  const TrackListSearchRequested(this.query);
}

/// Provider equivalent: loadMore().
class TrackListLoadMoreRequested extends TrackListEvent {
  const TrackListLoadMoreRequested();
}

/// Provider equivalent: retryAfterError().
class TrackListRetryRequested extends TrackListEvent {
  const TrackListRetryRequested();
}
