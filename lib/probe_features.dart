import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final client = Supabase.instance.client;

  // List of potential table names to check
  final tables = [
    'journals',
    'notebooks',
    'entries',
    'journal_entries',
    'vision_boards',
    'vision_items',
    'media',
    'images',
    'uploads',
  ];

  for (final table in tables) {
    debugPrint('--- Probing $table ---');
    try {
      final res = await client.from(table).select().limit(1);
      debugPrint('FOUND $table: $res');
    } catch (e) {
      // debugPrint('Error probing $table: $e');
      debugPrint('NOT FOUND $table');
    }
  }
}
