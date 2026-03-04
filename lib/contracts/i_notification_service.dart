abstract class INotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> scheduleReviewReminder(DateTime when, int cardsDue);
  Future<void> cancelAll();
}
