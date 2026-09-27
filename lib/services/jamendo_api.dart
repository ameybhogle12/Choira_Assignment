import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/track.dart';

class JamendoApiException implements Exception {
  final String message;
  JamendoApiException(this.message);

  @override
  String toString() => message;
}

/// Raw HTTP access to the Jamendo API. Knows nothing about pagination state
/// or caching - it just fetches a page and returns parsed [Track]s.
class JamendoApi {
  static const _baseUrl = 'https://api.jamendo.com/v3.0';

  final http.Client _client;

  JamendoApi({http.Client? client}) : _client = client ?? http.Client();

  String get _clientId => dotenv.env['JAMENDO_CLIENT_ID'] ?? '';

  Future<List<Track>> getTracks({required int limit, required int offset}) {
    final uri = Uri.parse('$_baseUrl/tracks/').replace(queryParameters: {
      'client_id': _clientId,
      'format': 'json',
      'limit': '$limit',
      'offset': '$offset',
    });
    return _fetch(uri);
  }

  Future<List<Track>> searchTracks({
    required String query,
    required int limit,
    required int offset,
  }) {
    final uri = Uri.parse('$_baseUrl/tracks/').replace(queryParameters: {
      'client_id': _clientId,
      'format': 'json',
      'namesearch': query,
      'limit': '$limit',
      'offset': '$offset',
    });
    return _fetch(uri);
  }

  Future<List<Track>> _fetch(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw JamendoApiException(
          'Could not reach Jamendo. Check your connection.');
    }

    if (response.statusCode != 200) {
      throw JamendoApiException(
          'Jamendo returned an error (${response.statusCode}).');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final headers = body['headers'] as Map<String, dynamic>?;
    if (headers?['status'] != 'success') {
      throw JamendoApiException(
          headers?['error_message'] as String? ?? 'Jamendo request failed.');
    }

    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
