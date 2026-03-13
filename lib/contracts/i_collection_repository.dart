import '../models/collection.dart';

abstract class ICollectionRepository {
  Future<List<Collection>> getCollections(String userId);
  Future<Collection> createCollection(Collection collection);
  Future<void> updateCollection(Collection collection);
  Future<void> deleteCollection(String collectionId);
  /// Pin a collection — DB trigger automatically unpins others.
  Future<void> pinCollection(String collectionId);
  Future<void> unpinCollection(String collectionId);
  /// Assign (or unassign with null) a card to a collection.
  Future<void> assignCardToCollection(String cardId, String? collectionId);
  /// Bulk assign multiple cards to a collection.
  Future<void> assignCardsToCollection(List<String> cardIds, String collectionId);
}
