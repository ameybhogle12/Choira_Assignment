import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: track.imageUrl.isEmpty
              ? const _ArtworkPlaceholder()
              : CachedNetworkImage(
                  imageUrl: track.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _ArtworkPlaceholder(),
                  errorWidget: (_, _, _) => const _ArtworkPlaceholder(),
                ),
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isPlaying
            ? TextStyle(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
      subtitle: Text(
        track.artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isPlaying
          ? Icon(Icons.equalizer, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
