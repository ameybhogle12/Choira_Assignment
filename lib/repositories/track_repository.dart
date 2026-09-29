import 'package:hive_flutter/hive_flutter.dart';

import '../models/track.dart';
import '../services/jamendo_api.dart';

/// Single point of contact for track data. Screens and blocs only ever
/// talk to this class, never to [JamendoApi] or [Hive] directly - so the
/// data source (network, cache, a future second API) can change behind this
/// one interface.
class TrackRepository {
  static const cacheBoxName = 'tracks_cache';
  static const _homeCacheKey = 'home_tracks';

  final JamendoApi _api;

  TrackRepository({JamendoApi? api}) : _api = api ?? JamendoApi();

  Box get _box => Hive.box(cacheBoxName);

  /// Browse (non-search) page. Only the first page (offset 0) is cached -
  /// that's enough to show something on a cold start with no network.
  Future<List<Track>> getTracks({required int limit, required int offset}) async {
    try {
      final tracks = await _api.getTracks(limit: limit, offset: offset);
      if (offset == 0) await _cacheHomeTracks(tracks);
      return tracks;
    } catch (e) {
      if (offset == 0) {
        final cached = getCachedHomeTracks();
        if (cached.isNotEmpty) return cached;
      }
      rethrow;
    }
  }

  /// Search results are never cached - a stale search result is worse than
  /// an empty one, and search is explicitly a separate paginated stream.
  Future<List<Track>> searchTracks({
    required String query,
    required int limit,
    required int offset,
  }) {
    return _api.searchTracks(query: query, limit: limit, offset: offset);
  }

  Future<void> _cacheHomeTracks(List<Track> tracks) async {
    final raw = tracks.map((t) => t.toJson()).toList();
    await _box.put(_homeCacheKey, raw);
  }

  List<Track> getCachedHomeTracks() {
    final raw = _box.get(_homeCacheKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
