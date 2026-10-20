import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinancialService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCashPlannerItems() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    return await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .eq('section', 'cashPlanner')
        .order('created_at', ascending: false);
  }

  Future<Map<String, double>> getFinancialMetrics() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _defaultMetrics();

      // Query all financial items from the items table (including cashPlanner)
      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .inFilter('section', [
            'assets',
            'liabilities',
            'income',
            'expenses',
            'cashPlanner',
          ]);

      // Calculate totals
      double totalAssets = 0.0;
      double totalLiabilities = 0.0;
      double monthlyIncome = 0.0;
      double monthlyExpenses = 0.0;
      double activeSpend = 0.0;

      for (var item in response) {
        final section = item['section'] as String?;
        final value = (item['value'] as num?)?.toDouble() ?? 0.0;
        final frequency = item['frequency'] as String?;

        switch (section) {
          case 'assets':
            totalAssets += value;
            break;
          case 'liabilities':
            totalLiabilities += value;
            break;
          case 'income':
            // Only count monthly income, or annual divided by 12
            if (frequency == 'monthly') {
              monthlyIncome += value;
            } else if (frequency == 'annual') {
              monthlyIncome += value / 12;
            } else {
              // If no frequency specified, assume monthly
              monthlyIncome += value;
            }
            break;
          case 'expenses':
            // Same logic for expenses
            if (frequency == 'monthly') {
              monthlyExpenses += value;
            } else if (frequency == 'annual') {
              monthlyExpenses += value / 12;
            } else {
              monthlyExpenses += value;
            }
            break;
          case 'cashPlanner':
            // Sum completed cash planner items as active spend
            if (item['is_completed'] == true) {
              activeSpend += value;
            }
            break;
        }
      }

      final surplus = monthlyIncome - monthlyExpenses;
      final cashSurplus = surplus - activeSpend;

      return {
        'net_worth': totalAssets - totalLiabilities,
        'income': monthlyIncome,
        'budget': monthlyExpenses,
        'cash_surplus': cashSurplus,
      };
    } catch (e) {
      debugPrint('Error fetching financial metrics: $e');
      return _defaultMetrics();
    }
  }

  Map<String, double> _defaultMetrics() {
    return {
      'net_worth': 0.0,
      'income': 0.0,
      'budget': 0.0,
      'cash_surplus': 0.0,
    };
  }
}
