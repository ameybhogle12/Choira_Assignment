import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/playback/playback_bloc.dart';
import '../blocs/playback/playback_event.dart';
import '../blocs/playback/playback_state.dart';
import '../screens/now_playing_screen.dart';

/// Persistent bottom bar shown whenever a track is loaded. Tapping it opens
/// the full Now Playing screen.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      builder: (context, playback) {
        final track = playback.currentTrack;
        if (track == null) return const SizedBox.shrink();
        final bloc = context.read<PlaybackBloc>();

        return Material(
          elevation: 8,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: track.imageUrl.isEmpty
                        ? const Icon(Icons.music_note)
                        : CachedNetworkImage(
                            imageUrl: track.imageUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          playback.error ?? track.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: playback.error != null
                                ? Theme.of(context).colorScheme.error
                                : null,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      playback.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () => bloc.add(const PlaybackToggleRequested()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: playback.hasNext
                        ? () => bloc.add(const PlaybackNextRequested())
                        : null,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
