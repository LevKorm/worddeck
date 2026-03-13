import 'package:supabase_flutter/supabase_flutter.dart';

import '../../contracts/i_collection_repository.dart';
import '../../core/errors/app_exception.dart';
import '../../models/collection.dart';

class SupabaseCollectionRepository implements ICollectionRepository {
  final SupabaseClient _supabase;
  static const _table = 'collections';
  static const _cardsTable = 'cards';

  const SupabaseCollectionRepository(this._supabase);

  @override
  Future<List<Collection>> getCollections(String userId) async {
    try {
      final data = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('position')
          .order('created_at');
      return (data as List)
          .map((e) => Collection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch collections', cause: e);
    }
  }

  @override
  Future<Collection> createCollection(Collection collection) async {
    try {
      final data = await _supabase
          .from(_table)
          .insert(collection.toInsertJson())
          .select()
          .single();
      return Collection.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to create collection', cause: e);
    }
  }

  @override
  Future<void> updateCollection(Collection collection) async {
    try {
      await _supabase
          .from(_table)
          .update({
            'name': collection.name,
            'emoji': collection.emoji,
            'color': collection.color,
            'description': collection.description,
            'position': collection.position,
          })
          .eq('id', collection.id);
    } catch (e) {
      throw DatabaseException('Failed to update collection', cause: e);
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    try {
      await _supabase.from(_table).delete().eq('id', collectionId);
    } catch (e) {
      throw DatabaseException('Failed to delete collection', cause: e);
    }
  }

  @override
  Future<void> pinCollection(String collectionId) async {
    try {
      // DB trigger handles unpinning others.
      await _supabase
          .from(_table)
          .update({'is_pinned': true})
          .eq('id', collectionId);
    } catch (e) {
      throw DatabaseException('Failed to pin collection', cause: e);
    }
  }

  @override
  Future<void> unpinCollection(String collectionId) async {
    try {
      await _supabase
          .from(_table)
          .update({'is_pinned': false})
          .eq('id', collectionId);
    } catch (e) {
      throw DatabaseException('Failed to unpin collection', cause: e);
    }
  }

  @override
  Future<void> assignCardToCollection(
      String cardId, String? collectionId) async {
    try {
      await _supabase
          .from(_cardsTable)
          .update({'collection_id': collectionId})
          .eq('id', cardId);
    } catch (e) {
      throw DatabaseException('Failed to assign card to collection', cause: e);
    }
  }

  @override
  Future<void> assignCardsToCollection(
      List<String> cardIds, String collectionId) async {
    if (cardIds.isEmpty) return;
    try {
      await _supabase
          .from(_cardsTable)
          .update({'collection_id': collectionId})
          .inFilter('id', cardIds);
    } catch (e) {
      throw DatabaseException('Failed to bulk assign cards', cause: e);
    }
  }
}
