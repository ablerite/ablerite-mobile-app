import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  static const String defaultCurrency = 'USD';

  static final Map<String, String> currencySymbols = {
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
  };

  static final Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'GBP': 'British Pound',
    'EUR': 'Euro',
  };

  /// Get the saved currency code from local cache (SharedPreferences)
  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? defaultCurrency;
  }

  /// Save the selected currency code to local cache only
  static Future<void> setCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
  }

  /// Get the currency symbol for a given code
  static String getSymbol(String currencyCode) {
    return currencySymbols[currencyCode] ?? '\$';
  }

  /// Fetch currency preference from Supabase (syncs with desktop).
  /// Falls back to local SharedPreferences if not logged in or on error.
  /// Returns the resolved currency code.
  static Future<String> fetchFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return await getCurrency();
      }

      final response = await Supabase.instance.client
          .from('items')
          .select('*')
          .eq('user_id', user.id)
          .eq('section', 'user_settings');

      if (response.isNotEmpty) {
        final prefs = response[0];
        final category = prefs['category'] as String?;
        if (category != null && currencySymbols.containsKey(category)) {
          // Update local cache with the synced value
          await setCurrency(category);
          return category;
        }
      }
    } catch (e) {
      // Silently fall back to local cache on error
      debugPrint('[CurrencyService] Error fetching from Supabase: $e');
    }

    return await getCurrency();
  }

  /// Save currency preference to both Supabase and local SharedPreferences.
  /// Matches the desktop data model: items table with section='user_settings',
  /// category=currencyCode. Preserves the existing 'text' field (theme).
  static Future<void> saveToSupabase(String currencyCode) async {
    // Always save locally first
    await setCurrency(currencyCode);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Check if a user_settings row already exists
      final existing = await Supabase.instance.client
          .from('items')
          .select('id, text')
          .eq('user_id', user.id)
          .eq('section', 'user_settings')
          .limit(1);

      if (existing.isNotEmpty) {
        // Update existing row — only change category, preserve text (theme)
        await Supabase.instance.client
            .from('items')
            .update({'category': currencyCode})
            .eq('id', existing[0]['id']);
      } else {
        // Insert new user_settings row
        await Supabase.instance.client.from('items').insert({
          'section': 'user_settings',
          'text': 'dark', // default theme
          'category': currencyCode,
          'user_id': user.id,
          'completed': null,
          'value': null,
          'archived': false,
        });
      }
    } catch (e) {
      debugPrint('[CurrencyService] Error saving to Supabase: $e');
    }
  }
}
