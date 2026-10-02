/// A member's rating of one session: 1 to 5 stars, an optional comment, and the trainer's answer.
class Review {
  final int id;
  final int bookingId;
  final int trainerId;
  final String trainerName;
  final String memberName; // "Malik Q." on profiles; the full name for the admin
  final int rating;
  final String? comment;
  final DateTime sessionDate;
  final DateTime createdAt;
  final String? reply;
  final bool hidden; // admin only
  final String? hiddenReason; // admin only

  const Review({
    required this.id,
    required this.bookingId,
    required this.trainerId,
    required this.trainerName,
    required this.memberName,
    required this.rating,
    required this.comment,
    required this.sessionDate,
    required this.createdAt,
    required this.reply,
    this.hidden = false,
    this.hiddenReason,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as num).toInt(),
      bookingId: (json['bookingId'] as num).toInt(),
      trainerId: (json['trainerId'] as num).toInt(),
      trainerName: json['trainerName'] as String,
      memberName: json['memberName'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      sessionDate: DateTime.parse(json['sessionDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reply: json['reply'] as String?,
      hidden: json['hidden'] as bool? ?? false,
      hiddenReason: json['hiddenReason'] as String?,
    );
  }
}

/// A trainer's average (null without reviews) and their latest reviews.
class TrainerReviews {
  final double? averageRating;
  final int reviewCount;
  final List<Review> reviews;

  const TrainerReviews({required this.averageRating, required this.reviewCount, required this.reviews});

  factory TrainerReviews.fromJson(Map<String, dynamic> json) {
    return TrainerReviews(
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      reviews: ((json['reviews'] as List?) ?? const [])
          .map((item) => Review.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
