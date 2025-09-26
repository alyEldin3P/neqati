import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neqati/core/models/scan.dart';

class ScanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Scan History Operations
  Future<List<Map<String, dynamic>>> getUserScanHistory(String userId) async {
    final response = await _supabase
        .from('scans')
        .select()
        .eq('user_id', userId)
        .order('scan_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRecentScans(int days) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final response = await _supabase
          .from('scans')
          .select()
          .gte('scan_date', cutoffDate);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get recent scans: $e');
    }
  }

  // Admin Scan Management
  Future<List<Map<String, dynamic>>> getScansPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('scans')
          .select('*, users(name, phone_number)')
          .range(offset, offset + limit - 1)
          .order('scan_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get scans: $e');
    }
  }

  // Typed methods using Scan model
  Future<List<Scan>> getScansTyped({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('scans')
          .select('*, users(name, phone_number)')
          .range(offset, offset + limit - 1)
          .order('scan_date', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((data) => Scan.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get scans: $e');
    }
  }

  Future<List<Scan>> getUserScanHistoryTyped(String userId) async {
    try {
      final response = await _supabase
          .from('scans')
          .select('*, users(name, phone_number)')
          .eq('user_id', userId)
          .order('scan_date', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((data) => Scan.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user scan history: $e');
    }
  }

  Future<List<Scan>> getRecentScansTyped(int days) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final response = await _supabase
          .from('scans')
          .select('*, users(name, phone_number)')
          .gte('scan_date', cutoffDate)
          .order('scan_date', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((data) => Scan.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent scans: $e');
    }
  }

  Future<Scan?> getScanById(String scanId) async {
    try {
      final response = await _supabase
          .from('scans')
          .select('*, users(name, phone_number)')
          .eq('id', scanId)
          .single();

      return Scan.fromSupabase(response);
    } catch (e) {
      log('Failed to get scan by ID: $e');
      return null;
    }
  }
}
