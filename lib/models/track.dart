class Track {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String imageUrl;
  final String audioUrl;
  final int durationSeconds;

  const Track({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    required this.imageUrl,
    required this.audioUrl,
    required this.durationSeconds,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String?;
    final albumImage = json['album_image'] as String?;
    return Track(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Untitled',
      artistName: (json['artist_name'] as String?)?.trim().isNotEmpty == true
          ? json['artist_name'] as String
          : 'Unknown artist',
      albumName: json['album_name'] as String? ?? '',
      imageUrl: (image?.isNotEmpty ?? false) ? image! : (albumImage ?? ''),
      audioUrl: json['audio'] as String? ?? '',
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'artist_name': artistName,
        'album_name': albumName,
        'image': imageUrl,
        'audio': audioUrl,
        'duration': durationSeconds,
      };
}
