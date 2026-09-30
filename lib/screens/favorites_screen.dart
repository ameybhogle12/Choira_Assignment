import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, _) {
          final favorites = favoritesProvider.favorites;

          if (favorites.isEmpty) {
            return Center(
              child: Text(
                'No favorites yet.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return Consumer<PlayerProvider>(
            builder: (context, player, _) {
              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final track = favorites[index];
                  return TrackTile(
                    track: track,
                    isPlaying: player.currentTrack?.id == track.id,
                    isFavorite: true,
                    onTap: () => player.playQueue(favorites, index),
                    onFavoriteToggle: () => favoritesProvider.toggle(track),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
