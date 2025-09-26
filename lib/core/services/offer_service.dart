import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfferService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Offer Operations
  Future<List<Map<String, dynamic>>> getOffers() async {
    log('🔍 OfferService.getOffers() - Getting ALL offers for admin');
    final response = await _supabase
        .from('offers')
        .select()
        .order('created_at', ascending: false);

    log('📊 Admin getOffers() Results: Found ${response.length} total offers');
    for (var offer in response) {
      log('   📄 Admin Offer: ${offer['title']} (ID: ${offer['id']}) - is_active: ${offer['is_active']}, end_date: ${offer['end_date']}');
    }

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<dynamic>> getActiveOffers() async {
    try {
      final now = DateTime.now().toIso8601String();
      log('🔍 OfferService.getActiveOffers() - Starting with current time: $now');
      
      // First try to get offers with is_active = true and valid end_date
      log('📊 Step 1: Querying offers with is_active=true AND end_date >= $now');
      final activeResponse = await _supabase
          .from('offers')
          .select()
          .eq('is_active', true)
          .gte('end_date', now)
          .order('end_date');
      
      log('📊 Step 1 Results: Found ${activeResponse.length} offers with active status and valid end date');
      if (activeResponse.isNotEmpty) {
        for (var offer in activeResponse) {
          log('   ✅ Active Offer: ${offer['title']} (ID: ${offer['id']}) - is_active: ${offer['is_active']}, end_date: ${offer['end_date']}');
        }
        log('🎯 Returning ${activeResponse.length} active offers from Step 1');
        return activeResponse;
      }
      
      // If no results, try just is_active = true (ignore date)
      log('📊 Step 2: No results from Step 1, querying offers with is_active=true only (ignoring date)');
      final activeOnlyResponse = await _supabase
          .from('offers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      log('📊 Step 2 Results: Found ${activeOnlyResponse.length} offers with active status (ignoring date)');
      if (activeOnlyResponse.isNotEmpty) {
        for (var offer in activeOnlyResponse) {
          log('   ✅ Active Offer (no date check): ${offer['title']} (ID: ${offer['id']}) - is_active: ${offer['is_active']}, end_date: ${offer['end_date']}');
        }
        log('🎯 Returning ${activeOnlyResponse.length} active offers from Step 2');
        return activeOnlyResponse;
      }
      
      // PROBLEM: This fallback returns ALL offers regardless of active status!
      log('⚠️ Step 3: No active offers found! This should return empty array, not all offers!');
      log('🚫 ISSUE IDENTIFIED: Fallback is returning ALL offers regardless of is_active status');
      
      // Instead of returning all offers, return empty array
      log('🔧 FIX: Returning empty array instead of all offers');
      return [];
      
      // OLD PROBLEMATIC CODE (commented out):
      // final allOffersResponse = await _supabase
      //     .from('offers')
      //     .select()
      //     .order('created_at', ascending: false);
      // 
      // log('📊 Step 3 Results: Returning ALL ${allOffersResponse.length} offers as fallback (THIS IS THE PROBLEM!)');
      // for (var offer in allOffersResponse) {
      //   log('   ❌ Fallback Offer: ${offer['title']} (ID: ${offer['id']}) - is_active: ${offer['is_active']}');
      // }
      // return allOffersResponse;
      
    } catch (e) {
      log('❌ Error getting active offers: $e');
      return [];
    }
  }

  // Admin Offer Management
  Future<String> createOffer({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final now = DateTime.now();
      final offerData = {
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'is_active': true, // Default to active
        'start_date': now.toIso8601String(), // Start now
        'end_date': now.add(Duration(days: 30)).toIso8601String(), // End in 30 days
        'created_at': now.toIso8601String(),
      };

      final response =
          await _supabase.from('offers').insert(offerData).select().single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create offer: $e');
    }
  }

  Future<void> updateOffer({
    required String offerId,
    required Map<String, dynamic> offerData,
  }) async {
    try {
      await _supabase.from('offers').update(offerData).eq('id', offerId);
    } catch (e) {
      throw Exception('Failed to update offer: $e');
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      await _supabase.from('offers').delete().eq('id', offerId);
    } catch (e) {
      throw Exception('Failed to delete offer: $e');
    }
  }

  Future<Map<String, dynamic>?> getOfferById(String offerId) async {
    try {
      final response =
          await _supabase.from('offers').select().eq('id', offerId).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Activate/Deactivate Offer
  Future<void> activateOffer(String offerId) async {
    try {
      await _supabase
          .from('offers')
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', offerId);
    } catch (e) {
      throw Exception('Failed to activate offer: $e');
    }
  }

  Future<void> deactivateOffer(String offerId) async {
    try {
      await _supabase
          .from('offers')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', offerId);
    } catch (e) {
      throw Exception('Failed to deactivate offer: $e');
    }
  }

  Future<void> toggleOfferStatus(String offerId, bool isActive) async {
    try {
      await _supabase
          .from('offers')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', offerId);
    } catch (e) {
      throw Exception('Failed to toggle offer status: $e');
    }
  }
}
