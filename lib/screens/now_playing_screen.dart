import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../widgets/seek_bar.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Consumer<PlayerProvider>(
        builder: (context, player, _) {
          final track = player.currentTrack;
          if (track == null) {
            return const Center(child: Text('Nothing is playing.'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: track.imageUrl.isEmpty
                        ? Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.music_note, size: 64),
                          )
                        : CachedNetworkImage(
                            imageUrl: track.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note, size: 64),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  track.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  track.artistName,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (player.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    player.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SeekBar(
                  position: player.position,
                  duration: player.duration,
                  onSeek: player.seek,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: player.hasPrevious ? player.previous : null,
                    ),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      iconSize: 40,
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: player.togglePlayPause,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next),
                      onPressed: player.hasNext ? player.next : null,
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.shuffle),
                      onPressed: player.playRandomSong,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
