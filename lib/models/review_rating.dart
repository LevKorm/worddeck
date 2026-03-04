/// Review quality ratings fed into the SM-2 algorithm.
/// Integer values match the original SM-2 spec (0, 3, 4, 5).
enum ReviewRating {
  again(0, 'Again'),  // complete blackout — reset
  hard(3, 'Hard'),    // correct but significant difficulty
  good(4, 'Good'),    // correct with some hesitation
  easy(5, 'Easy');    // perfect recall

  final int quality;  // SM-2 quality value
  final String label;
  const ReviewRating(this.quality, this.label);
}
