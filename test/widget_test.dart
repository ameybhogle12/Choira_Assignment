import 'package:flutter_test/flutter_test.dart';

import 'package:choira_music/models/track.dart';

void main() {
  test('Track.fromJson parses a real Jamendo response item', () {
    final json = {
      'id': '241',
      'name': 'Simple Exercice',
      'artist_name': 'Both',
      'album_name': 'Simple Exercice',
      'album_image': 'https://example.com/album.jpg',
      'image': 'https://example.com/image.jpg',
      'audio': 'https://example.com/audio.mp3',
      'duration': 340,
    };

    final track = Track.fromJson(json);

    expect(track.id, '241');
    expect(track.name, 'Simple Exercice');
    expect(track.artistName, 'Both');
    expect(track.imageUrl, 'https://example.com/image.jpg');
    expect(track.audioUrl, 'https://example.com/audio.mp3');
    expect(track.durationSeconds, 340);
  });

  test('Track.fromJson falls back to album_image when image is empty', () {
    final json = {
      'id': '242',
      'name': 'No direct image',
      'artist_name': 'Someone',
      'album_image': 'https://example.com/album.jpg',
      'image': '',
      'audio': 'https://example.com/audio.mp3',
      'duration': 100,
    };

    final track = Track.fromJson(json);

    expect(track.imageUrl, 'https://example.com/album.jpg');
  });
}
