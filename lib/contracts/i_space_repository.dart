import '../models/space.dart';

abstract class ISpaceRepository {
  Future<List<Space>> getSpaces(String userId);
  Future<Space> createSpace(Space space);
  Future<void> deleteSpace(String spaceId);
  Future<void> setActiveSpace(String userId, String spaceId);
  Future<String?> getActiveSpaceId(String userId);
  /// Bulk-update cards with NULL space_id to the given space (first-launch migration).
  Future<void> migrateCardsToSpace(String userId, String spaceId);
}
