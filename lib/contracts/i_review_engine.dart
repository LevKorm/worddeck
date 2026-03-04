import '../models/sm2_data.dart';
import '../models/review_rating.dart';

abstract class IReviewEngine {
  SM2Data calculateNext(SM2Data current, ReviewRating rating);
  SM2Data createInitial();
}
