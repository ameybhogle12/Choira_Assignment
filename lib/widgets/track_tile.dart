import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const TrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              track.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isPlaying
                  ? TextStyle(color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              track.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textWidthBasis: TextWidthBasis.parent,
            ),
          ),
          Text(' • '),
          Text(
            '${track.durationSeconds ~/ 60}:${(track.durationSeconds % 60).toString().padLeft(2, '0')}',
          ),
        ],
      ),
      trailing: Row(
        // ListTile sizes trailing to its content, not the full row width -
        // without this, Row's default MainAxisSize.max fights that.
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: onFavoriteToggle,
          ),
          if (isPlaying)
            Icon(Icons.equalizer, color: Theme.of(context).colorScheme.primary),
        ],
      ),
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
