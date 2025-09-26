import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Level Operations
  Future<List<Map<String, dynamic>>> getLevels() async {
    final response = await _supabase
        .from('levels')
        .select()
        .order('starting_points');

    return List<Map<String, dynamic>>.from(response);
  }

  // Admin Level Management
  Future<String> createLevel(Map<String, dynamic> levelData) async {
    try {
      final response =
          await _supabase.from('levels').insert(levelData).select().single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create level: $e');
    }
  }

  Future<Map<String, dynamic>?> getLevelById(String levelId) async {
    try {
      final response =
          await _supabase.from('levels').select().eq('id', levelId).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateLevel({
    required String levelId,
    required Map<String, dynamic> levelData,
  }) async {
    try {
      await _supabase.from('levels').update(levelData).eq('id', levelId);
    } catch (e) {
      throw Exception('Failed to update level: $e');
    }
  }

  Future<void> deleteLevel(String levelId) async {
    try {
      await _supabase.from('levels').delete().eq('id', levelId);
    } catch (e) {
      throw Exception('Failed to delete level: $e');
    }
  }
}
