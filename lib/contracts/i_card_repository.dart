import '../models/flash_card.dart';

abstract class ICardRepository {
  Future<FlashCard> saveCard(FlashCard card);
  Future<List<FlashCard>> getAllCards(String userId);
  Future<List<FlashCard>> getDueCards(String userId, DateTime now);
  Future<FlashCard> updateCard(FlashCard card);
  Future<void> deleteCard(String cardId);
  Future<List<FlashCard>> searchCards(String userId, String query);
  Future<int> getCardCount(String userId);
  Future<void> clearAllCards(String userId);
}
