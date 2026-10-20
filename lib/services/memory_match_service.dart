import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryMatchService {
  static const String _campaignUnlockedKey = 'campaign_unlocked';
  static const String _progressSection = 'memory_match_progress';
  static const String _scoresSection = 'memory_match_high_scores';

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<int> loadCampaignUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final localLevel = prefs.getInt(_campaignUnlockedKey) ?? 1;
    final remoteLevel = await _loadRemoteCampaignUnlockedLevel();
    final resolvedLevel = remoteLevel == null
        ? localLevel
        : (remoteLevel > localLevel ? remoteLevel : localLevel);

    if (resolvedLevel != localLevel) {
      await prefs.setInt(_campaignUnlockedKey, resolvedLevel);
    }
    if (remoteLevel == null || resolvedLevel > remoteLevel) {
      await saveCampaignUnlockedLevel(resolvedLevel);
    }

    return resolvedLevel;
  }

  static Future<void> saveCampaignUnlockedLevel(int unlockedLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final localLevel = prefs.getInt(_campaignUnlockedKey) ?? 1;
    final resolvedLevel = unlockedLevel > localLevel
        ? unlockedLevel
        : localLevel;
    await prefs.setInt(_campaignUnlockedKey, resolvedLevel);

    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final existing = await _client
          .from('items')
          .select('id, value')
          .eq('user_id', user.id)
          .eq('section', _progressSection)
          .eq('category', 'campaign')
          .limit(1);

      final remoteValue = existing.isNotEmpty
          ? existing.first['value'] as int?
          : null;
      final valueToSave = remoteValue != null && remoteValue > resolvedLevel
          ? remoteValue
          : resolvedLevel;

      if (existing.isNotEmpty) {
        await _client
            .from('items')
            .update({
              'text': 'campaign_unlocked',
              'value': valueToSave,
              'archived': false,
            })
            .eq('id', existing.first['id'])
            .eq('user_id', user.id);
      } else {
        await _client.from('items').insert({
          'user_id': user.id,
          'section': _progressSection,
          'category': 'campaign',
          'text': 'campaign_unlocked',
          'value': valueToSave,
          'completed': false,
          'archived': false,
        });
      }
    } catch (e) {
      debugPrint('[MemoryMatchService] Error saving progress: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadHighScores(
    String mode,
    String difficulty,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _highScoreKey(mode, difficulty);
    final localScores = _decodeScores(prefs.getStringList(key) ?? []);
    final remoteScores = await _loadRemoteHighScores(mode, difficulty);
    final mergedScores = _mergeScores([...localScores, ...remoteScores]);

    await prefs.setStringList(
      key,
      mergedScores.map((score) => jsonEncode(score)).toList(),
    );
    if (jsonEncode(mergedScores) != jsonEncode(remoteScores)) {
      await _saveRemoteHighScores(mode, difficulty, mergedScores);
    }

    return mergedScores;
  }

  static Future<void> saveHighScore({
    required String mode,
    required String difficulty,
    required int moves,
    required int time,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _highScoreKey(mode, difficulty);
    final existingScores = await loadHighScores(mode, difficulty);
    final updatedScores = _mergeScores([
      ...existingScores,
      {'moves': moves, 'time': time, 'date': date.toIso8601String()},
    ]);

    await prefs.setStringList(
      key,
      updatedScores.map((score) => jsonEncode(score)).toList(),
    );
    await _saveRemoteHighScores(mode, difficulty, updatedScores);
  }

  static Future<int?> _loadRemoteCampaignUnlockedLevel() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('items')
          .select('value')
          .eq('user_id', user.id)
          .eq('section', _progressSection)
          .eq('category', 'campaign')
          .limit(1);

      if (response.isEmpty) return null;
      return response.first['value'] as int?;
    } catch (e) {
      debugPrint('[MemoryMatchService] Error loading progress: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _loadRemoteHighScores(
    String mode,
    String difficulty,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('items')
          .select('why')
          .eq('user_id', user.id)
          .eq('section', _scoresSection)
          .eq('category', _scoreCategory(mode, difficulty))
          .limit(1);

      if (response.isEmpty) return [];
      final encoded = response.first['why'] as String?;
      if (encoded == null || encoded.trim().isEmpty) return [];

      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((score) => Map<String, dynamic>.from(score))
          .toList();
    } catch (e) {
      debugPrint('[MemoryMatchService] Error loading high scores: $e');
      return [];
    }
  }

  static Future<void> _saveRemoteHighScores(
    String mode,
    String difficulty,
    List<Map<String, dynamic>> scores,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final category = _scoreCategory(mode, difficulty);
      final payload = jsonEncode(scores);
      final existing = await _client
          .from('items')
          .select('id')
          .eq('user_id', user.id)
          .eq('section', _scoresSection)
          .eq('category', category)
          .limit(1);

      if (existing.isNotEmpty) {
        await _client
            .from('items')
            .update({
              'text': 'high_scores_$category',
              'why': payload,
              'archived': false,
            })
            .eq('id', existing.first['id'])
            .eq('user_id', user.id);
      } else {
        await _client.from('items').insert({
          'user_id': user.id,
          'section': _scoresSection,
          'category': category,
          'text': 'high_scores_$category',
          'why': payload,
          'completed': false,
          'archived': false,
        });
      }
    } catch (e) {
      debugPrint('[MemoryMatchService] Error saving high scores: $e');
    }
  }

  static String _highScoreKey(String mode, String difficulty) {
    return 'highscores_${mode}_$difficulty';
  }

  static String _scoreCategory(String mode, String difficulty) {
    return '${mode}_$difficulty';
  }

  static List<Map<String, dynamic>> _decodeScores(List<String> encodedScores) {
    return encodedScores
        .map((score) {
          try {
            return jsonDecode(score) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static List<Map<String, dynamic>> _mergeScores(
    List<Map<String, dynamic>> scores,
  ) {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    for (final score in scores) {
      final time = score['time'];
      final moves = score['moves'];
      final date = score['date'];
      if (time is! int || moves is! int || date is! String) continue;

      final signature = '$time|$moves|$date';
      if (seen.add(signature)) {
        merged.add({'time': time, 'moves': moves, 'date': date});
      }
    }

    merged.sort((a, b) {
      final timeCompare = (a['time'] as int).compareTo(b['time'] as int);
      if (timeCompare != 0) return timeCompare;
      return (a['moves'] as int).compareTo(b['moves'] as int);
    });
    return merged.take(10).toList();
  }
}
