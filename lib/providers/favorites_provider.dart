import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/track.dart';

/// Holds the user's favourited tracks, backed by a dedicated Hive box so
/// favourites survive an app restart.
///
/// Each favourite is stored as its own entry, keyed by track id - unlike
/// TrackRepository's home-page cache (one big list under one key, replaced
/// wholesale on every successful fetch), favourites are added and removed
/// one track at a time, so a keyed box gives cheap add/remove/lookup instead
/// of rewriting one giant list on every toggle.
class FavoritesProvider extends ChangeNotifier {
  static const boxName = 'favorite_tracks';

  Box get _box => Hive.box(boxName);

  final Map<String, Track> _favorites = {};

  FavoritesProvider() {
    for (final key in _box.keys) {
      final raw = Map<String, dynamic>.from(_box.get(key) as Map);
      _favorites[key as String] = Track.fromJson(raw);
    }
  }

  List<Track> get favorites => List.unmodifiable(_favorites.values);

  bool isFavorite(String trackId) => _favorites.containsKey(trackId);

  Future<void> toggle(Track track) async {
    if (_favorites.containsKey(track.id)) {
      _favorites.remove(track.id);
      await _box.delete(track.id);
    } else {
      _favorites[track.id] = track;
      await _box.put(track.id, track.toJson());
    }
    notifyListeners();
  }
}
