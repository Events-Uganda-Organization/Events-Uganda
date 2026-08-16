class ReviewModel {
  final String id;
  final String userName;
  final String userImageUrl;
  final String reviewText;
  final String date;
  final int rating;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.reviewText,
    required this.date,
    required this.rating,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      userName: json['userName'] as String? ?? 'User',
      userImageUrl: json['userImageUrl'] as String? ?? '',
      reviewText: json['reviewText'] as String? ?? '',
      date: json['date'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
    );
  }
}
