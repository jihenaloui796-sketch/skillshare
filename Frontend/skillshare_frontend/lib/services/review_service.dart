import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  final ApiClient _api;

  ReviewService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Review>> getByUser(int userId) async {
    final json = await _api.get('/reviews/$userId');
    final raw = (json as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => Review.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Review>> listMine() async {
    final json = await _api.get('/reviews/mine');
    final raw = (json as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => Review.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<Review> create(
      {required int reviewedUserId,
      required int requestId,
      required int rating,
      String? comment}) async {
    final json = await _api.post('/reviews', body: {
      'reviewedUserId': reviewedUserId,
      'requestId': requestId,
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<Review> update(
      {required int id, required int rating, String? comment}) async {
    final json = await _api.put('/reviews/$id', body: {
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<void> delete({required int id}) async {
    await _api.delete('/reviews/$id');
  }
}
