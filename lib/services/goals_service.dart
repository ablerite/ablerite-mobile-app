import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal.dart';
import 'package:uuid/uuid.dart';

class GoalsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all active goals for the current user
  Future<List<Goal>> getActiveGoals() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'activeGoals')
          .neq('status', 'deleted')
          .neq('status', 'trashed')
          .or('archived.is.null,archived.eq.false')
          .order('order_index', ascending: true);

      final goals = response.map<Goal>((json) => Goal.fromJson(json)).toList();
      return goals;
    } catch (e) {
      debugPrint('Error fetching active goals: $e');
      return [];
    }
  }

  /// Get all long-term goals for the current user
  Future<List<Goal>> getLongTermGoals() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'longTermGoals')
          .neq('status', 'deleted')
          .neq('status', 'trashed')
          .or('archived.is.null,archived.eq.false')
          .order('order_index', ascending: true);

      final goals = response.map<Goal>((json) => Goal.fromJson(json)).toList();
      return goals;
    } catch (e) {
      debugPrint('Error fetching long-term goals: $e');
      return [];
    }
  }

  /// Get completed active goals
  Future<List<Goal>> getCompletedGoals() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'activeGoals')
          .eq('completed', true)
          .neq('status', 'deleted')
          .neq('status', 'trashed')
          .order('created_at', ascending: false);

      final goals = response.map<Goal>((json) => Goal.fromJson(json)).toList();
      return goals;
    } catch (e) {
      debugPrint('Error fetching completed goals: $e');
      return [];
    }
  }

  /// Add a new goal
  Future<Goal?> addGoal(Goal goal) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final goalData = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'text': goal.text,
        'section': goal.section,
        'category': goal.category,
        'parent_id': goal.parentId,
        'completed': goal.completed,
        'order_index':
            goal.orderIndex ?? await _nextOrderIndex(userId, goal.section),
        'due_date': goal.dueDate,
        'start_date': goal.startDate,
        'created_at': DateTime.now().toIso8601String(),
        'value': goal.value,
        'goal_type': goal.goalType,
        'why': goal.why,
        'is_primary': goal.isPrimary,
        'cost_estimate': goal.costEstimate,
        'cost_type': goal.costType,
        'related_ids': goal.relatedIds,
        'related_vision_board_ids': goal.relatedVisionBoardIds,
        'specific': goal.specific,
        'measurable': goal.measurable,
        'achievable': goal.achievable,
        'relevant': goal.relevant,
      };
      _applyGoalTypeValueFallback(goalData);

      // If this is being set as primary, unset all other primary goals
      if (goal.isPrimary && goal.section == 'activeGoals') {
        await _client
            .from('items')
            .update({'is_primary': false})
            .eq('section', 'activeGoals')
            .eq('user_id', userId);
      }

      List<dynamic> response;
      try {
        response = await _client.from('items').insert(goalData).select();
      } catch (e) {
        if (goal.goalType != 'asset' && goal.goalType != 'liability') {
          rethrow;
        }
        final fallbackGoalData = Map<String, dynamic>.from(goalData);
        _applyGoalTypeValueFallback(fallbackGoalData, forceFallback: true);
        response = await _client
            .from('items')
            .insert(fallbackGoalData)
            .select();
      }

      if (response.isNotEmpty) {
        return Goal.fromJson(response.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding goal: $e');
      return null;
    }
  }

  /// Update an existing goal
  Future<bool> updateGoal(Goal goal) async {
    final updates = Map<String, dynamic>.from(goal.toJson())
      ..remove('id')
      ..remove('user_id');
    return updateGoalFields(goal.id, updates);
  }

  Future<bool> updateGoalFields(
    String goalId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      if (updates['is_primary'] == true &&
          updates['section'] == 'activeGoals') {
        await _client
            .from('items')
            .update({'is_primary': false})
            .eq('section', 'activeGoals')
            .eq('user_id', userId)
            .neq('id', goalId);
      }

      final safeUpdates = Map<String, dynamic>.from(updates);
      _applyGoalTypeValueFallback(safeUpdates);
      await _updateGoalRow(goalId, userId, safeUpdates);

      return true;
    } catch (e) {
      final goalType = updates['goal_type'];
      if (goalType == 'asset' || goalType == 'liability') {
        try {
          final fallbackUpdates = Map<String, dynamic>.from(updates);
          _applyGoalTypeValueFallback(fallbackUpdates, forceFallback: true);
          await _updateGoalRow(goalId, userId, fallbackUpdates);
          return true;
        } catch (fallbackError) {
          debugPrint(
            'Error updating goal fields with fallback: $fallbackError',
          );
        }
      }
      debugPrint('Error updating goal fields: $e');
      return false;
    }
  }

  Future<void> _updateGoalRow(
    String goalId,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _client
        .from('items')
        .update(updates)
        .eq('id', goalId)
        .eq('user_id', userId);
  }

  void _applyGoalTypeValueFallback(
    Map<String, dynamic> updates, {
    bool forceFallback = false,
  }) {
    final goalType = updates['goal_type'];
    if (forceFallback && goalType == 'asset') {
      updates['goal_type'] = 'desire';
      updates['value'] = goalTypeAssetValueFallback;
    } else if (forceFallback && goalType == 'liability') {
      updates['goal_type'] = 'need';
      updates['value'] = goalTypeLiabilityValueFallback;
    } else if (goalType == 'need' || goalType == 'desire') {
      updates['value'] = null;
    }
  }

  Future<int> _nextOrderIndex(String userId, String section) async {
    final response = await _client
        .from('items')
        .select('order_index')
        .eq('user_id', userId)
        .eq('section', section);

    var maxOrder = -1;
    for (final row in response) {
      final orderIndex = row['order_index'];
      if (orderIndex is int && orderIndex > maxOrder) {
        maxOrder = orderIndex;
      }
    }

    return maxOrder + 1;
  }

  Future<bool> updateGoalOrder(List<Goal> goals) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      for (var index = 0; index < goals.length; index++) {
        await _client
            .from('items')
            .update({'order_index': index})
            .eq('id', goals[index].id)
            .eq('user_id', userId);
      }

      return true;
    } catch (e) {
      debugPrint('Error updating goal order: $e');
      return false;
    }
  }

  /// Delete a goal
  Future<bool> deleteGoal(String id) async {
    try {
      await _client.from('items').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      return false;
    }
  }

  /// Toggle goal completion status
  Future<bool> toggleGoalStatus(String id, bool completed) async {
    try {
      await _client.from('items').update({'completed': completed}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error toggling goal status: $e');
      return false;
    }
  }

  /// Move a long-term goal to active goals
  Future<bool> makeGoalActive(String id) async {
    try {
      await _client
          .from('items')
          .update({'section': 'activeGoals'})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error making goal active: $e');
      return false;
    }
  }

  /// Move an active goal to long-term goals
  Future<bool> makeGoalLongTerm(String id) async {
    try {
      await _client
          .from('items')
          .update({'section': 'longTermGoals', 'is_primary': false})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error making goal long-term: $e');
      return false;
    }
  }

  /// Archive a goal
  Future<bool> archiveGoal(String id) async {
    try {
      await _client
          .from('items')
          .update({'archived': true, 'is_primary': false})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error archiving goal: $e');
      return false;
    }
  }

  /// Get archived goals
  Future<List<Goal>> getArchivedGoals() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('archived', true)
          .neq('status', 'deleted')
          .neq('status', 'trashed')
          .inFilter('section', ['activeGoals', 'longTermGoals'])
          .order('created_at', ascending: false);

      final goals = response.map<Goal>((json) => Goal.fromJson(json)).toList();
      return goals;
    } catch (e) {
      debugPrint('Error fetching archived goals: $e');
      return [];
    }
  }

  /// Get sub-goals for a parent goal
  Future<List<Goal>> getSubGoals(String parentId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('parent_id', parentId)
          .neq('status', 'deleted')
          .neq('status', 'trashed')
          .inFilter('section', ['activeGoals', 'longTermGoals'])
          .order('created_at', ascending: false);

      return response.map<Goal>((json) => Goal.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching sub-goals: $e');
      return [];
    }
  }
}
