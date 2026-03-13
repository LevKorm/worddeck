import 'package:supabase_flutter/supabase_flutter.dart';

import '../../contracts/i_space_repository.dart';
import '../../core/errors/app_exception.dart';
import '../../models/space.dart';

class SupabaseSpaceRepository implements ISpaceRepository {
  final SupabaseClient _supabase;
  static const _table = 'spaces';

  const SupabaseSpaceRepository(this._supabase);

  @override
  Future<List<Space>> getSpaces(String userId) async {
    try {
      final data = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('display_order');
      return (data as List)
          .map((e) => Space.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch spaces', cause: e);
    }
  }

  @override
  Future<Space> createSpace(Space space) async {
    try {
      final data = await _supabase
          .from(_table)
          .insert(space.toInsertJson())
          .select()
          .single();
      return Space.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to create space', cause: e);
    }
  }

  @override
  Future<void> deleteSpace(String spaceId) async {
    try {
      await _supabase.from(_table).delete().eq('id', spaceId);
    } catch (e) {
      throw DatabaseException('Failed to delete space', cause: e);
    }
  }

  @override
  Future<void> setActiveSpace(String userId, String spaceId) async {
    try {
      await _supabase
          .from('user_settings')
          .upsert({'user_id': userId, 'active_space_id': spaceId});
    } catch (e) {
      throw DatabaseException('Failed to set active space', cause: e);
    }
  }

  @override
  Future<String?> getActiveSpaceId(String userId) async {
    try {
      final data = await _supabase
          .from('user_settings')
          .select('active_space_id')
          .eq('user_id', userId)
          .maybeSingle();
      return data?['active_space_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> migrateCardsToSpace(String userId, String spaceId) async {
    try {
      await _supabase
          .from('cards')
          .update({'space_id': spaceId})
          .eq('user_id', userId)
          .filter('space_id', 'is', null);
    } catch (_) {
      // Migration failure is non-fatal — cards will still load
    }
  }
}
