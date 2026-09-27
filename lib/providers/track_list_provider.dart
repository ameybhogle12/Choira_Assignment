import 'package:flutter/foundation.dart';

import '../models/track.dart';
import '../repositories/track_repository.dart';

enum TrackListStatus { initial, loading, loaded, error }

/// Holds all state for the home list: browsing, searching, and pagination.
///
/// The three pagination rules the assignment calls out explicitly live here:
/// - [_isFetching] guards every fetch so a duplicate request while one is
///   already in flight is simply ignored.
/// - [hasMore] flips to false the moment a page comes back shorter than
///   [_pageSize] - that page was the last one.
/// - [search] and [loadInitial] reset offset, hasMore and the track list
///   together, so browse and search never bleed into each other.
class TrackListProvider extends ChangeNotifier {
  static const _pageSize = 20;

  final TrackRepository _repository;

  TrackListProvider({TrackRepository? repository})
    : _repository = repository ?? TrackRepository();

  final List<Track> _tracks = [];
  List<Track> get tracks => List.unmodifiable(_tracks);

  TrackListStatus _status = TrackListStatus.initial;
  TrackListStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isFetching = false;
  bool get isFetchingMore => _isFetching && _tracks.isNotEmpty;

  String? _paginationError;
  String? get paginationError => _paginationError;

  String _query = '';
  bool get isSearching => _query.isNotEmpty;

  Future<void> loadInitial() => _reset(query: '');

  Future<void> search(String query) => _reset(query: query.trim());

  Future<void> clearSearch() => loadInitial();

  Future<void> loadMore() async {
    if (_isFetching || !_hasMore) return;
    await _fetchPage();
  }

  Future<void> _reset({required String query}) async {
    _query = query;
    _offset = 0;
    _hasMore = true;
    _tracks.clear();
    _status = TrackListStatus.loading;
    _errorMessage = null;
    notifyListeners();
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (_isFetching) return;
    _isFetching = true;
    if (_tracks.isEmpty) notifyListeners(); // show the loading state promptly

    try {
      final page = _query.isEmpty
          ? await _repository.getTracks(limit: _pageSize, offset: _offset)
          : await _repository.searchTracks(
              query: _query,
              limit: _pageSize,
              offset: _offset,
            );

      _tracks.addAll(page);
      _offset += page.length;
      _hasMore = page.length == _pageSize;
      _status = TrackListStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      if (_tracks.isEmpty) {
        // First page failed.
        _status = TrackListStatus.error;
        _errorMessage = e.toString();
      } else {
        // A later page failed.
        // Keep the already-loaded tracks visible.
        _status = TrackListStatus.loaded;

        // This is what the UI will use for the Snackbar.
        _paginationError = 'Failed to load more songs. Please try again.';
      }
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void clearPaginationError() {
    _paginationError = null;
    notifyListeners();
  }
}
