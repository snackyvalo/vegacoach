import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NeatQueueService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final apiKey = dotenv.env['NEATQUEUE_API_KEY'];
    if (apiKey == null) throw Exception('Missing NEATQUEUE_API_KEY in .env');
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }

  static String? get _serverId => dotenv.env['NEATQUEUE_SERVER_ID'];

  static Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    final serverId = _serverId;
    final channelId = dotenv.env['NEATQUEUE_CHANNEL_ID'];

    if (serverId == null || channelId == null) {
      throw Exception('Missing NeatQueue API configuration in .env');
    }

    final url = Uri.parse('https://api.neatqueue.com/api/v2/leaderboard/$serverId/$channelId');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('months')) {
          final months = data['months'] as List;
          if (months.isNotEmpty) {
            final latestMonthData = months[0]['data'] as List;
            return latestMonthData.cast<Map<String, dynamic>>();
          }
        }
        return [];
      } else {
        throw Exception('Failed to load leaderboard. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching leaderboard: $e');
    }
  }
  static Stream<List<Map<String, dynamic>>> leaderboardStream({Duration interval = const Duration(seconds: 30)}) async* {
    try {
      yield await fetchLeaderboard();
    } catch (e) {
      // Yield empty list on initial failure so the UI can show an error or empty state
      yield [];
    }

    await for (var _ in Stream.periodic(interval)) {
      try {
        yield await fetchLeaderboard();
      } catch (e) {
        // Ignore periodic errors to prevent the UI from flickering, it will try again next tick
      }
    }
  }
  static Future<List<Map<String, dynamic>>> fetchQueues() async {
    final serverId = _serverId;
    if (serverId == null) throw Exception('Missing server ID');
    
    final url = Uri.parse('https://api.neatqueue.com/api/v1/queuechannels/$serverId');
    final response = await http.get(url, headers: await _getAuthHeaders());
    if (response.statusCode == 200) {
      final dynamic json = jsonDecode(response.body);
      if (json is List) {
        return json.map((q) {
          if (q is List && q.length >= 2) {
            return {'id': q[0], 'name': q[1]};
          } else if (q is Map) {
            return Map<String, dynamic>.from(q);
          }
          return <String, dynamic>{'name': 'Unknown'};
        }).toList();
      }
      return [];
    }
    throw Exception('Failed to fetch queues');
  }

  static Future<List<dynamic>> fetchMatches() async {
    final serverId = _serverId;
    if (serverId == null) throw Exception('Missing server ID');
    
    final url = Uri.parse('https://api.neatqueue.com/api/v1/matches/$serverId');
    final response = await http.get(url, headers: await _getAuthHeaders());
    if (response.statusCode == 200) {
      final dynamic json = jsonDecode(response.body);
      if (json is List) {
        return json;
      } else if (json is Map) {
        // sometimes it returns {"matchId": {...}}
        return json.values.toList();
      }
      return [];
    }
    throw Exception('Failed to fetch matches');
  }

  static Future<List<dynamic>> fetchHistory() async {
    final serverId = _serverId;
    if (serverId == null) throw Exception('Missing server ID');
    
    final url = Uri.parse('https://api.neatqueue.com/api/v1/history/$serverId');
    final response = await http.get(url, headers: await _getAuthHeaders());
    if (response.statusCode == 200) {
      final dynamic json = jsonDecode(response.body);
      if (json is Map && json.containsKey('data')) {
        final data = json['data'];
        if (data is List) return data;
      } else if (json is List) {
        return json;
      }
      return [];
    }
    throw Exception('Failed to fetch history');
  }

  static Future<Map<String, dynamic>> fetchServerAnalytics() async {
    final serverId = _serverId;
    if (serverId == null) throw Exception('Missing server ID');
    
    final url = Uri.parse('https://api.neatqueue.com/api/v2/server/$serverId/analytics');
    final response = await http.get(url, headers: await _getAuthHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch analytics');
  }
}
